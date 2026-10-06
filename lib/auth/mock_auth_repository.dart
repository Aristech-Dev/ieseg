import 'auth_repository.dart';

/// Dépôt d'auth en mémoire : utilisé en tests et quand Firebase n'est pas
/// configuré. Les comptes sont perdus au rechargement de la page.
class MockAuthRepository implements AuthRepository {
  final Map<String, String> _accounts = {};
  AuthUser? _current;

  String _normalize(String email) => email.trim().toLowerCase();

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final key = _normalize(email);
    if (_accounts.containsKey(key)) {
      throw const AuthException('Un compte existe déjà avec cet email');
    }
    _accounts[key] = password;
    return _current = AuthUser(uid: 'mock-$key', email: key);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final key = _normalize(email);
    if (_accounts[key] != password) {
      throw const AuthException('Email ou mot de passe incorrect');
    }
    return _current = AuthUser(uid: 'mock-$key', email: key);
  }

  @override
  Future<void> signOut() async => _current = null;
}
