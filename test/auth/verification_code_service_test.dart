import 'dart:math';

import 'package:autoscope/auth/verification_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  test('issueCode génère 6 chiffres en conservant les zéros initiaux', () async {
    final service = VerificationCodeService(
      await mockPrefs(),
      random: _FixedRandom(4217),
    );
    expect(service.issueCode('u1'), '004217');
    expect(service.pendingCode('u1'), '004217');
  });

  test('un code aléatoire fait toujours 6 chiffres', () async {
    final service = VerificationCodeService(await mockPrefs());
    for (var i = 0; i < 50; i++) {
      expect(service.issueCode('u1'), matches(RegExp(r'^\d{6}$')));
    }
  });

  test('verify accepte le bon code (espaces autour tolérés) et marque vérifié', () async {
    final service = VerificationCodeService(
      await mockPrefs(),
      random: _FixedRandom(4217),
    );
    service.issueCode('u1');
    expect(service.isVerified('u1'), isFalse);
    expect(service.verify('u1', ' 004217 '), isTrue);
    expect(service.isVerified('u1'), isTrue);
    expect(service.pendingCode('u1'), isNull);
  });

  test('verify refuse mauvais code, 5 chiffres et lettres', () async {
    final service = VerificationCodeService(
      await mockPrefs(),
      random: _FixedRandom(123456),
    );
    service.issueCode('u1');
    expect(service.verify('u1', '654321'), isFalse);
    expect(service.verify('u1', '12345'), isFalse);
    expect(service.verify('u1', '12345a'), isFalse);
    expect(service.verify('u1', ''), isFalse);
    expect(service.isVerified('u1'), isFalse);
  });

  test('verify refuse tout quand aucun code n\'est en attente', () async {
    final service = VerificationCodeService(await mockPrefs());
    expect(service.verify('u1', '000000'), isFalse);
  });

  test('l\'état est isolé par utilisateur et persiste dans les prefs', () async {
    final prefs = await mockPrefs();
    final a = VerificationCodeService(prefs, random: _FixedRandom(111111));
    a.issueCode('u1');
    a.verify('u1', '111111');
    final b = VerificationCodeService(prefs);
    expect(b.isVerified('u1'), isTrue);
    expect(b.isVerified('u2'), isFalse);
  });
}
