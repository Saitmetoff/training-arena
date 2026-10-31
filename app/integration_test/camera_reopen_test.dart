/// On-device regression: the camera pipeline must reopen after dispose.
///
/// Owner report (2026-09-23, Redmi 10): the first camera start showed the
/// preview, the next ones showed nothing. Root cause: the native plugin kept
/// a disposed controller, and `start()` returned a texture id without binding
/// the camera — so Dart rendered a black preview and no landmark ever
/// arrived.
///
/// This drives the real [PlatformCameraBridge] on a device/emulator and fails
/// if the second start never reports ready or never produces a pose event.
/// Emulator coverage is reported separately from physical-hardware results.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:training_arena/camera/bridge/camera_bridge.dart';
import 'package:training_arena/camera/bridge/platform_camera_bridge.dart';
import 'package:training_arena/camera/camera_types.dart';
import 'package:training_arena/domain/arena_types.dart';

/// Records the two event streams a healthy pipeline must produce.
class _Probe {
  final List<String> cues = <String>[];
  final List<String> poses = <String>[];
  StreamSubscription<CameraCueEvent>? cueSub;
  StreamSubscription<PoseBridgeEvent>? poseSub;

  Future<void> attach(PlatformCameraBridge bridge) async {
    cueSub = bridge.cueEvents.listen((event) => cues.add(event.code));
    poseSub = bridge.poseEvents.listen(
      (event) => poses.add(event.runtimeType.toString()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> detach() async {
    await cueSub?.cancel();
    await poseSub?.cancel();
    cueSub = null;
    poseSub = null;
  }
}

Future<bool> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return condition();
}

/// Starts the pipeline and requires a bind cue plus at least one analyzer
/// event; a texture id alone is not success.
Future<void> _expectStartWorks(
  PlatformCameraBridge bridge,
  _Probe probe, {
  required String label,
}) async {
  final texture = await bridge.startPreview(ArenaExercise.pushUps);
  expect(texture, isNotNull, reason: '$label: startPreview returned nothing');

  final ready = await _waitFor(() => probe.cues.contains('cameraReady'));
  expect(
    ready,
    isTrue,
    reason: '$label: no cameraReady cue — the camera never bound '
        '(cues: ${probe.cues})',
  );

  final events = await _waitFor(() => probe.poses.isNotEmpty);
  expect(
    events,
    isTrue,
    reason: '$label: no pose or tracking events — the analyzer never ran',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the camera pipeline reopens after dispose', (tester) async {
    final first = PlatformCameraBridge();
    // Fail fast instead of raising the system dialog: an unattended run must
    // not hang waiting for a tap. Grant first with:
    //   adb shell pm grant app.trainingarena.mobile android.permission.CAMERA
    final permission = await first.checkPermission();
    if (permission != CameraPermissionStatus.granted) {
      fail(
        'camera permission is $permission; grant it before running\n'
        '  adb shell pm grant app.trainingarena.mobile '
        'android.permission.CAMERA',
      );
    }

    final firstProbe = _Probe();
    await firstProbe.attach(first);
    await _expectStartWorks(first, firstProbe, label: 'first start');
    await firstProbe.detach();
    await first.dispose();

    // Before the fix the native side reused the disposed controller: this
    // second start returned a texture id but never bound, so no cue arrived.
    final second = PlatformCameraBridge();
    final secondProbe = _Probe();
    await secondProbe.attach(second);
    await _expectStartWorks(second, secondProbe, label: 'second start');
    await secondProbe.detach();
    await second.dispose();

    // A third cycle guards against a fix that only works once.
    final third = PlatformCameraBridge();
    final thirdProbe = _Probe();
    await thirdProbe.attach(third);
    await _expectStartWorks(third, thirdProbe, label: 'third start');
    await thirdProbe.detach();
    await third.dispose();
  });
}
