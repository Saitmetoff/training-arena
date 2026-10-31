/// Challenge link analytics.
///
/// Events go through the documented `analytics` action and are best effort:
/// a failed analytics call must never break the challenge flow. Opening a
/// platform share sheet is explicitly **not** a referral and never creates a
/// recipient profile.
library;

import 'arena_challenge_api.dart';

/// Stable event names from
/// `docs/decisions/05-challenge-link-interface-decisions.md`.
abstract final class ChallengeAnalyticsEvent {
  /// A link or install referrer opened the challenge experience.
  static const String linkOpened = 'challenge_link_opened';

  /// The sign-in delegate returned a real session.
  static const String signInCompleted = 'challenge_sign_in_completed';

  /// The backend confirmed this device's request.
  static const String requestSent = 'challenge_request_sent';

  /// An accepted request surfaced as a live casual match.
  static const String requestAccepted = 'challenge_request_accepted';

  /// The platform share sheet opened. Never counted as a referral.
  static const String shareSheetOpened = 'challenge_share_sheet_opened';

  /// The Play install CTA was tapped.
  static const String installCtaTapped = 'challenge_install_cta_tapped';
}

/// One recorded event, kept for tests and QA.
class ChallengeAnalyticsRecord {
  const ChallengeAnalyticsRecord(this.event, this.properties);

  final String event;
  final Map<String, Object?> properties;

  @override
  String toString() => '$event($properties)';
}

/// Sink consumed by the controller and the share flow.
abstract class ChallengeAnalyticsSink {
  Future<void> track(String event, Map<String, Object?> properties);
}

/// Sends events to the arena API, swallowing every failure.
class ApiChallengeAnalyticsSink implements ChallengeAnalyticsSink {
  const ApiChallengeAnalyticsSink(this._api);

  final ArenaChallengeApi _api;

  @override
  Future<void> track(String event, Map<String, Object?> properties) async {
    try {
      await _api.trackEvent(event, properties);
    } catch (_) {
      // Analytics must never block a challenge.
    }
  }
}

/// Discards events (default when the backend is not configured).
class NoopChallengeAnalyticsSink implements ChallengeAnalyticsSink {
  const NoopChallengeAnalyticsSink();

  @override
  Future<void> track(String event, Map<String, Object?> properties) async {}
}

/// Records events in order for tests and preview tooling.
class MemoryChallengeAnalyticsSink implements ChallengeAnalyticsSink {
  final List<ChallengeAnalyticsRecord> records = <ChallengeAnalyticsRecord>[];

  List<String> get eventNames =>
      records.map((record) => record.event).toList(growable: false);

  bool contains(String event) => eventNames.contains(event);

  @override
  Future<void> track(String event, Map<String, Object?> properties) async {
    records.add(ChallengeAnalyticsRecord(event, Map.unmodifiable(properties)));
  }
}
