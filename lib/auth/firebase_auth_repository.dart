import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

String authErrorMessage(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'Un compte existe déjà avec cet email';
    case 'invalid-email':
      return 'Adresse email invalide';
    case 'weak-password':
      return 'Mot de passe trop faible';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email ou mot de passe incorrect';
    case 'network-request-failed':
      return 'Connexion réseau indisponible';
    case 'too-many-requests':
      return 'Trop de tentatives, réessayez plus tard';
    default:
      return 'Une erreur est survenue ($code)';
  }
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AuthUser? _map(User? user) =>
      user == null ? null : AuthUser(uid: user.uid, email: user.email ?? '');

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(cred.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e.code));
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(cred.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
