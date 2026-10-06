import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'auth/auth_controller.dart';
import 'auth/auth_repository.dart';
import 'auth/mock_auth_repository.dart';
import 'auth/verification_code_service.dart';
import 'onboarding/search_criteria.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final AuthRepository repository = MockAuthRepository();
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
