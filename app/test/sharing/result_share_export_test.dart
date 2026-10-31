import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/sharing/fixtures/result_share_fixtures.dart';
import 'package:training_arena/sharing/result_share_card_view.dart';
import 'package:training_arena/sharing/result_share_models.dart';
import 'package:training_arena/sharing/result_share_service.dart';

int _pngWidth(List<int> bytes) =>
    (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];

int _pngHeight(List<int> bytes) =>
    (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];

void main() {
  const capture = RepaintBoundaryResultShareCapture();

  Future<GlobalKey> pumpCard(
    WidgetTester tester,
    ResultShareFormat format,
    ResultShareCard card,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: ResultShareCardView(card: card, format: format),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return key;
  }

  /// `toImage` needs real async; the boundary is already painted, so the
  /// capture never waits for another frame.
  Future<List<int>> export(
    WidgetTester tester,
    GlobalKey key,
    ResultShareFormat format,
  ) async {
    final bytes = await tester.runAsync(
      () => capture.capturePng(boundaryKey: key, format: format),
    );
    return bytes!;
  }

  testWidgets('stories export is exactly 1080x1920', (tester) async {
    final key = await pumpCard(
      tester,
      ResultShareFormat.stories,
      ResultShareFixtures.winCasual,
    );
    final bytes = await export(tester, key, ResultShareFormat.stories);
    expect(bytes.length, greaterThan(24));
    expect(_pngWidth(bytes), 1080);
    expect(_pngHeight(bytes), 1920);
  });

  testWidgets('feed export is exactly 1080x1350', (tester) async {
    final key = await pumpCard(
      tester,
      ResultShareFormat.feed,
      ResultShareFixtures.winCasual,
    );
    final bytes = await export(tester, key, ResultShareFormat.feed);
    expect(_pngWidth(bytes), 1080);
    expect(_pngHeight(bytes), 1350);
  });

  testWidgets('export is deterministic for the same card and format',
      (tester) async {
    final key = await pumpCard(
      tester,
      ResultShareFormat.feed,
      ResultShareFixtures.winRanked,
    );
    final first = await export(tester, key, ResultShareFormat.feed);
    final second = await export(tester, key, ResultShareFormat.feed);
    expect(second, first);
  });

  testWidgets('every fixture exports at both exact sizes', (tester) async {
    for (final card in ResultShareFixtures.all) {
      for (final format in ResultShareFormat.values) {
        final key = await pumpCard(tester, format, card);
        final bytes = await export(tester, key, format);
        expect(_pngWidth(bytes), format.pixelWidth,
            reason: '${card.outcome.wire} ${format.name}');
        expect(_pngHeight(bytes), format.pixelHeight,
            reason: '${card.outcome.wire} ${format.name}');
      }
    }
  });

  test('capture without a mounted preview fails with preview_required', () {
    expectLater(
      capture.capturePng(
        boundaryKey: GlobalKey(),
        format: ResultShareFormat.stories,
      ),
      throwsA(
        isA<ResultShareException>()
            .having((error) => error.code, 'code', 'preview_required'),
      ),
    );
  });
}
