/// Training Arena camera and rep-counting layer (task `03`).
///
/// Public surface for the battle feature:
///
/// * [CameraSession] — lifecycle, permission, practice/round flow and rep
///   events. Create it with [CameraSession.platform] in production and
///   [CameraSession.debugFixture] for the labeled offline demo.
/// * [CameraPreview] — local texture preview with instruction and demo label.
/// * [PoseSkeletonOverlay] — draws the counter's landmarks over the preview.
/// * [CameraSessionSnapshot], [RepEvent], [CameraTrackingState],
///   [TrackingPauseReason] — stable value types.
///
/// Privacy: frames are processed in memory by the on-device detector and are
/// never written to disk, encoded or uploaded. Rep events contain counters,
/// timestamps, confidence and a counter version only.
library;

export 'bridge/camera_bridge.dart';
export 'bridge/debug_fixture.dart' show FixtureCameraBridge, FixtureScript, buildFixtureScript;
export 'bridge/platform_camera_bridge.dart';
export 'camera_preview.dart';
export 'camera_session.dart';
export 'camera_types.dart';
export 'counter/exercise_profile.dart';
export 'counter/rep_counter.dart';
export 'counter/counter_copy.dart';
export 'phone_placement.dart';
export 'pose/pose_types.dart';
export 'pose_skeleton_overlay.dart';
