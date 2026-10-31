/// Deterministic solo badges.
///
/// Badges are derived from the stored history, never stored or awarded:
/// evaluating them twice cannot duplicate anything, and reinstalling keeps
/// them as long as the local history survives. No badge implies a
/// competitive claim or a health claim.
library;

import 'solo_result.dart';
import 'solo_streak.dart';

class SoloBadge {
  const SoloBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

/// Fixed badge set, in display order.
List<SoloBadge> soloBadges({
  required SoloStats stats,
  required SoloStreak streak,
}) =>
    <SoloBadge>[
      SoloBadge(
        id: 'first-set',
        title: 'First set',
        description: 'Finish your first solo set.',
        unlocked: stats.sessions >= 1,
      ),
      SoloBadge(
        id: 'goal-day',
        title: 'Goal day',
        description: 'Reach the daily goal on any day.',
        unlocked: streak.longest >= 1,
      ),
      SoloBadge(
        id: 'week-streak',
        title: 'Seven days',
        description: 'Reach the daily goal seven days in a row.',
        unlocked: streak.longest >= 7,
      ),
      SoloBadge(
        id: 'month-streak',
        title: 'Thirty days',
        description: 'Reach the daily goal thirty days in a row.',
        unlocked: streak.longest >= 30,
      ),
      SoloBadge(
        id: 'hundred-reps',
        title: 'Hundred reps',
        description: 'Complete 100 solo reps in total.',
        unlocked: stats.totalReps >= 100,
      ),
      SoloBadge(
        id: 'thousand-reps',
        title: 'Thousand reps',
        description: 'Complete 1,000 solo reps in total.',
        unlocked: stats.totalReps >= 1000,
      ),
    ];

/// Count of unlocked badges; used by the summary line.
int unlockedBadgeCount(List<SoloBadge> badges) =>
    badges.where((badge) => badge.unlocked).length;
