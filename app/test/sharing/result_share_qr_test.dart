import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/linking/challenge_link.dart';
import 'package:training_arena/sharing/result_share_models.dart';
import 'package:training_arena/sharing/result_share_qr.dart';

void main() {
  final url = Uri.parse('https://example.invalid/c/ab12cd34ef56');
  final qr = ResultShareQr.fromUrl(url, expectedHost: 'example.invalid');

  group('ResultShareQr', () {
    test('encodes the exact challenge URL', () {
      expect(qr.url, url);
      expect(qr.moduleCount, greaterThanOrEqualTo(21));
      for (final row in qr.modules) {
        expect(row.length, qr.moduleCount);
      }
    });

    test('is deterministic for the same URL', () {
      final again = ResultShareQr.fromUrl(url, expectedHost: 'example.invalid');
      expect(again.moduleCount, qr.moduleCount);
      for (var row = 0; row < qr.moduleCount; row++) {
        for (var col = 0; col < qr.moduleCount; col++) {
          expect(again.isDark(row, col), qr.isDark(row, col));
        }
      }
    });

    test('different URLs produce different matrices', () {
      final other = ResultShareQr.fromUrl(
        Uri.parse('https://example.invalid/c/ff99ee88dd77'),
        expectedHost: 'example.invalid',
      );
      var differences = 0;
      final size = qr.moduleCount < other.moduleCount
          ? qr.moduleCount
          : other.moduleCount;
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          if (qr.isDark(row, col) != other.isDark(row, col)) {
            differences += 1;
          }
        }
      }
      expect(differences, greaterThan(0));
    });

    test('rejects a foreign host', () {
      expect(
        () => ResultShareQr.fromUrl(
          Uri.parse('https://evil.invalid/c/ab12cd34ef56'),
          expectedHost: 'example.invalid',
        ),
        throwsA(
          isA<ResultShareException>()
              .having((error) => error.code, 'code', 'invalid_link'),
        ),
      );
    });

    test('rejects a non-challenge path', () {
      expect(
        () => ResultShareQr.fromUrl(
          Uri.parse('https://example.invalid/welcome'),
          expectedHost: 'example.invalid',
        ),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('rejects a non-https scheme', () {
      expect(
        () => ResultShareQr.fromUrl(
          Uri.parse('http://example.invalid/c/ab12cd34ef56'),
          expectedHost: 'example.invalid',
        ),
        throwsA(isA<ResultShareException>()),
      );
    });

    test('readable code groups the token in fours', () {
      expect(ChallengeLink.readableCodeFor('ab12cd34ef56'), 'AB12-CD34-EF56');
    });
  });

  testWidgets('QR view exposes the URL as accessible alt text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ResultShareQrView(
            qr: qr,
            size: 104,
            semanticLabel: 'QR code that opens the live challenge $url',
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(url.toString()))),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('painter draws without layout errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CustomPaint(
            size: const Size.square(160),
            painter: ResultShareQrPainter(qr),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
