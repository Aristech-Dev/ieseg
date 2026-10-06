import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Code de vérification à 6 chiffres SIMULÉ : généré et stocké côté client.
/// Non sécurisé, réservé à la démo (la production demanderait un backend).
class VerificationCodeService {
  VerificationCodeService(this._prefs, {Random? random})
      : _random = random ?? Random.secure();

  final SharedPreferences _prefs;
  final Random _random;

  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  String _codeKey(String uid) => 'verification_code_$uid';
  String _verifiedKey(String uid) => 'verified_$uid';

  String issueCode(String uid) {
    final code = _random.nextInt(1000000).toString().padLeft(6, '0');
    unawaited(_prefs.setString(_codeKey(uid), code));
    return code;
  }

  String? pendingCode(String uid) => _prefs.getString(_codeKey(uid));

  bool isVerified(String uid) => _prefs.getBool(_verifiedKey(uid)) ?? false;

  bool verify(String uid, String input) {
    final candidate = input.trim();
    final expected = pendingCode(uid);
    if (expected == null ||
        !_sixDigits.hasMatch(candidate) ||
        candidate != expected) {
      return false;
    }
    unawaited(_prefs.setBool(_verifiedKey(uid), true));
    unawaited(_prefs.remove(_codeKey(uid)));
    return true;
  }
}
