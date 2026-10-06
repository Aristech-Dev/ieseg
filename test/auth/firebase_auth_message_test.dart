import 'package:autoscope/auth/firebase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authErrorMessage traduit les codes Firebase courants', () {
    expect(authErrorMessage('email-already-in-use'),
        'Un compte existe déjà avec cet email');
    expect(authErrorMessage('invalid-email'), 'Adresse email invalide');
    expect(authErrorMessage('weak-password'), 'Mot de passe trop faible');
    for (final code in ['user-not-found', 'wrong-password', 'invalid-credential']) {
      expect(authErrorMessage(code), 'Email ou mot de passe incorrect');
    }
    expect(authErrorMessage('network-request-failed'),
        'Connexion réseau indisponible');
    expect(authErrorMessage('too-many-requests'),
        'Trop de tentatives, réessayez plus tard');
  });

  test('authErrorMessage a un repli pour un code inconnu', () {
    expect(authErrorMessage('quelque-chose'),
        'Une erreur est survenue (quelque-chose)');
  });
}
