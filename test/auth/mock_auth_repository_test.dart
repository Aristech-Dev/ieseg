import 'package:autoscope/auth/auth_repository.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signUp crée un compte et connecte l\'utilisateur', () async {
    final repo = MockAuthRepository();
    final user = await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    expect(user.email, 'a@b.fr');
    expect(repo.currentUser?.uid, user.uid);
  });

  test('l\'email est normalisé (espaces et casse)', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: ' User@Mail.COM ', password: 'Abcdef1!');
    await repo.signOut();
    final user = await repo.signIn(email: 'user@mail.com', password: 'Abcdef1!');
    expect(user.email, 'user@mail.com');
  });

  test('signUp en double lève une AuthException', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    expect(
      () => repo.signUp(email: 'A@B.fr', password: 'Autre1234!'),
      throwsA(isA<AuthException>().having(
        (e) => e.message,
        'message',
        'Un compte existe déjà avec cet email',
      )),
    );
  });

  test('signIn refuse un mauvais mot de passe et un compte inconnu', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    await repo.signOut();
    for (final attempt in [
      ('a@b.fr', 'Mauvais1!'),
      ('inconnu@b.fr', 'Abcdef1!'),
    ]) {
      expect(
        () => repo.signIn(email: attempt.$1, password: attempt.$2),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Email ou mot de passe incorrect',
        )),
      );
    }
    expect(repo.currentUser, isNull);
  });

  test('signOut efface l\'utilisateur courant', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    await repo.signOut();
    expect(repo.currentUser, isNull);
  });
}
