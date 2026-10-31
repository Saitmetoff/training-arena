/// Preparation demonstration media.
///
/// Resolves task 02's athlete manifest fallback chain
/// (`app/assets/media/athlete/manifest.json`) and renders the first decodable
/// asset. The demonstration is instructional only: it never counts reps and
/// never verifies form. Missing media falls back to the documented
/// placeholder text rather than a blank frame, and an asset whose
/// `review_status` is not `approved` is never rendered (the manifest's
/// `missing_media_policy.release_builds` rule; the release gate in
/// `qa/media/tools/validate_media_package.py` enforces the same policy).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/arena_types.dart';
import '../../theme/arena_tokens.dart';
import 'battle_style.dart';

/// Decodable candidate in fallback order.
class _DemoCandidate {
  const _DemoCandidate(this.asset, {required this.animated});

  final String asset;
  final bool animated;
}

/// Instructional demonstration frame for [exercise].
class BattleAthleteDemo extends StatefulWidget {
  const BattleAthleteDemo({
    super.key,
    required this.exercise,
    this.assetLoader,
  });

  final ArenaExercise exercise;

  /// Test seam; defaults to the root asset bundle.
  final Future<ByteData> Function(String key)? assetLoader;

  @override
  State<BattleAthleteDemo> createState() => _BattleAthleteDemoState();
}

class _BattleAthleteDemoState extends State<BattleAthleteDemo> {
  Future<_DemoCandidate?>? _resolution;

  @override
  void initState() {
    super.initState();
    _resolution = _resolve();
  }

  @override
  void didUpdateWidget(BattleAthleteDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise != widget.exercise) {
      _resolution = _resolve();
    }
  }

  Future<ByteData> _load(String key) {
    final loader = widget.assetLoader;
    if (loader != null) {
      return loader(key);
    }
    return rootBundle.load(key);
  }

  Future<_DemoCandidate?> _resolve() async {
    try {
      final data = await _load('assets/media/athlete/manifest.json');
      final raw = utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final exercises = decoded['exercises'] as Map<String, dynamic>?;
      final entry = exercises?[widget.exercise.wire] as Map<String, dynamic>?;
      final assets = entry?['assets'] as Map<String, dynamic>?;
      if (assets == null) {
        return null;
      }
      // Flutter can decode WebP (including animation) and PNG without a
      // video plugin; MP4 assets are skipped by the app fallback order.
      const order = <String, bool>{
        'loop_webp': true,
        'poster_start': false,
        'poster_start_png': false,
      };
      for (final entry in order.entries) {
        final asset = assets[entry.key] as Map<String, dynamic>?;
        final path = asset?['asset'] as String?;
        if (path == null) {
          continue;
        }
        // Human-reviewed only: an unreviewed asset must fall through to the
        // placeholder instead of shipping unreviewed instruction.
        if (asset?['review_status'] != 'approved') {
          continue;
        }
        final candidate = _DemoCandidate(path, animated: entry.value);
        try {
          final bytes = await _load(path);
          await decodeImageFromList(
            bytes.buffer.asUint8List(
              bytes.offsetInBytes,
              bytes.lengthInBytes,
            ),
          );
          return candidate;
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DemoCandidate?>(
      future: _resolution,
      builder: (context, snapshot) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(ArenaBattleSpace.radiusControl),
          child: Container(
            key: const ValueKey('battle-athlete-demo'),
            color: ArenaColors.charcoal,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 220),
            child: snapshot.connectionState != ConnectionState.done
                ? const _DemoLoading()
                : snapshot.data == null
                    ? const _DemoPlaceholder()
                    : _DemoFrame(candidate: snapshot.data!),
          ),
        );
      },
    );
  }
}

class _DemoLoading extends StatelessWidget {
  const _DemoLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(ArenaBattleSpace.s5),
        child: Text(
          'Loading the demonstration…',
          style: TextStyle(color: ArenaColors.quiet),
        ),
      ),
    );
  }
}

class _DemoFrame extends StatelessWidget {
  const _DemoFrame({required this.candidate});

  final _DemoCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: const EdgeInsets.all(ArenaBattleSpace.s2),
          child: Image.asset(
            candidate.asset,
            fit: BoxFit.contain,
            semanticLabel: 'Instructional movement demonstration',
            errorBuilder: (context, error, stackTrace) =>
                const _DemoPlaceholder(),
          ),
        ),
        Positioned(
          top: ArenaBattleSpace.s2,
          left: ArenaBattleSpace.s2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ArenaColors.raised,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Instructional',
              style: ArenaBattleText.micro.copyWith(
                color: ArenaColors.secondary,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoPlaceholder extends StatelessWidget {
  const _DemoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(ArenaBattleSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.accessibility_new,
              color: ArenaColors.quiet,
              size: 40,
            ),
            SizedBox(height: ArenaBattleSpace.s3),
            Text(
              'Form guide pending review',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArenaColors.softWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ArenaBattleSpace.s1),
            Text(
              'Demonstration media ships only after a human form review. It '
              'never counts reps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ArenaColors.quiet, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
