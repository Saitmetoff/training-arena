import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/camera/camera.dart';
import 'package:training_arena/camera/debug/synthetic_pose.dart';
import 'package:training_arena/domain/arena_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const deviceChannel = MethodChannel(CameraChannels.device);
  const poseChannel = EventChannel(CameraChannels.pose);
  const cueChannel = EventChannel(CameraChannels.cues);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> deviceCalls;
  late PlatformCameraBridge bridge;
  MockStreamHandlerEventSink? poseSink;
  MockStreamHandlerEventSink? cueSink;

  setUp(() {
    deviceCalls = [];
    messenger.setMockMethodCallHandler(deviceChannel, (call) async {
      deviceCalls.add(call);
      switch (call.method) {
        case 'checkPermission':
          return 'granted';
        case 'requestPermission':
          return 'granted';
        case 'openAppSettings':
          return true;
        case 'hasCamera':
          return true;
        case 'startPreview':
          return 77;
        case 'runtimeInfo':
          return <String, Object?>{
            'detector_sdk': 'ML Kit pose-detection 18.0.0-beta5',
            'detector_model': 'base',
            'camera_stack': 'CameraX 1.4.1',
            'min_sdk': 24,
            'api_level': 34,
            'device': 'test device',
          };
        default:
          return true;
      }
    });
    messenger.setMockStreamHandler(
      poseChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) => poseSink = events,
      ),
    );
    messenger.setMockStreamHandler(
      cueChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) => cueSink = events,
      ),
    );
    bridge = PlatformCameraBridge();
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(deviceChannel, null);
    messenger.setMockStreamHandler(poseChannel, null);
    messenger.setMockStreamHandler(cueChannel, null);
    await bridge.dispose();
  });

  test('permission states map from native wire values', () async {
    expect(await bridge.checkPermission(), CameraPermissionStatus.granted);

    messenger.setMockMethodCallHandler(deviceChannel, (call) async {
      deviceCalls.add(call);
      return 'permanently_denied';
    });
    expect(
      await bridge.requestPermission(),
      CameraPermissionStatus.permanentlyDenied,
    );

    messenger.setMockMethodCallHandler(deviceChannel, (call) async {
      deviceCalls.add(call);
      return 'unexpected-value';
    });
    expect(await bridge.checkPermission(), CameraPermissionStatus.unknown);
  });

  test(
    'preview geometry carries the crop and analysis mapping from native',
    () {
      final event = parsePoseBridgeEvent(<Object?, Object?>{
        'type': 'preview',
        'timestamp_us': 5,
        'width': 480,
        'height': 640,
        'crop': [60, 0, 420, 640],
        'texture_quarter_turns': 1,
        'mirrored': false,
        'analysis_to_preview': [1.5, 0, -0.25, 0, 1, 0],
      });
      expect(event, isNotNull);
      // The centre and left crop edge must remain aligned even when preview
      // and analysis have different dimensions.
      final geometry = (event as PosePreviewEvent).geometry;
      expect(geometry.project(0.5, 0.25), (0.5, 0.25));
      expect(geometry.project(1 / 6, 0.25), (0.0, 0.25));
      expect(geometry.mirrored, isFalse);
      expect(geometry.textureQuarterTurns, 1);
    },
  );

  test('native permission errors become typed bridge exceptions', () async {
    messenger.setMockMethodCallHandler(deviceChannel, (call) async {
      deviceCalls.add(call);
      throw PlatformException(code: 'camera_permission', message: 'blocked');
    });

    await expectLater(
      bridge.requestPermission(),
      throwsA(
        isA<CameraBridgeException>().having(
          (error) => error.code,
          'code',
          'camera_permission',
        ),
      ),
    );
  });

  test('preview rejects singular transforms and invalid crop bounds', () {
    final raw = <Object?, Object?>{
      'type': 'preview',
      'width': 480,
      'height': 640,
      'crop': [0, 0, 480, 640],
      'mirrored': true,
      'texture_quarter_turns': 0,
      'analysis_to_preview': [0, 0, 0, 0, 0, 0],
    };
    expect(parsePoseBridgeEvent(raw), isNull);
    raw['analysis_to_preview'] = [1, 0, 0, 0, 1, 0];
    raw['crop'] = [0, 0, 481, 640];
    expect(parsePoseBridgeEvent(raw), isNull);
  });

  test(
    'startPreview sends the exercise wire value and returns the texture',
    () async {
      final textureId = await bridge.startPreview(ArenaExercise.squats);

      expect(textureId, 77);
      final call = deviceCalls.singleWhere(
        (call) => call.method == 'startPreview',
      );
      expect(call.arguments, {'exercise': 'squats', 'lens_facing': 'front'});
    },
  );

  test('pause, resume, torch and stop reach the device channel', () async {
    await bridge.pause();
    await bridge.resume();
    await bridge.setTorch(true);
    await bridge.stop();

    expect(
      deviceCalls.map((call) => call.method),
      containsAll(<String>['pause', 'resume', 'setTorch', 'stop']),
    );
    final torch = deviceCalls.singleWhere((call) => call.method == 'setTorch');
    expect(torch.arguments, {'enabled': true});
  });

  test('runtime info exposes the documented detector versions', () async {
    final info = await bridge.runtimeInfo();

    expect(info.detectorSdk, 'ML Kit pose-detection 18.0.0-beta5');
    expect(info.detectorModel, 'base');
    expect(info.cameraStack, 'CameraX 1.4.1');
    expect(info.minSdk, 24);
    expect(info.apiLevel, 34);
    expect(info.deviceName, 'test device');
  });

  test('dispose releases once and blocks later calls', () async {
    await bridge.dispose();
    await bridge.dispose();

    expect(
      deviceCalls.where((call) => call.method == 'disposeSession'),
      hasLength(1),
    );
    await expectLater(bridge.pause(), throwsA(isA<CameraBridgeException>()));
  });

  test('pose frames normalise pixel landmarks against the upright frame',
      () async {
    final events = <PoseBridgeEvent>[];
    bridge.poseEvents.listen(events.add);
    await Future<void>.delayed(Duration.zero);

    poseSink!.success(<String, Object?>{
      'type': 'pose',
      'timestamp_us': 123456,
      'luminance': 0.42,
      'frame_width': 480,
      'frame_height': 640,
      'landmarks': <Object?>[
        {'t': 11, 'x': 240, 'y': 160, 'z': -48, 'l': 0.93},
        {'t': 99, 'x': 48, 'y': 64, 'z': 0.0, 'l': 0.5},
      ],
    });
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    final frameEvent = events.single as PoseFrameEvent;
    expect(frameEvent.frame.timestampMicros, 123456);
    expect(frameEvent.frame.luminance, closeTo(0.42, 1e-9));
    final shoulder =
        frameEvent.frame.point(PoseLandmarkType.leftShoulder)!;
    expect(shoulder.x, closeTo(0.5, 1e-9));
    expect(shoulder.y, closeTo(0.25, 1e-9));
    expect(shoulder.z, closeTo(-0.1, 1e-9));
    expect(shoulder.likelihood, 0.93);
  });

  test('a pose event without the upright frame size is dropped', () async {
    final events = <PoseBridgeEvent>[];
    bridge.poseEvents.listen(events.add);
    await Future<void>.delayed(Duration.zero);

    poseSink!.success(<String, Object?>{
      'type': 'pose',
      'timestamp_us': 1,
      'luminance': 0.5,
      'landmarks': <Object?>[
        {'t': 11, 'x': 240, 'y': 160, 'l': 0.9},
      ],
    });
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
    expect(
      parsePoseBridgeEvent(<Object?, Object?>{
        'type': 'pose',
        'timestamp_us': 1,
        'frame_width': 0,
        'frame_height': 640,
        'landmarks': <Object?>[
          {'t': 11, 'x': 240, 'y': 160, 'l': 0.9},
        ],
      }),
      isNull,
    );
  });

  test('a pixel-valued clean rep counts one after bridge normalisation', () {
    final source = SyntheticPoseSource.pushups(seed: 21, intervalMicros: 66000);
    final frames = <PoseFrame>[
      ...source.holdTop(800),
      ...source.rep(),
    ];
    const frameWidth = 480.0; // upright frame of the 640x480 analysis stream
    const frameHeight = 640.0;
    final counter = RepCounter(
      ExerciseCounterProfile.forExercise(ArenaExercise.pushUps),
    );

    for (final frame in frames) {
      final event = parsePoseBridgeEvent(<Object?, Object?>{
        'type': 'pose',
        'timestamp_us': frame.timestampMicros,
        'luminance': frame.luminance,
        'frame_width': frameWidth,
        'frame_height': frameHeight,
        'landmarks': <Object?>[
          for (final type in PoseLandmarkType.values)
            if (frame.point(type) != null)
              <String, Object?>{
                't': type.index,
                'x': frame.point(type)!.x * frameWidth,
                'y': frame.point(type)!.y * frameHeight,
                'z': frame.point(type)!.z * frameWidth,
                'l': frame.point(type)!.likelihood,
              },
        ],
      });
      final parsed = (event! as PoseFrameEvent).frame;
      for (final point in parsed.landmarks.whereType<PosePoint>()) {
        expect(point.x, inInclusiveRange(0.0, 1.0));
        expect(point.y, inInclusiveRange(0.0, 1.0));
      }
      counter.addFrame(parsed);
    }

    expect(counter.countedReps, 1);
  });

  test('tracking, error and malformed pose payloads are handled', () async {
    final events = <PoseBridgeEvent>[];
    bridge.poseEvents.listen(events.add);
    await Future<void>.delayed(Duration.zero);

    poseSink!.success(<String, Object?>{
      'type': 'tracking',
      'state': 'lost',
      'reason': 'noPerson',
      'luminance': 0.5,
      'timestamp_us': 1,
    });
    poseSink!.success(<String, Object?>{
      'type': 'error',
      'code': 'camera_unavailable',
      'message': 'no camera',
      'timestamp_us': 2,
    });
    poseSink!.success(<String, Object?>{'type': 'future-event'});
    poseSink!.success('not a map');
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2));
    final tracking = events.first as PoseTrackingEvent;
    expect(tracking.state, CameraTrackingState.searching);
    expect(tracking.reason, TrackingPauseReason.noPerson);
    final error = events.last as PoseErrorEvent;
    expect(error.code, 'camera_unavailable');
  });

  test('cue payloads parse and unknown cues are ignored', () async {
    final cues = <CameraCueEvent>[];
    bridge.cueEvents.listen(cues.add);
    await Future<void>.delayed(Duration.zero);

    cueSink!.success(<String, Object?>{
      'code': 'lowLight',
      'message': 'too dark',
      'timestamp_us': 5,
    });
    cueSink!.success(<String, Object?>{'message': 'no code'});
    await Future<void>.delayed(Duration.zero);

    expect(cues, hasLength(1));
    expect(cues.single.code, 'lowLight');
    expect(cues.single.message, 'too dark');
  });

  test('protocol parser ignores unknown fields and out-of-range landmarks', () {
    final event = parsePoseBridgeEvent(<Object?, Object?>{
      'type': 'pose',
      'timestamp_us': 10,
      'luminance': 0.3,
      'frame_image': 'never-a-frame',
      'frame_width': 640,
      'frame_height': 480,
      'landmarks': <Object?>[
        {'t': 0, 'x': 64, 'y': 48, 'l': 0.9},
        {'t': -5, 'x': 64, 'y': 48},
        {'t': 33, 'x': 64, 'y': 48},
      ],
    });

    expect(event, isA<PoseFrameEvent>());
    final frame = (event! as PoseFrameEvent).frame;
    expect(frame.point(PoseLandmarkType.nose)!.x, closeTo(0.1, 1e-9));
    expect(frame.landmarks.where((point) => point != null), hasLength(1));
    expect(parsePoseBridgeEvent(null), isNull);
    expect(parseCameraCueEvent(<Object?, Object?>{}), isNull);
  });
}
