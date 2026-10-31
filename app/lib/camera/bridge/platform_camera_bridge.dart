/// Production [CameraBridge] backed by the Android channels documented in
/// `camera_bridge.dart`.
library;

import 'package:flutter/services.dart';

import '../../domain/arena_types.dart';
import '../camera_types.dart';
import 'camera_bridge.dart';

class PlatformCameraBridge implements CameraBridge {
  PlatformCameraBridge({
    MethodChannel? deviceChannel,
    EventChannel? poseChannel,
    EventChannel? cueChannel,
  })  : _device = deviceChannel ?? const MethodChannel(CameraChannels.device),
        _pose = poseChannel ?? const EventChannel(CameraChannels.pose),
        _cues = cueChannel ?? const EventChannel(CameraChannels.cues);

  final MethodChannel _device;
  final EventChannel _pose;
  final EventChannel _cues;

  Stream<PoseBridgeEvent>? _poseEvents;
  Stream<CameraCueEvent>? _cueEvents;
  bool _disposed = false;

  @override
  Stream<PoseBridgeEvent> get poseEvents => _poseEvents ??= _pose
      .receiveBroadcastStream()
      .map(parsePoseBridgeEvent)
      .where((event) => event != null)
      .cast<PoseBridgeEvent>();

  @override
  Stream<CameraCueEvent> get cueEvents => _cueEvents ??= _cues
      .receiveBroadcastStream()
      .map(parseCameraCueEvent)
      .where((event) => event != null)
      .cast<CameraCueEvent>();

  @override
  Future<CameraPermissionStatus> checkPermission() async {
    final wire = await _invoke<String>('checkPermission');
    return CameraPermissionStatus.fromWire(wire);
  }

  @override
  Future<CameraPermissionStatus> requestPermission() async {
    final wire = await _invoke<String>('requestPermission');
    return CameraPermissionStatus.fromWire(wire);
  }

  @override
  Future<bool> openAppSettings() async =>
      await _invoke<bool>('openAppSettings') ?? false;

  @override
  Future<bool> hasCamera() async => await _invoke<bool>('hasCamera') ?? false;

  @override
  Future<int> startPreview(ArenaExercise exercise) async {
    final textureId = await _invoke<int>('startPreview', {
      'exercise': exercise.wire,
      'lens_facing': 'front',
    });
    if (textureId == null) {
      throw const CameraBridgeException(
        CameraFailureCodes.cameraUnavailable,
        'startPreview returned no texture id',
      );
    }
    return textureId;
  }

  @override
  Future<void> setTorch(bool enabled) async {
    await _invoke<bool>('setTorch', {'enabled': enabled});
  }

  @override
  Future<void> pause() async {
    await _invoke<bool>('pause');
  }

  @override
  Future<void> resume() async {
    await _invoke<bool>('resume');
  }

  @override
  Future<void> stop() async {
    await _invoke<bool>('stop');
  }

  @override
  Future<CameraRuntimeInfo> runtimeInfo() async {
    final raw = await _invoke<Map<Object?, Object?>>('runtimeInfo') ?? const {};
    String stringOf(Object? key) {
      final value = raw[key];
      return value is String ? value : '';
    }

    int intOf(Object? key) {
      final value = raw[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return 0;
    }

    return CameraRuntimeInfo(
      detectorSdk: stringOf('detector_sdk'),
      detectorModel: stringOf('detector_model'),
      cameraStack: stringOf('camera_stack'),
      minSdk: intOf('min_sdk'),
      apiLevel: intOf('api_level'),
      deviceName: stringOf('device'),
      raw: raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    try {
      await _device.invokeMethod<bool>('disposeSession');
    } on PlatformException {
      // Best effort: the engine may already be detaching.
    } on MissingPluginException {
      // No native bridge (host tests or a partially detached engine).
    } finally {
      _disposed = true;
    }
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (_disposed) {
      throw CameraBridgeException(
        CameraFailureCodes.bridgeFailure,
        'bridge disposed before $method',
      );
    }
    try {
      return await _device.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw CameraBridgeException(
        error.code,
        error.message ?? 'native $method failed',
      );
    } on MissingPluginException {
      throw const CameraBridgeException(
        CameraFailureCodes.bridgeFailure,
        'native camera bridge is not registered',
      );
    }
  }
}
