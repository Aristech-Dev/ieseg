import 'package:autoscope/auth/auth_controller.dart';
import 'package:autoscope/auth/auth_repository.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:autoscope/auth/verification_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<(AuthController, MockAuthRepository, VerificationCodeService)>
    _setup() async {
  final repo = MockAuthRepository();
  final codes = VerificationCodeService(await mockPrefs());
  return (AuthController(repository: repo, codes: codes), repo, codes);
}

void main() {
  test('état initial : non connecté', () async {
    final (auth, _, _) = await _setup();
    expect(auth.isSignedIn, isFalse);
    expect(auth.isVerified, isFalse);
    expect(auth.demoCode, isNull);
  });

  test('signUp connecte, émet un code et reste non vérifié', () async {
    final (auth, _, _) = await _setup();
    var notified = 0;
    auth.addListener(() => notified++);
    await auth.signUp('a@b.fr', 'Abcdef1!');
    expect(auth.isSignedIn, isTrue);
    expect(auth.isVerified, isFalse);
    expect(auth.demoCode, matches(RegExp(r'^\d{6}$')));
    expect(notified, 1);
  });

  test('verifyCode valide le bon code puis isVerified passe à true', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    expect(auth.verifyCode('000000x'), isFalse);
    expect(auth.isVerified, isFalse);
    expect(auth.verifyCode(auth.demoCode!), isTrue);
    expect(auth.isVerified, isTrue);
  });

  test('signIn d\'un compte non vérifié sans code en attente en émet un', () async {
    final (auth, repo, codes) = await _setup();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    await repo.signOut();
    await auth.signIn('a@b.fr', 'Abcdef1!');
    expect(auth.isVerified, isFalse);
    expect(codes.pendingCode(auth.user!.uid), isNotNull);
  });

  test('signIn d\'un compte déjà vérifié reste vérifié', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.verifyCode(auth.demoCode!);
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    await auth.signIn('a@b.fr', 'Abcdef1!');
    expect(auth.isVerified, isTrue);
  });

  test('un mauvais mot de passe propage l\'AuthException', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    await auth.signOut();
    await expectLater(() => auth.signIn('a@b.fr', 'Nope1234!'),
        throwsA(isA<AuthException>()));
    expect(auth.isSignedIn, isFalse);
  });

  test('resendCode émet un nouveau code valide', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.resendCode();
    expect(auth.verifyCode(auth.demoCode!), isTrue);
  });

  test('un nouveau contrôleur reprend la session du dépôt (rechargement)', () async {
    final (auth, repo, codes) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.verifyCode(auth.demoCode!);
    final reloaded = AuthController(repository: repo, codes: codes);
    expect(reloaded.isSignedIn, isTrue);
    expect(reloaded.isVerified, isTrue);
  });
}
