import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'verification_code_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required VerificationCodeService codes,
  })  : _repository = repository,
        _codes = codes,
        _user = repository.currentUser;

  final AuthRepository _repository;
  final VerificationCodeService _codes;
  AuthUser? _user;

  AuthUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isVerified => _user != null && _codes.isVerified(_user!.uid);
  String? get demoCode => _user == null ? null : _codes.pendingCode(_user!.uid);

  Future<void> signUp(String email, String password) async {
    final user = await _repository.signUp(email: email, password: password);
    _codes.issueCode(user.uid);
    _user = user;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final user = await _repository.signIn(email: email, password: password);
    if (!_codes.isVerified(user.uid) && _codes.pendingCode(user.uid) == null) {
      _codes.issueCode(user.uid);
    }
    _user = user;
    notifyListeners();
  }

  bool verifyCode(String input) {
    final user = _user;
    if (user == null) return false;
    final ok = _codes.verify(user.uid, input);
    if (ok) notifyListeners();
    return ok;
  }

  void resendCode() {
    final user = _user;
    if (user == null) return;
    _codes.issueCode(user.uid);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
  }
}
