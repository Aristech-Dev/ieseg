import 'package:autoscope/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePassword', () {
    test('accepte exactement 8 caractères avec majuscule et spécial', () {
      expect(validatePassword('Abcdef1!'), isNull);
    });

    test('refuse 7 caractères', () {
      expect(validatePassword('Abcde1!'), contains('8 caractères'));
    });

    test('refuse sans majuscule', () {
      expect(validatePassword('abcdefg!'), contains('majuscule'));
    });

    test('refuse sans caractère spécial', () {
      expect(validatePassword('Abcdefg1'), contains('caractère spécial'));
    });

    test('un espace n\'est pas un caractère spécial', () {
      expect(validatePassword('Abcdefg '), contains('caractère spécial'));
    });

    test('accepte une majuscule accentuée et le symbole €', () {
      expect(validatePassword('Éabcdef€'), isNull);
    });

    test('refuse null et vide', () {
      expect(validatePassword(null), isNotNull);
      expect(validatePassword(''), isNotNull);
    });
  });

  group('passwordRules', () {
    test('expose 3 règles évaluables', () {
      expect(passwordRules, hasLength(3));
      expect(passwordRules.map((r) => r.test('Abcdef1!')), everyElement(isTrue));
      expect(passwordRules.map((r) => r.test('')), everyElement(isFalse));
    });
  });

  group('validateEmail', () {
    test('accepte une adresse valide avec espaces autour', () {
      expect(validateEmail('  user@mail.fr '), isNull);
    });

    test('refuse vide, sans arobase et sans domaine', () {
      expect(validateEmail(''), 'Saisissez votre email');
      expect(validateEmail(null), 'Saisissez votre email');
      expect(validateEmail('user.mail.fr'), 'Adresse email invalide');
      expect(validateEmail('user@mail'), 'Adresse email invalide');
    });
  });

  group('validateConfirm', () {
    test('accepte deux saisies identiques', () {
      expect(validateConfirm('Abcdef1!', 'Abcdef1!'), isNull);
    });

    test('refuse deux saisies différentes', () {
      expect(
        validateConfirm('Abcdef1!', 'Abcdef1?'),
        'Les mots de passe ne correspondent pas',
      );
    });
  });
}
