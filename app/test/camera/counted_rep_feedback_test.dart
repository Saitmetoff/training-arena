import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SYNTHETIC accepted practice rep cues once; duplicate and shallow frames do not cue', () async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform,(call) async {
      calls.add(call); return null;
    });
    addTearDown(()=>messenger.setMockMethodCallHandler(SystemChannels.platform,null));
    final source = SyntheticPoseSource.pushups();
    source.holdTop(800); source.partialRep(minimum:122); source.holdTop(500); source.rep();
    final bridge = FixtureCameraBridge(exercise:ArenaExercise.pushUps,
      script:FixtureScript(label:'SYNTHETIC feedback',frames:[...source.frames,source.frames.last]));
    final session = CameraSession.debugFixture(exercise:ArenaExercise.pushUps,bridge:bridge,autoPlay:false);
    addTearDown(session.dispose);
    await session.startPractice();
    for (var i=0;i<source.frames.length+1;i++) {
      bridge.emitNext(); await Future<void>.delayed(Duration.zero);
    }
    // The appended frame is a true duplicate timestamp after the practice count.
    expect(session.reps,1);
    expect(calls.where((c)=>c.method=='SystemSound.play').map((c)=>c.arguments),
      ['SystemSoundType.click']);
    expect(calls.where((c)=>c.method=='HapticFeedback.vibrate').map((c)=>c.arguments),
      ['HapticFeedbackType.lightImpact']);
  });
}
