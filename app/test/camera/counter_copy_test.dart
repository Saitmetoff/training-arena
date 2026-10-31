import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  test('every CounterRejection has nonempty plain-language copy', () {
    for (final reason in CounterRejection.values) {
      final copy = counterRejectionInstruction(reason);
      expect(copy.trim(),isNotEmpty,reason:reason.name);
      expect(copy,contains(' '),reason:reason.name);
    }
    expect(counterRejectionInstruction(CounterRejection.lockoutMissed),'Straighten fully at the top.');
    expect(counterRejectionInstruction(CounterRejection.notDeepEnough),'Go lower.');
  });
  test('every TrackingPauseReason has nonempty copy for both exercises', () {
    for (final exercise in ArenaExercise.values) {
      for (final reason in TrackingPauseReason.values) {
        expect(trackingInstruction(exercise:exercise,
          tracking:CameraTrackingState.tracking,reason:reason,practiceComplete:false).trim(),
          isNotEmpty,reason:'${exercise.name} ${reason.name}');
      }
    }
  });
}
