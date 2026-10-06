import 'package:autoscope/app.dart';
import 'package:autoscope/auth/auth_controller.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:autoscope/auth/verification_code_service.dart';
import 'package:autoscope/onboarding/search_criteria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<(MockAuthRepository, VerificationCodeService)> _deps() async =>
    (MockAuthRepository(), VerificationCodeService(await mockPrefs()));

Future<void> _pumpApp(
  WidgetTester tester,
  AuthController auth, {
  String initialLocation = '/login',
}) async {
  useTallScreen(tester);
  await tester.pumpWidget(AutoscopeApp(
    auth: auth,
    criteria: SearchCriteria(),
    initialLocation: initialLocation,
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('parcours complet : inscription, code, OnBoarding, Feed, filtre, déconnexion', (tester) async {
    final (repo, codes) = await _deps();
    final auth = AuthController(repository: repo, codes: codes);
    await _pumpApp(tester, auth);
    expect(find.byKey(const Key('login-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('signup-link')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('signup-email-field')), 'demo@autoscope.fr');
    await tester.enterText(
        find.byKey(const Key('signup-password-field')), 'Demo1234!');
    await tester.enterText(
        find.byKey(const Key('signup-confirm-field')), 'Demo1234!');
    await tester.tap(find.byKey(const Key('signup-button')));
    await tester.pumpAndSettle();

    final code =
        tester.widget<Text>(find.byKey(const Key('demo-code-value'))).data!;
    await tester.enterText(find.byKey(const Key('code-field')), code);
    await tester.tap(find.byKey(const Key('verify-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('validate-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('validate-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('contact-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('validate-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });

  testWidgets('une reconnexion avec compte non vérifié mène à la saisie du code', (tester) async {
    final (repo, codes) = await _deps();
    final auth = AuthController(repository: repo, codes: codes);
    await auth.signUp('a@b.fr', 'Abcdef1!');
    await auth.signOut();
    await _pumpApp(tester, auth);

    await tester.enterText(find.byKey(const Key('email-field')), 'a@b.fr');
    await tester.enterText(find.byKey(const Key('password-field')), 'Abcdef1!');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('code-field')), findsOneWidget);
  });

  testWidgets('sans session, /feed et /onboarding redirigent vers /login', (tester) async {
    final (repo, codes) = await _deps();
    for (final location in ['/feed', '/onboarding', '/verify']) {
      await _pumpApp(tester, AuthController(repository: repo, codes: codes),
          initialLocation: location);
      expect(find.byKey(const Key('login-button')), findsOneWidget,
          reason: location);
    }
  });

  testWidgets('connecté non vérifié : /feed redirige vers /verify', (tester) async {
    final (repo, codes) = await _deps();
    final auth = AuthController(repository: repo, codes: codes);
    await auth.signUp('a@b.fr', 'Abcdef1!');
    await _pumpApp(tester, auth, initialLocation: '/feed');
    expect(find.byKey(const Key('code-field')), findsOneWidget);
    expect(find.byKey(const Key('contact-button')), findsNothing);
  });

  testWidgets('connecté vérifié : /login redirige vers /onboarding', (tester) async {
    final (repo, codes) = await _deps();
    final auth = AuthController(repository: repo, codes: codes);
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.verifyCode(auth.demoCode!);
    await _pumpApp(tester, auth, initialLocation: '/login');
    expect(find.byKey(const Key('validate-button')), findsOneWidget);
  });

  testWidgets('rechargement : la session vérifiée permet de rester sur /feed', (tester) async {
    final (repo, codes) = await _deps();
    final first = AuthController(repository: repo, codes: codes);
    await first.signUp('a@b.fr', 'Abcdef1!');
    first.verifyCode(first.demoCode!);
    final reloaded = AuthController(repository: repo, codes: codes);
    await _pumpApp(tester, reloaded, initialLocation: '/feed');
    expect(find.byKey(const Key('contact-button')), findsOneWidget);
  });
}
