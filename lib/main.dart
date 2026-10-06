import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_repository.dart';
import 'auth/firebase_auth_repository.dart';
import 'auth/mock_auth_repository.dart';
import 'auth/verification_code_service.dart';
import 'firebase_config.dart';
import 'onboarding/search_criteria.dart';

Future<AuthRepository> _createRepository() async {
  if (!FirebaseConfig.isConfigured) {
    debugPrint('Firebase non configuré : mode démo avec comptes en mémoire.');
    return MockAuthRepository();
  }
  await Firebase.initializeApp(options: FirebaseConfig.options);
  return FirebaseAuthRepository();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = await _createRepository();
  runApp(
    AutoscopeApp(
      auth: AuthController(
        repository: repository,
        codes: VerificationCodeService(prefs),
      ),
      criteria: SearchCriteria(),
    ),
  );
}
