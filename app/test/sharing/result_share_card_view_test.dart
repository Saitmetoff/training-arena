import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/sharing/fixtures/result_share_fixtures.dart';
import 'package:training_arena/sharing/result_share_card_view.dart';
import 'package:training_arena/sharing/result_share_models.dart';

import '../linking/fakes.dart';
import 'test_receipts.dart';

/// 1×1 image provider so the avatar path never touches the network.
class SolidImageProvider extends ImageProvider<SolidImageProvider> {
  const SolidImageProvider();

  @override
  Future<SolidImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SolidImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    SolidImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0xFFD6FF3F),
    );
    final picture = recorder.endRecording();
    final image = picture.toImage(1, 1);
    return OneFrameImageStreamCompleter(
      image.then((value) => ImageInfo(image: value)),
    );
  }
}

void main() {
  const requiredKeys = <String>[
    'result-share-card',
    'share-card-kicker',
    'share-card-headline',
    'share-card-score-viewer',
    'share-card-score-opponent',
    'share-card-meta',
    'share-card-cta',
    'share-card-link',
    'share-card-qr',
    'share-card-url',
    'share-card-code',
    'share-card-footnote',
  ];

  Future<void> pumpCard(
    WidgetTester tester,
    ResultShareCard card,
    ResultShareFormat format, {
    Map<String, ImageProvider> avatars = const <String, ImageProvider>{},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Center(
            child: ResultShareCardView(
              card: card,
              format: format,
              avatarImages: avatars,
            ),
          ),
        ),
      ),
    );
  }

  void expectWithinCard(
    WidgetTester tester,
    Rect content,
    String key,
    ResultShareFormat format,
  ) {
    final cardTopLeft =
        tester.getTopLeft(find.byKey(const ValueKey('result-share-card')));
    final rect = tester.getRect(find.byKey(ValueKey(key)));
    final local = rect.shift(-cardTopLeft);
    final reason = '$key must stay inside the ${format.label} safe area';
    expect(local.left, greaterThanOrEqualTo(content.left - 0.01),
        reason: reason);
    expect(local.top, greaterThanOrEqualTo(content.top - 0.01), reason: reason);
    expect(local.right, lessThanOrEqualTo(content.right + 0.01), reason: reason);
    expect(local.bottom, lessThanOrEqualTo(content.bottom + 0.01),
        reason: reason);
  }

  for (final format in ResultShareFormat.values) {
    testWidgets('${format.label} card renders every mandatory element',
        (tester) async {
      await pumpCard(tester, ResultShareFixtures.winCasual, format);
      for (final key in requiredKeys) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('${format.label} keeps mandatory content inside the safe area',
        (tester) async {
      final layout = ResultShareCardLayout.forFormat(format);
      final expectedContent = switch (format) {
        ResultShareFormat.stories =>
          const Rect.fromLTRB(108, 312, 972, 1560),
        ResultShareFormat.feed =>
          const Rect.fromLTRB(86, 136, 994, 1188),
      };
      expect(layout.contentRectPixels, expectedContent);
      expect(
        layout.contentRectPixels.width / format.pixelWidth,
        greaterThan(0.75),
      );
      expect(
        layout.contentRectPixels.height / format.pixelHeight,
        greaterThan(0.6),
      );
      await pumpCard(tester, ResultShareFixtures.winRanked, format);
      for (final key in <String>[
        'share-card-kicker',
        'share-card-headline',
        'share-card-score-viewer',
        'share-card-score-opponent',
        'share-card-meta',
        'share-card-cta',
        'share-card-link',
        'share-card-footnote',
      ]) {
        expectWithinCard(tester, layout.contentRect, key, format);
      }
    });

    testWidgets('${format.label} renders every fixture without overflow',
        (tester) async {
      for (final card in ResultShareFixtures.all) {
        await pumpCard(tester, card, format);
        expect(
          tester.takeException(),
          isNull,
          reason: '${card.headline} (${card.outcome.wire})',
        );
      }
    });
  }

  testWidgets('sharer is left lime and opponent is right violet',
      (tester) async {
    await pumpCard(tester, ResultShareFixtures.winCasual,
        ResultShareFormat.feed);
    final viewerRect = tester.getRect(
      find.byKey(const ValueKey('share-card-score-viewer')),
    );
    final opponentRect = tester.getRect(
      find.byKey(const ValueKey('share-card-score-opponent')),
    );
    expect(viewerRect.left, lessThan(opponentRect.left));
    expect(find.text('@azizbek'), findsOneWidget);
    expect(find.text('@zuhra'), findsOneWidget);
    expect(find.text('you · player'), findsOneWidget);
    expect(find.text('opponent'), findsOneWidget);
  });

  testWidgets('headline, exercise, duration and CTA are readable facts',
      (tester) async {
    await pumpCard(tester, ResultShareFixtures.lossRanked,
        ResultShareFormat.stories);
    expect(find.text('@zuhra BEAT ME BY 5'), findsOneWidget);
    expect(find.text('Push-ups · 60 seconds'), findsOneWidget);
    expect(find.text('CHALLENGE @zuhra'), findsOneWidget);
    expect(
      find.text(
        'https://example.invalid/c/${ResultShareFixtures.token}',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Code ${ResultShareFixtures.readableCode}'),
      findsOneWidget,
    );
  });

  testWidgets('ranked ratings render only when the server confirmed them',
      (tester) async {
    await pumpCard(tester, ResultShareFixtures.winRanked,
        ResultShareFormat.feed);
    expect(find.text('Arena rating 1058 (+16)'), findsOneWidget);
    expect(find.text('Arena rating 1044 (−16)'), findsOneWidget);
    expect(find.text('Ranked · rating confirmed'), findsOneWidget);

    await pumpCard(tester, ResultShareFixtures.winCasual,
        ResultShareFormat.feed);
    expect(find.textContaining('Arena rating'), findsNothing);
    expect(find.text('Casual · rating unchanged'), findsOneWidget);
  });

  testWidgets('no-result hides scores and claims no rating change',
      (tester) async {
    await pumpCard(tester, ResultShareFixtures.noResult,
        ResultShareFormat.stories);
    expect(find.text('NO RESULT'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('no confirmed score'), findsNWidgets(2));
    expect(find.text('Ranked · no rating change'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(find.text('9'), findsNothing);
  });

  testWidgets('missing avatars fall back to monograms', (tester) async {
    await pumpCard(tester, ResultShareFixtures.winCasual,
        ResultShareFormat.feed);
    expect(find.text('AZ'), findsOneWidget);
    expect(find.text('ZU'), findsOneWidget);
  });

  testWidgets('provided avatar images render without network access',
      (tester) async {
    await pumpCard(
      tester,
      ResultShareFixtures.winCasual,
      ResultShareFormat.feed,
      avatars: const <String, ImageProvider>{
        'fixture-viewer': SolidImageProvider(),
        'fixture-opponent': SolidImageProvider(),
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(Image), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a very long username never overflows the headline',
      (tester) async {
    const longName = 'averyveryverylongusernamefortesting';
    final card = confirmResultShareCard(
      receipt: testReceipt(
        viewer: receiptPlayer(testViewerProfile, 10),
        opponent: receiptPlayer(
          const ArenaProfile(id: 'u-opp', username: longName),
          40,
        ),
        winnerId: 'u-opp',
      ),
      viewerId: 'u-you',
      account: const ChallengeAccountSnapshot(
        profile: testViewerProfile,
        link: ChallengeLinkInfo(
          token: 'ab12cd34ef56',
          code: 'ab12cd34ef56',
        ),
      ),
      config: testConfig(),
    );
    await pumpCard(tester, card, ResultShareFormat.feed);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('BEAT ME BY 30'), findsOneWidget);
  });

  testWidgets('a fixture card is labelled as simulated', (tester) async {
    await pumpCard(tester, ResultShareFixtures.winCasual,
        ResultShareFormat.feed);
    expect(find.textContaining('SIMULATED FIXTURE'), findsOneWidget);
    expect(find.textContaining('cannot be shared'), findsOneWidget);
  });
}
