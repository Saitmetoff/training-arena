/// Composition root for request notifications.
///
/// Builds the transport, the arena notification client, the authoritative
/// request source and the service. Push is only enabled when the build has
/// arena credentials and `ARENA_FEATURE_PUSH_NOTIFICATIONS=true`; otherwise
/// the runtime stays inert and the in-app inbox remains the only channel.
library;

import '../battle/ports/battle_backend.dart';
import '../config/arena_config.dart';
import 'notification_api.dart';
import 'notification_models.dart';
import 'notification_permission_store.dart';
import 'notification_request_source.dart';
import 'notification_service.dart';
import 'platform_push_transport.dart';
import 'push_transport.dart';

/// Owns the [NotificationService] for the app.
class NotificationRuntime {
  NotificationRuntime._({required this.service, required this.enabled});

  /// Production defaults from [ArenaConfig].
  factory NotificationRuntime.fromConfig(
    ArenaConfig config, {
    required BattleBackend backend,
    required NotificationAccessTokenProvider accessTokenProvider,
    PushTransport? transport,
    NotificationApi? api,
    NotificationRequestSource? requests,
    NotificationPermissionStore? permissionStore,
    Future<void> Function(PushPayload payload)? onForegroundMessage,
  }) {
    final enabled =
        config.pushNotificationsEnabled && config.hasSupabaseCredentials;
    final resolvedTransport = transport ??
        (enabled ? PlatformPushTransport() : const UnavailablePushTransport());
    final resolvedApi = api ??
        HttpNotificationApi(
          config: config,
          accessTokenProvider: accessTokenProvider,
        );
    final resolvedRequests =
        requests ?? BattleBackendNotificationSource(backend);
    final service = NotificationService(
      transport: resolvedTransport,
      api: resolvedApi,
      requests: resolvedRequests,
      permissionStore:
          permissionStore ?? SharedPreferencesNotificationPermissionStore(),
      onForegroundMessage: onForegroundMessage,
    );
    return NotificationRuntime._(service: service, enabled: enabled);
  }

  final NotificationService service;

  /// True when push permission, registration and taps are wired.
  final bool enabled;

  Future<void> initialize() => service.start();

  void dispose() {
    service.dispose();
  }
}
