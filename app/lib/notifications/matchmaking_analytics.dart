/// HTTP analytics sink for the ranked search.
///
/// Wraps the documented `analytics` action and swallows every failure, so a
/// queue seat, a match or a result can never depend on telemetry. Properties
/// never contain device tokens or other credentials.
library;

import '../battle/ports/battle_analytics.dart';
import 'notification_api.dart';

/// Sends matchmaking events through [NotificationApi.trackEvent].
class ApiBattleAnalyticsSink implements BattleAnalyticsSink {
  const ApiBattleAnalyticsSink(this._api);

  final NotificationApi _api;

  @override
  Future<void> track(String event, Map<String, Object?> properties) async {
    try {
      await _api.trackEvent(event, properties);
    } catch (_) {
      // Telemetry is best effort and never blocks the arena.
    }
  }
}
