import 'package:firebase_core/firebase_core.dart';

/// Configuration web Firebase injectée au build via --dart-define.
/// Ces valeurs ne sont pas secrètes (elles sont publiques côté navigateur).
class FirebaseConfig {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static bool get isConfigured =>
      apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? '$projectId.firebaseapp.com' : authDomain,
      );
}
