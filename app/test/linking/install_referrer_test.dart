import 'package:flutter_test/flutter_test.dart';
import 'package:training_arena/linking/install_referrer.dart';

void main() {
  group('challengeTokenFromReferrer', () {
    test('reads a plain challenge token', () {
      expect(
        challengeTokenFromReferrer('challenge=Ab12Cd34Ef56'),
        'ab12cd34ef56',
      );
    });

    test('reads an encoded referrer from the Play URL', () {
      const referrer = 'challenge%3Dab12cd34ef56';
      expect(challengeTokenFromReferrer(referrer), 'ab12cd34ef56');
    });

    test('reads token= and full URLs', () {
      expect(challengeTokenFromReferrer('token=ab12cd34ef56'), 'ab12cd34ef56');
      expect(
        challengeTokenFromReferrer('utm=1&challenge=ab12cd34ef56&x=2'),
        'ab12cd34ef56',
      );
      expect(
        challengeTokenFromReferrer(
          'https%3A%2F%2Fexample.invalid%2Fc%2Fab12cd34ef56',
        ),
        'ab12cd34ef56',
      );
      expect(
        challengeTokenFromReferrer(
          'trainingarena://challenge/ab12cd34ef56',
        ),
        'ab12cd34ef56',
      );
    });

    test('fails closed on missing or fake-broken values', () {
      expect(challengeTokenFromReferrer(null), isNull);
      expect(challengeTokenFromReferrer(''), isNull);
      expect(challengeTokenFromReferrer('challenge='), isNull);
      expect(challengeTokenFromReferrer('challenge=short'), isNull);
      expect(challengeTokenFromReferrer('utm_source=play'), isNull);
    });
  });
}
