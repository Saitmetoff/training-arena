/// Copy guard: user-facing strings must not make forbidden claims.
///
/// Scans single-line string literals under `lib/` for phrases the product
/// must never use (accuracy percentages, "cheat-proof", guarantees, medical
/// claims). Heuristic: multiline and interpolated literals are not parsed
/// exhaustively; the goal is to catch the phrases as they are written, not to
/// be a Dart parser. Documentation comments are out of scope.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lower-case phrases that must never appear in a user-facing string.
const List<String> forbiddenPhrases = <String>[
  'cheat-proof',
  'cheat proof',
  'guaranteed',
  'guarantee',
  'medically proven',
  'clinically proven',
  'fda approved',
  'fda-approved',
];

/// Numeric accuracy claims such as "98% accurate".
final RegExp numericAccuracy =
    RegExp(r'\d+\s*%\s*(accurate|accuracy)', caseSensitive: false);

final RegExp singleLineLiteral = RegExp(r"'([^'\\\n]|\\.)*'");

void main() {
  test('no forbidden claim appears in a lib/ string literal', () {
    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in singleLineLiteral.allMatches(source)) {
        final literal = match.group(0)!;
        final lower = literal.toLowerCase();
        for (final phrase in forbiddenPhrases) {
          if (lower.contains(phrase)) {
            violations.add('${file.path}: $literal');
          }
        }
        if (numericAccuracy.hasMatch(literal)) {
          violations.add('${file.path}: $literal');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Forbidden claims found:\n${violations.join('\n')}',
    );
  });

  test('the on-device processing statement is present', () {
    final source = File('lib/camera/camera_types.dart').readAsStringSync();
    expect(source, contains('ever leaves the device'));
    final settings = File('lib/account/ui/settings_page.dart').readAsStringSync();
    expect(settings, contains('never'));
    expect(settings, contains('uploaded'));
  });
}
