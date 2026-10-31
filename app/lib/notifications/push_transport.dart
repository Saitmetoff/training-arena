/// Platform push transport boundary.
///
/// Task `08` owns this seam. The production adapter is
/// [PlatformPushTransport] (method/event channels implemented by the native
/// Android host, documented in `docs/notifications/ANDROID_PUSH_SETUP.md`);
/// tests and unconfigured builds use [UnavailablePushTransport] or a fake.
///
/// Platform delivery is best effort by contract: when permission is denied or
/// a token cannot be obtained, the in-app inbox (`inbox` action) remains the
/// authoritative source of requests. No method in this layer may log a device
/// token.
library;

import 'notification_models.dart';

/// Native push capabilities consumed by [NotificationService].
abstract interface class PushTransport {
  /// Current permission answer without prompting.
  Future<PushPermissionStatus> permissionStatus();

  /// Asks the OS once; returns the resulting answer.
  Future<PushPermissionStatus> requestPermission();

  /// The current FCM/APNs device token, or null when unavailable.
  ///
  /// Callers must never log or persist this value outside the registration
  /// call and must never place it in analytics properties.
  Future<String?> deviceToken();

  /// Fresh tokens when the platform rotates them.
  Stream<String> get tokenRefreshes;

  /// Messages received while the app is foregrounded. Delivery here never
  /// creates a request or a match; the inbox stays authoritative.
  Stream<PushPayload> get foregroundMessages;

  /// Taps on notifications while the app is running (background or
  /// foreground).
  Stream<PushTap> get notificationTaps;

  /// The tap that cold-started the app, if any. Consumed once per launch.
  Future<PushTap?> initialTap();

  /// Releases platform listeners. Idempotent.
  Future<void> dispose();
}

/// Honest placeholder for builds without push configuration.
class UnavailablePushTransport implements PushTransport {
  const UnavailablePushTransport();

  @override
  Future<PushPermissionStatus> permissionStatus() async =>
      PushPermissionStatus.notDetermined;

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.notDetermined;

  @override
  Future<String?> deviceToken() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream<String>.empty();

  @override
  Stream<PushPayload> get foregroundMessages =>
      const Stream<PushPayload>.empty();

  @override
  Stream<PushTap> get notificationTaps => const Stream<PushTap>.empty();

  @override
  Future<PushTap?> initialTap() async => null;

  @override
  Future<void> dispose() async {}
}
