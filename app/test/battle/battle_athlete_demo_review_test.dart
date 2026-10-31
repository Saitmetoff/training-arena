/// Media review policy regression: the preparation demonstration must never
/// render an asset whose manifest `review_status` is not `approved`
/// (`app/assets/media/athlete/manifest.json` `missing_media_policy`, mirrored
/// by `qa/media/tools/validate_media_package.py --gate release`).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_arena/battle/ui/battle_athlete_demo.dart';
import 'package:training_arena/domain/arena_types.dart';

/// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

Map<String, Object?> _manifest({
  required String loopStatus,
  required String posterPngStatus,
}) {
  return {
    'exercises': {
      'pushups': {
        'assets': {
          'loop_webp': {
            'asset': 'assets/media/athlete/loops/pushup_loop.webp',
            'review_status': loopStatus,
          },
          'poster_start_png': {
            'asset': 'assets/media/athlete/posters/pushup_start.png',
            'review_status': posterPngStatus,
          },
        },
      },
    },
  };
}

Future<ByteData> Function(String) _loader(Map<String, Object?> manifest) {
  final encoded = Uint8List.fromList(utf8.encode(json.encode(manifest)));
  return (String key) async {
    if (key == 'assets/media/athlete/manifest.json') {
      return ByteData.sublistView(encoded);
    }
    if (key.endsWith('.webp') || key.endsWith('.png')) {
      return ByteData.sublistView(_png);
    }
    throw FlutterError('unexpected asset request: $key');
  };
}

/// Image decoding is a real async native call, so the widget is pumped inside
/// [WidgetTester.runAsync] before settling.
Future<void> _pump(WidgetTester tester, Map<String, Object?> manifest) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleAthleteDemo(
            exercise: ArenaExercise.pushUps,
            assetLoader: _loader(manifest),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unreviewed assets render the placeholder', (tester) async {
    await _pump(
      tester,
      _manifest(
        loopStatus: 'pending_human_review',
        posterPngStatus: 'pending_human_review',
      ),
    );

    expect(find.text('Form guide pending review'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('approved assets render', (tester) async {
    await _pump(
      tester,
      _manifest(
        loopStatus: 'approved',
        posterPngStatus: 'pending_human_review',
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Form guide pending review'), findsNothing);
  });

  testWidgets('an approved fallback is used when the preferred asset is '
      'unreviewed', (tester) async {
    await _pump(
      tester,
      _manifest(
        loopStatus: 'pending_human_review',
        posterPngStatus: 'approved',
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Form guide pending review'), findsNothing);
  });
}
