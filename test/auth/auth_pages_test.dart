import 'package:autoscope/auth/auth_controller.dart';
import 'package:autoscope/auth/login_page.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:autoscope/auth/signup_page.dart';
import 'package:autoscope/auth/verification_code_service.dart';
import 'package:autoscope/auth/verify_code_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

Future<AuthController> _pump(WidgetTester tester, Widget page) async {
  useTallScreen(tester);
  final auth = AuthController(
    repository: MockAuthRepository(),
    codes: VerificationCodeService(await mockPrefs()),
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthController>.value(
      value: auth,
      child: MaterialApp(home: page),
    ),
  );
  return auth;
}

void main() {
  group('LoginPage', () {
    testWidgets('affiche logo, champs, bouton et lien d\'inscription', (tester) async {
      await _pump(tester, const LoginPage());
      expect(find.text('Autoscope'), findsOneWidget);
      expect(find.byKey(const Key('email-field')), findsOneWidget);
      expect(find.byKey(const Key('password-field')), findsOneWidget);
      expect(find.text('Me connecter'), findsOneWidget);
      expect(find.text('Je n\'ai pas de compte'), findsOneWidget);
    });

    testWidgets('un formulaire vide affiche les erreurs', (tester) async {
      await _pump(tester, const LoginPage());
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez votre email'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe'), findsOneWidget);
    });

    testWidgets('des identifiants inconnus affichent l\'erreur du dépôt', (tester) async {
      await _pump(tester, const LoginPage());
      await tester.enterText(find.byKey(const Key('email-field')), 'x@y.fr');
      await tester.enterText(find.byKey(const Key('password-field')), 'Abcdef1!');
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();
      expect(find.text('Email ou mot de passe incorrect'), findsOneWidget);
    });
  });

  group('SignupPage', () {
    testWidgets('la checklist suit la saisie du mot de passe', (tester) async {
      await _pump(tester, const SignupPage());
      expect(find.byIcon(Icons.check_circle), findsNothing);
      await tester.enterText(
          find.byKey(const Key('signup-password-field')), 'Abcdefgh');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      await tester.enterText(
          find.byKey(const Key('signup-password-field')), 'Abcdef1!');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    });

    testWidgets('refuse une confirmation différente', (tester) async {
      await _pump(tester, const SignupPage());
      await tester.enterText(find.byKey(const Key('signup-email-field')), 'a@b.fr');
      await tester.enterText(
          find.byKey(const Key('signup-password-field')), 'Abcdef1!');
      await tester.enterText(
          find.byKey(const Key('signup-confirm-field')), 'Abcdef1?');
      await tester.tap(find.byKey(const Key('signup-button')));
      await tester.pumpAndSettle();
      expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
    });

    testWidgets('refuse un mot de passe faible sans appeler le dépôt', (tester) async {
      final auth = await _pump(tester, const SignupPage());
      await tester.enterText(find.byKey(const Key('signup-email-field')), 'a@b.fr');
      await tester.enterText(find.byKey(const Key('signup-password-field')), 'abc');
      await tester.enterText(find.byKey(const Key('signup-confirm-field')), 'abc');
      await tester.tap(find.byKey(const Key('signup-button')));
      await tester.pumpAndSettle();
      expect(find.text('Le mot de passe doit contenir au moins 8 caractères'),
          findsOneWidget);
      expect(auth.isSignedIn, isFalse);
    });

    testWidgets('une inscription valide crée le compte', (tester) async {
      final auth = await _pump(tester, const SignupPage());
      await tester.enterText(find.byKey(const Key('signup-email-field')), 'a@b.fr');
      await tester.enterText(
          find.byKey(const Key('signup-password-field')), 'Abcdef1!');
      await tester.enterText(
          find.byKey(const Key('signup-confirm-field')), 'Abcdef1!');
      await tester.tap(find.byKey(const Key('signup-button')));
      await tester.pumpAndSettle();
      expect(auth.isSignedIn, isTrue);
      expect(auth.isVerified, isFalse);
    });

    testWidgets('une inscription en double affiche l\'erreur', (tester) async {
      final auth = await _pump(tester, const SignupPage());
      await auth.signUp('a@b.fr', 'Abcdef1!');
      await auth.signOut();
      await tester.enterText(find.byKey(const Key('signup-email-field')), 'a@b.fr');
      await tester.enterText(
          find.byKey(const Key('signup-password-field')), 'Abcdef1!');
      await tester.enterText(
          find.byKey(const Key('signup-confirm-field')), 'Abcdef1!');
      await tester.tap(find.byKey(const Key('signup-button')));
      await tester.pumpAndSettle();
      expect(find.text('Un compte existe déjà avec cet email'), findsOneWidget);
    });
  });

  group('VerifyCodePage', () {
    Future<AuthController> pumpVerify(WidgetTester tester) async {
      final auth = await _pump(tester, const VerifyCodePage());
      await auth.signUp('a@b.fr', 'Abcdef1!');
      await tester.pump();
      return auth;
    }

    testWidgets('affiche le code de démonstration', (tester) async {
      final auth = await pumpVerify(tester);
      final shown =
          tester.widget<Text>(find.byKey(const Key('demo-code-value'))).data;
      expect(shown, auth.demoCode);
      expect(find.textContaining('Mode démo'), findsOneWidget);
    });

    testWidgets('un mauvais code ou un code de 5 chiffres est refusé', (tester) async {
      final auth = await pumpVerify(tester);
      for (final bad in ['000000x', '12345']) {
        await tester.enterText(find.byKey(const Key('code-field')), bad);
        await tester.tap(find.byKey(const Key('verify-button')));
        await tester.pumpAndSettle();
        expect(find.text('Code incorrect'), findsOneWidget);
      }
      expect(auth.isVerified, isFalse);
    });

    testWidgets('le bon code vérifie le compte', (tester) async {
      final auth = await pumpVerify(tester);
      await tester.enterText(find.byKey(const Key('code-field')), auth.demoCode!);
      await tester.tap(find.byKey(const Key('verify-button')));
      await tester.pumpAndSettle();
      expect(auth.isVerified, isTrue);
    });

    testWidgets('le champ n\'accepte que 6 chiffres', (tester) async {
      await pumpVerify(tester);
      await tester.enterText(find.byKey(const Key('code-field')), '12ab3456789');
      final field =
          tester.widget<TextField>(find.byKey(const Key('code-field')));
      expect(field.controller!.text, '123456');
    });
  });
}
