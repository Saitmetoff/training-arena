import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/domain/arena_types.dart';
import 'package:training_arena/linking/challenge_analytics.dart';
import 'package:training_arena/linking/challenge_models.dart';
import 'package:training_arena/linking/challenge_share.dart';
import 'package:training_arena/sharing/fixtures/result_share_fixtures.dart';
import 'package:training_arena/sharing/result_share_models.dart';
import 'package:training_arena/sharing/result_share_preview.dart';
import 'package:training_arena/sharing/result_share_service.dart';

import '../linking/fakes.dart';
import 'fakes.dart';
import 'test_receipts.dart';

void main() {
  Future<void> pumpPreview(
    WidgetTester tester, {
    required ResultShareService service,
    required FakeResultShareCapture capture,
    ResultReceipt? receipt,
    String viewerId = 'fixture-viewer',
    ChallengeAccountSnapshot? initialSnapshot,
  }) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ResultSharePreviewPage(
          receipt: receipt ?? ResultShareFixtures.winCasual.receipt,
          viewerId: viewerId,
          service: service,
          capture: capture,
          initialSnapshot: initialSnapshot,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ResultShareService buildService({
    FakeResultShareAccountSource? account,
    FakeResultShareLauncher? launcher,
    FakeResultShareClipboard? clipboard,
    MemoryChallengeAnalyticsSink? analytics,
  }) {
    return ResultShareService(
      account: account ?? FakeResultShareAccountSource(),
      config: testConfig(),
      launcher: launcher ?? FakeResultShareLauncher(),
      clipboard: clipboard ?? FakeResultShareClipboard(),
      analytics: analytics ?? MemoryChallengeAnalyticsSink(),
    );
  }

  testWidgets('preview renders the exact card and all three actions',
      (tester) async {
    final service = buildService();
    await pumpPreview(
      tester,
      service: service,
      capture: FakeResultShareCapture(),
    );
    expect(find.byKey(const ValueKey('result-share-card')), findsOneWidget);
    expect(find.text('I BEAT @zuhra BY 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('result-share-primary')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-share-copy')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-share-system')), findsOneWidget);
    expect(find.text('Stories 9:16'), findsOneWidget);
    expect(find.text('Feed 4:5'), findsOneWidget);
  });

  testWidgets('Share challenge captures the boundary then opens the sheet',
      (tester) async {
    final launcher = FakeResultShareLauncher();
    final analytics = MemoryChallengeAnalyticsSink();
    final capture = FakeResultShareCapture();
    final service = buildService(launcher: launcher, analytics: analytics);
    await pumpPreview(tester, service: service, capture: capture);

    await tester.tap(find.byKey(const ValueKey('result-share-primary')));
    await tester.pumpAndSettle();

    expect(capture.calls, 1);
    expect(capture.formats.single, ResultShareFormat.stories);
    expect(launcher.imageBytes.single, capture.bytes);
    expect(launcher.imageNames.single, contains('fault-challenge'));
    expect(
      launcher.imageTexts.single,
      contains('https://example.invalid/c/$fakeToken'),
    );
    expect(launcher.imageTexts.single.toLowerCase(), isNot(contains('replay')));
    expect(
      analytics.eventNames,
      contains(ResultShareAnalyticsEvent.previewOpened),
    );
    expect(
      analytics.eventNames,
      contains(ResultShareAnalyticsEvent.cardExported),
    );
    expect(
      analytics.eventNames,
      contains(ResultShareAnalyticsEvent.sheetOpened),
    );
  });

  testWidgets('format toggle exports the selected exact size', (tester) async {
    final capture = FakeResultShareCapture();
    await pumpPreview(
      tester,
      service: buildService(),
      capture: capture,
    );
    await tester.tap(find.text('Feed 4:5'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('result-share-primary')));
    await tester.pumpAndSettle();
    expect(capture.formats.single, ResultShareFormat.feed);
  });

  testWidgets('Copy challenge link copies the real URL and shows the code',
      (tester) async {
    final clipboard = FakeResultShareClipboard();
    await pumpPreview(
      tester,
      service: buildService(clipboard: clipboard),
      capture: FakeResultShareCapture(),
    );
    await tester.tap(find.byKey(const ValueKey('result-share-copy')));
    await tester.pumpAndSettle();
    expect(clipboard.copied.single, 'https://example.invalid/c/$fakeToken');
    expect(
      find.textContaining('Challenge link copied. Code AB12-CD34-EF56'),
      findsOneWidget,
    );
  });

  testWidgets('System share sends the caption without the image',
      (tester) async {
    final launcher = FakeResultShareLauncher();
    await pumpPreview(
      tester,
      service: buildService(launcher: launcher),
      capture: FakeResultShareCapture(),
    );
    await tester.tap(find.byKey(const ValueKey('result-share-system')));
    await tester.pumpAndSettle();
    expect(launcher.imageBytes, isEmpty);
    expect(launcher.sharedTexts.single, contains('New live challenge:'));
    expect(
      launcher.sharedTexts.single,
      contains('https://example.invalid/c/$fakeToken'),
    );
  });

  testWidgets('the painted CTA is not an interactive link', (tester) async {
    final launcher = FakeResultShareLauncher();
    await pumpPreview(
      tester,
      service: buildService(launcher: launcher),
      capture: FakeResultShareCapture(),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('share-card-cta')));
    await tester.tap(find.byKey(const ValueKey('share-card-cta')));
    await tester.pumpAndSettle();
    expect(launcher.imageBytes, isEmpty);
    expect(launcher.sharedTexts, isEmpty);
  });

  testWidgets('offline link failure shows factual copy and retry works',
      (tester) async {
    final account = FakeResultShareAccountSource()
      ..error = const ChallengeShareException(
        'network',
        'The arena is unreachable right now.',
      );
    await pumpPreview(
      tester,
      service: buildService(account: account),
      capture: FakeResultShareCapture(),
    );
    expect(find.text('Challenge link unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('result-share-primary')), findsNothing);

    account.error = null;
    await tester.tap(find.byKey(const ValueKey('result-share-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('result-share-card')), findsOneWidget);
    expect(account.calls, 2);
  });

  testWidgets('a prefetched confirmed snapshot works offline', (tester) async {
    final account = FakeResultShareAccountSource()
      ..error = const ChallengeShareException('network', 'offline');
    final launcher = FakeResultShareLauncher();
    await pumpPreview(
      tester,
      service: buildService(account: account, launcher: launcher),
      capture: FakeResultShareCapture(),
      initialSnapshot: ResultShareFixtures.account,
    );
    expect(account.calls, 0);
    expect(find.byKey(const ValueKey('result-share-card')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('result-share-copy')));
    await tester.pumpAndSettle();
    expect(
      launcher.imageBytes,
      isEmpty,
      reason: 'copying a link never opens the share sheet',
    );
  });

  testWidgets('a malformed receipt is refused before any preview artwork',
      (tester) async {
    final service = buildService();
    await pumpPreview(
      tester,
      service: service,
      capture: FakeResultShareCapture(),
      receipt: testReceipt(winnerId: null),
      viewerId: 'u-you',
    );
    expect(find.textContaining('cannot be'), findsOneWidget);
    expect(find.byKey(const ValueKey('result-share-card')), findsNothing);
    expect(find.byKey(const ValueKey('result-share-primary')), findsNothing);
  });

  testWidgets('no-result preview shows no scores and no rating claim',
      (tester) async {
    await pumpPreview(
      tester,
      service: buildService(),
      capture: FakeResultShareCapture(),
      receipt: ResultShareFixtures.noResult.receipt,
    );
    expect(find.text('NO RESULT'), findsOneWidget);
    expect(find.text('no confirmed score'), findsNWidgets(2));
    expect(find.textContaining('Arena rating'), findsNothing);
  });

  testWidgets('missing avatars render as monograms in the preview',
      (tester) async {
    await pumpPreview(
      tester,
      service: buildService(),
      capture: FakeResultShareCapture(),
    );
    expect(find.text('AZ'), findsOneWidget);
    expect(find.text('ZU'), findsOneWidget);
  });

  testWidgets('a share-sheet failure keeps the preview card visible',
      (tester) async {
    final launcher = FakeResultShareLauncher()..imageError = Exception('nope');
    await pumpPreview(
      tester,
      service: buildService(launcher: launcher),
      capture: FakeResultShareCapture(),
    );
    await tester.tap(find.byKey(const ValueKey('result-share-primary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('result-share-card')), findsOneWidget);
    expect(find.textContaining('could not be opened'), findsOneWidget);
  });
}
