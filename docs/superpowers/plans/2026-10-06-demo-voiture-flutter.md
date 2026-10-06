# Démo Flutter « Autoscope » Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construire une démo Flutter web (mobile-first) avec Connexion/Inscription (Firebase Auth + code à 6 chiffres simulé), OnBoarding (formulaire de recherche) et Feed (fiche véhicule), déployée sur GitHub Pages.

**Architecture:** `go_router` pour la navigation et les gardes d'accès, `provider` (`ChangeNotifier`) pour l'état (`AuthController`, `SearchCriteria`). L'accès aux comptes passe par une interface `AuthRepository` (implémentation Firebase + implémentation mock en mémoire utilisée en tests et quand Firebase n'est pas configuré). Le code à 6 chiffres est généré côté client, stocké via `shared_preferences` (localStorage) et affiché dans un bandeau « Mode démo ».

**Tech Stack:** Flutter (web), `go_router`, `provider`, `firebase_core`, `firebase_auth`, `shared_preferences`, `flutter_svg`, GitHub Actions + GitHub Pages.

**Spec:** `docs/superpowers/specs/2026-10-06-demo-voiture-flutter-design.md`

## Global Constraints

- Interface entièrement en français, avec accents corrects.
- Nom de l'app : « Autoscope » ; nom du package Dart : `autoscope`.
- Mot de passe : minimum 8 caractères, minimum 1 majuscule, minimum 1 caractère spécial ; saisi deux fois à l'inscription.
- Le code de vérification fait exactement 6 chiffres (zéros initiaux conservés, donc type `String`).
- Aucun email n'est envoyé : le code est affiché dans un bandeau « Mode démo », et la page précise que ce n'est pas sécurisé.
- Aucune base de données : seul `shared_preferences` est utilisé (état « vérifié » et code en attente par `uid`).
- Puissance : intervalle de 60 à 1000 ch. Marques : Peugeot, Renault, Audi, BMW (bouton avec logo à gauche).
- Le bouton « Je souhaite être contacté » n'a aucune action.
- La navigation web utilise la stratégie d'URL par défaut de Flutter (hash), compatible GitHub Pages.
- Les logos de marques et les visuels véhicule sont des illustrations SVG dessinées (placeholders, pas d'assets officiels ni de photos), remplaçables en changeant les fichiers référencés.
- Les messages de commit se terminent par `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Aucun dépôt GitHub distant n'est créé et rien n'est poussé sans l'accord explicite de l'utilisateur.

## Review Focus

Entrées ou situations que la spec implique sans que le parcours nominal les exerce, de la plus probable à la moins probable :

1. Mot de passe aux limites : 7 vs 8 caractères, espace seul (non spécial), majuscule accentuée, symbole `€` → Task 2.
2. Saisie du code : espaces autour, 5 chiffres, lettres, zéros initiaux (`004217`), aucun code en attente → Task 3.
3. Email avec casse/espaces (` User@Mail.com `), inscription en double, mauvais mot de passe, erreurs Firebase en français → Tasks 4 et 5.
4. Accès direct par URL / rechargement : `/feed` sans session, utilisateur non vérifié sur `/feed`, utilisateur vérifié sur `/login` → Task 8.
5. État du formulaire : puissance hors bornes ou inversée, marque cliquée deux fois, « Sélectionner une ville » sans ville (défaut), « Retour à l'accueil » qui réinitialise contre le filtre qui conserve → Tasks 6 et 7.

---

## File Structure

```
pubspec.yaml
lib/
  main.dart                          point d'entrée (prefs + dépôt d'auth + runApp)
  app.dart                           AutoscopeApp (providers, MaterialApp.router, largeur max)
  router.dart                        createRouter(auth) + gardes
  firebase_config.dart               config Firebase via --dart-define
  core/
    theme.dart                       buildTheme()
    app_logo.dart                    AppLogo
    validators.dart                  règles mot de passe, validateEmail/Password/Confirm
  auth/
    auth_repository.dart             AuthUser, AuthException, AuthRepository
    mock_auth_repository.dart        implémentation en mémoire
    firebase_auth_repository.dart    implémentation Firebase + authErrorMessage
    verification_code_service.dart   code 6 chiffres + état vérifié (prefs)
    auth_controller.dart             ChangeNotifier de session
    login_page.dart, signup_page.dart, verify_code_page.dart
  onboarding/
    search_criteria.dart             enums + SearchCriteria (ChangeNotifier)
    brand_button.dart, crit_air_section.dart, onboarding_page.dart
  feed/
    vehicle.dart                     Vehicle + formatNumber
    photo_carousel.dart, feed_page.dart
assets/brands/*.svg, assets/photos/*.svg
test/                                miroir de lib/ + helpers.dart
.github/workflows/deploy.yml
README.md
```

---

### Task 1: Scaffold Flutter, thème et logo

**Files:**
- Create: projet Flutter à la racine (`flutter create`), `lib/core/theme.dart`, `lib/core/app_logo.dart`
- Modify: `pubspec.yaml`, `lib/main.dart`
- Delete: `test/widget_test.dart`
- Test: `test/core/app_logo_test.dart`

**Interfaces:**
- Produces: `ThemeData buildTheme()`, `class AppLogo extends StatelessWidget { const AppLogo({super.key, double size = 72}) }` (affiche le texte `Autoscope`).

- [ ] **Step 1: Vérifier l'outillage et créer le projet**

Run:
```bash
cd /Users/vincentfalies/dev/ieseg
flutter --version
flutter create --project-name autoscope --org com.autoscope --platforms web .
```
Expected: « All done! » ; `pubspec.yaml`, `lib/main.dart`, `web/` créés. Le dossier `docs/` et le dépôt git existants restent intacts.

- [ ] **Step 2: Ajouter les dépendances**

Run:
```bash
flutter pub add go_router provider firebase_core firebase_auth shared_preferences flutter_svg
```
Expected: « Got dependencies! » sans erreur de résolution.

- [ ] **Step 3: Écrire le test qui échoue**

Create `test/core/app_logo_test.dart`:
```dart
import 'package:autoscope/core/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppLogo affiche le nom de l\'application', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: AppLogo()))),
    );
    expect(find.text('Autoscope'), findsOneWidget);
    expect(find.byIcon(Icons.directions_car_filled), findsOneWidget);
  });
}
```
Run: `rm test/widget_test.dart && flutter test test/core/app_logo_test.dart`
Expected: FAIL (`app_logo.dart` n'existe pas).

- [ ] **Step 4: Implémenter le thème et le logo**

Create `lib/core/theme.dart`:
```dart
import 'package:flutter/material.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1B4DFF));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
  );
}
```

Create `lib/core/app_logo.dart`:
```dart
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          child: Icon(
            Icons.directions_car_filled,
            color: scheme.onPrimary,
            size: size * 0.55,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Autoscope',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
```

Replace `lib/main.dart` (provisoire, réécrit en Task 8):
```dart
import 'package:flutter/material.dart';

import 'core/app_logo.dart';
import 'core/theme.dart';

void main() {
  runApp(
    MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(body: Center(child: AppLogo())),
    ),
  );
}
```

- [ ] **Step 5: Vérifier**

Run: `flutter test && flutter analyze --no-fatal-infos`
Expected: tests PASS, « No issues found » (ou infos seulement).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter web, thème et logo" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Validateurs (email, mot de passe, confirmation)

**Files:**
- Create: `lib/core/validators.dart`
- Test: `test/core/validators_test.dart`

**Interfaces:**
- Produces:
  - `class PasswordRule { const PasswordRule(this.label, this.error, this.test); final String label; final String error; final bool Function(String) test; }`
  - `const List<PasswordRule> passwordRules` (3 règles : longueur, majuscule, caractère spécial, dans cet ordre)
  - `String? validatePassword(String? value)`, `String? validateEmail(String? value)`, `String? validateConfirm(String? password, String? confirm)` (retournent `null` si valide, sinon un message français).

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/core/validators_test.dart`:
```dart
import 'package:autoscope/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePassword', () {
    test('accepte exactement 8 caractères avec majuscule et spécial', () {
      expect(validatePassword('Abcdef1!'), isNull);
    });

    test('refuse 7 caractères', () {
      expect(validatePassword('Abcde1!'), contains('8 caractères'));
    });

    test('refuse sans majuscule', () {
      expect(validatePassword('abcdefg!'), contains('majuscule'));
    });

    test('refuse sans caractère spécial', () {
      expect(validatePassword('Abcdefg1'), contains('caractère spécial'));
    });

    test('un espace n\'est pas un caractère spécial', () {
      expect(validatePassword('Abcdefg '), contains('caractère spécial'));
    });

    test('accepte une majuscule accentuée et le symbole €', () {
      expect(validatePassword('Éabcdef€'), isNull);
    });

    test('refuse null et vide', () {
      expect(validatePassword(null), isNotNull);
      expect(validatePassword(''), isNotNull);
    });
  });

  group('passwordRules', () {
    test('expose 3 règles évaluables', () {
      expect(passwordRules, hasLength(3));
      expect(passwordRules.map((r) => r.test('Abcdef1!')), everyElement(isTrue));
      expect(passwordRules.map((r) => r.test('')), everyElement(isFalse));
    });
  });

  group('validateEmail', () {
    test('accepte une adresse valide avec espaces autour', () {
      expect(validateEmail('  user@mail.fr '), isNull);
    });

    test('refuse vide, sans arobase et sans domaine', () {
      expect(validateEmail(''), 'Saisissez votre email');
      expect(validateEmail(null), 'Saisissez votre email');
      expect(validateEmail('user.mail.fr'), 'Adresse email invalide');
      expect(validateEmail('user@mail'), 'Adresse email invalide');
    });
  });

  group('validateConfirm', () {
    test('accepte deux saisies identiques', () {
      expect(validateConfirm('Abcdef1!', 'Abcdef1!'), isNull);
    });

    test('refuse deux saisies différentes', () {
      expect(
        validateConfirm('Abcdef1!', 'Abcdef1?'),
        'Les mots de passe ne correspondent pas',
      );
    });
  });
}
```
Run: `flutter test test/core/validators_test.dart`
Expected: FAIL (fichier manquant).

- [ ] **Step 2: Implémenter**

Create `lib/core/validators.dart`:
```dart
class PasswordRule {
  const PasswordRule(this.label, this.error, this.test);

  final String label;
  final String error;
  final bool Function(String) test;
}

final RegExp _uppercase = RegExp(r'\p{Lu}', unicode: true);
final RegExp _special = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool _hasMinLength(String v) => v.length >= 8;
bool _hasUppercase(String v) => _uppercase.hasMatch(v);
bool _hasSpecial(String v) => _special.hasMatch(v);

const List<PasswordRule> passwordRules = [
  PasswordRule(
    '8 caractères minimum',
    'Le mot de passe doit contenir au moins 8 caractères',
    _hasMinLength,
  ),
  PasswordRule(
    '1 majuscule minimum',
    'Le mot de passe doit contenir au moins une majuscule',
    _hasUppercase,
  ),
  PasswordRule(
    '1 caractère spécial minimum',
    'Le mot de passe doit contenir au moins un caractère spécial',
    _hasSpecial,
  ),
];

String? validatePassword(String? value) {
  final v = value ?? '';
  for (final rule in passwordRules) {
    if (!rule.test(v)) return rule.error;
  }
  return null;
}

String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Saisissez votre email';
  if (!_email.hasMatch(v)) return 'Adresse email invalide';
  return null;
}

String? validateConfirm(String? password, String? confirm) {
  if (password != confirm) return 'Les mots de passe ne correspondent pas';
  return null;
}
```

- [ ] **Step 3: Vérifier**

Run: `flutter test test/core/validators_test.dart`
Expected: PASS (toutes les assertions).

- [ ] **Step 4: Commit**

```bash
git add lib/core/validators.dart test/core/validators_test.dart
git commit -m "feat: validateurs email et mot de passe" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Service de code de vérification et helpers de test

**Files:**
- Create: `lib/auth/verification_code_service.dart`, `test/helpers.dart`
- Test: `test/auth/verification_code_service_test.dart`

**Interfaces:**
- Produces:
  - `class VerificationCodeService { VerificationCodeService(SharedPreferences prefs, {Random? random}); String issueCode(String uid); String? pendingCode(String uid); bool isVerified(String uid); bool verify(String uid, String input); }`
  - `test/helpers.dart` : `Future<SharedPreferences> mockPrefs([Map<String, Object> values])`, `void useTallScreen(WidgetTester tester)` (fenêtre 480×2400, ratio 1, remise à zéro en fin de test).

- [ ] **Step 1: Écrire les helpers**

Create `test/helpers.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> mockPrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
```

- [ ] **Step 2: Écrire les tests qui échouent**

Create `test/auth/verification_code_service_test.dart`:
```dart
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
```
Run: `flutter test test/auth/verification_code_service_test.dart`
Expected: FAIL (fichier manquant).

- [ ] **Step 3: Implémenter**

Create `lib/auth/verification_code_service.dart`:
```dart
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
```

- [ ] **Step 4: Vérifier**

Run: `flutter test test/auth/verification_code_service_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/auth/verification_code_service.dart test/helpers.dart test/auth/verification_code_service_test.dart
git commit -m "feat: service de code de vérification simulé" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 4: AuthRepository (mock + Firebase) et AuthController

**Files:**
- Create: `lib/auth/auth_repository.dart`, `lib/auth/mock_auth_repository.dart`, `lib/auth/firebase_auth_repository.dart`, `lib/auth/auth_controller.dart`
- Test: `test/auth/mock_auth_repository_test.dart`, `test/auth/firebase_auth_message_test.dart`, `test/auth/auth_controller_test.dart`

**Interfaces:**
- Consumes: `VerificationCodeService` (Task 3), `mockPrefs` (Task 3).
- Produces:
  - `class AuthUser { const AuthUser({required this.uid, required this.email}); final String uid; final String email; }`
  - `class AuthException implements Exception { const AuthException(this.message); final String message; }`
  - `abstract class AuthRepository { AuthUser? get currentUser; Future<AuthUser> signUp({required String email, required String password}); Future<AuthUser> signIn({required String email, required String password}); Future<void> signOut(); }`
  - `class MockAuthRepository implements AuthRepository` (constructeur sans argument)
  - `class FirebaseAuthRepository implements AuthRepository` (`FirebaseAuthRepository([FirebaseAuth? auth])`), `String authErrorMessage(String code)`
  - `class AuthController extends ChangeNotifier { AuthController({required AuthRepository repository, required VerificationCodeService codes}); AuthUser? get user; bool get isSignedIn; bool get isVerified; String? get demoCode; Future<void> signUp(String email, String password); Future<void> signIn(String email, String password); bool verifyCode(String input); void resendCode(); Future<void> signOut(); }`
- Messages d'erreur exacts : `Un compte existe déjà avec cet email`, `Email ou mot de passe incorrect`.

- [ ] **Step 1: Écrire l'interface**

Create `lib/auth/auth_repository.dart`:
```dart
class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthUser> signUp({required String email, required String password});

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> signOut();
}
```

- [ ] **Step 2: Écrire les tests du mock et du mapping Firebase (échouent)**

Create `test/auth/mock_auth_repository_test.dart`:
```dart
import 'package:autoscope/auth/auth_repository.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signUp crée un compte et connecte l\'utilisateur', () async {
    final repo = MockAuthRepository();
    final user = await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    expect(user.email, 'a@b.fr');
    expect(repo.currentUser?.uid, user.uid);
  });

  test('l\'email est normalisé (espaces et casse)', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: ' User@Mail.COM ', password: 'Abcdef1!');
    await repo.signOut();
    final user = await repo.signIn(email: 'user@mail.com', password: 'Abcdef1!');
    expect(user.email, 'user@mail.com');
  });

  test('signUp en double lève une AuthException', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    expect(
      () => repo.signUp(email: 'A@B.fr', password: 'Autre1234!'),
      throwsA(isA<AuthException>().having(
        (e) => e.message,
        'message',
        'Un compte existe déjà avec cet email',
      )),
    );
  });

  test('signIn refuse un mauvais mot de passe et un compte inconnu', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    await repo.signOut();
    for (final attempt in [
      ('a@b.fr', 'Mauvais1!'),
      ('inconnu@b.fr', 'Abcdef1!'),
    ]) {
      expect(
        () => repo.signIn(email: attempt.$1, password: attempt.$2),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Email ou mot de passe incorrect',
        )),
      );
    }
    expect(repo.currentUser, isNull);
  });

  test('signOut efface l\'utilisateur courant', () async {
    final repo = MockAuthRepository();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    await repo.signOut();
    expect(repo.currentUser, isNull);
  });
}
```

Create `test/auth/firebase_auth_message_test.dart`:
```dart
import 'package:autoscope/auth/firebase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authErrorMessage traduit les codes Firebase courants', () {
    expect(authErrorMessage('email-already-in-use'),
        'Un compte existe déjà avec cet email');
    expect(authErrorMessage('invalid-email'), 'Adresse email invalide');
    expect(authErrorMessage('weak-password'), 'Mot de passe trop faible');
    for (final code in ['user-not-found', 'wrong-password', 'invalid-credential']) {
      expect(authErrorMessage(code), 'Email ou mot de passe incorrect');
    }
    expect(authErrorMessage('network-request-failed'),
        'Connexion réseau indisponible');
    expect(authErrorMessage('too-many-requests'),
        'Trop de tentatives, réessayez plus tard');
  });

  test('authErrorMessage a un repli pour un code inconnu', () {
    expect(authErrorMessage('quelque-chose'),
        'Une erreur est survenue (quelque-chose)');
  });
}
```
Run: `flutter test test/auth`
Expected: FAIL (implémentations manquantes).

- [ ] **Step 3: Implémenter mock et Firebase**

Create `lib/auth/mock_auth_repository.dart`:
```dart
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
```

Create `lib/auth/firebase_auth_repository.dart`:
```dart
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
```
Run: `flutter test test/auth/mock_auth_repository_test.dart test/auth/firebase_auth_message_test.dart`
Expected: PASS.

- [ ] **Step 4: Écrire les tests de AuthController (échouent)**

Create `test/auth/auth_controller_test.dart`:
```dart
import 'package:autoscope/auth/auth_controller.dart';
import 'package:autoscope/auth/auth_repository.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:autoscope/auth/verification_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<(AuthController, MockAuthRepository, VerificationCodeService)>
    _setup() async {
  final repo = MockAuthRepository();
  final codes = VerificationCodeService(await mockPrefs());
  return (AuthController(repository: repo, codes: codes), repo, codes);
}

void main() {
  test('état initial : non connecté', () async {
    final (auth, _, _) = await _setup();
    expect(auth.isSignedIn, isFalse);
    expect(auth.isVerified, isFalse);
    expect(auth.demoCode, isNull);
  });

  test('signUp connecte, émet un code et reste non vérifié', () async {
    final (auth, _, _) = await _setup();
    var notified = 0;
    auth.addListener(() => notified++);
    await auth.signUp('a@b.fr', 'Abcdef1!');
    expect(auth.isSignedIn, isTrue);
    expect(auth.isVerified, isFalse);
    expect(auth.demoCode, matches(RegExp(r'^\d{6}$')));
    expect(notified, 1);
  });

  test('verifyCode valide le bon code puis isVerified passe à true', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    expect(auth.verifyCode('000000x'), isFalse);
    expect(auth.isVerified, isFalse);
    expect(auth.verifyCode(auth.demoCode!), isTrue);
    expect(auth.isVerified, isTrue);
  });

  test('signIn d\'un compte non vérifié sans code en attente en émet un', () async {
    final (auth, repo, codes) = await _setup();
    await repo.signUp(email: 'a@b.fr', password: 'Abcdef1!');
    await repo.signOut();
    await auth.signIn('a@b.fr', 'Abcdef1!');
    expect(auth.isVerified, isFalse);
    expect(codes.pendingCode(auth.user!.uid), isNotNull);
  });

  test('signIn d\'un compte déjà vérifié reste vérifié', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.verifyCode(auth.demoCode!);
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    await auth.signIn('a@b.fr', 'Abcdef1!');
    expect(auth.isVerified, isTrue);
  });

  test('un mauvais mot de passe propage l\'AuthException', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    await auth.signOut();
    expect(() => auth.signIn('a@b.fr', 'Nope1234!'),
        throwsA(isA<AuthException>()));
    expect(auth.isSignedIn, isFalse);
  });

  test('resendCode émet un nouveau code valide', () async {
    final (auth, _, _) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.resendCode();
    expect(auth.verifyCode(auth.demoCode!), isTrue);
  });

  test('un nouveau contrôleur reprend la session du dépôt (rechargement)', () async {
    final (auth, repo, codes) = await _setup();
    await auth.signUp('a@b.fr', 'Abcdef1!');
    auth.verifyCode(auth.demoCode!);
    final reloaded = AuthController(repository: repo, codes: codes);
    expect(reloaded.isSignedIn, isTrue);
    expect(reloaded.isVerified, isTrue);
  });
}
```
Run: `flutter test test/auth/auth_controller_test.dart`
Expected: FAIL (`auth_controller.dart` manquant).

- [ ] **Step 5: Implémenter AuthController**

Create `lib/auth/auth_controller.dart`:
```dart
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
```

- [ ] **Step 6: Vérifier**

Run: `flutter test test/auth && flutter analyze --no-fatal-infos`
Expected: tous les tests PASS ; pas d'erreur d'analyse.

- [ ] **Step 7: Commit**

```bash
git add lib/auth test/auth
git commit -m "feat: dépôts d'auth (mock, Firebase) et AuthController" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Pages Connexion, Inscription et Vérification du code

**Files:**
- Create: `lib/auth/login_page.dart`, `lib/auth/signup_page.dart`, `lib/auth/verify_code_page.dart`
- Test: `test/auth/auth_pages_test.dart`

**Interfaces:**
- Consumes: `AuthController`, `AuthException`, `MockAuthRepository`, `VerificationCodeService`, validateurs, `AppLogo`, `mockPrefs`, `useTallScreen`.
- Produces (clés de widgets exactes, utilisées par la Task 8) :
  - LoginPage : `email-field`, `password-field`, `login-button`, `signup-link`
  - SignupPage : `signup-email-field`, `signup-password-field`, `signup-confirm-field`, `signup-button`, `login-link`
  - VerifyCodePage : `demo-code-value` (Text contenant uniquement les 6 chiffres), `code-field`, `verify-button`, `resend-button`, `logout-button`
- Navigation : `context.go('/signup')`, `context.go('/login')` ; après succès, c'est la redirection du routeur (Task 8) qui change de page.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/auth/auth_pages_test.dart`:
```dart
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
```
Run: `flutter test test/auth/auth_pages_test.dart`
Expected: FAIL (pages manquantes).

- [ ] **Step 2: Implémenter LoginPage**

Create `lib/auth/login_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_logo.dart';
import '../core/validators.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.signIn(_email.text, _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo()),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('email-field'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('password-field'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Saisissez votre mot de passe'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login-button'),
                    onPressed: _loading ? null : _submit,
                    child: const Text('Me connecter'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('signup-link'),
                    onPressed: () => context.go('/signup'),
                    child: const Text('Je n\'ai pas de compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Implémenter SignupPage**

Create `lib/auth/signup_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_logo.dart';
import '../core/validators.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.signUp(_email.text, _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        title: const Text('Créer un compte'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(size: 56)),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('signup-email-field'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup-password-field'),
                    controller: _password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: _password,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final rule in passwordRules)
                          _RuleRow(
                            label: rule.label,
                            ok: rule.test(_password.text),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('signup-confirm-field'),
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe'),
                    validator: (v) => validateConfirm(_password.text, v),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('signup-button'),
                    onPressed: _loading ? null : _submit,
                    child: const Text('Créer mon compte'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('login-link'),
                    onPressed: () => context.go('/login'),
                    child: const Text('J\'ai déjà un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: ok ? Colors.green : Theme.of(context).disabledColor,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implémenter VerifyCodePage**

Create `lib/auth/verify_code_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_logo.dart';
import 'auth_controller.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = context.read<AuthController>().verifyCode(_code.text);
    if (!ok) setState(() => _error = 'Code incorrect');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final code = auth.demoCode;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 56)),
                const SizedBox(height: 24),
                Text(
                  'Vérifiez votre adresse email',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Saisissez le code à 6 chiffres associé à ${auth.user?.email ?? ''}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (code != null)
                  Card(
                    color: scheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'Mode démo : aucun email n\'est envoyé et ce code '
                            'n\'est pas sécurisé. Votre code est :',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code,
                            key: const Key('demo-code-value'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(letterSpacing: 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('code-field'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Code à 6 chiffres',
                    errorText: _error,
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('verify-button'),
                  onPressed: _submit,
                  child: const Text('Valider le code'),
                ),
                TextButton(
                  key: const Key('resend-button'),
                  onPressed: () {
                    context.read<AuthController>().resendCode();
                    setState(() => _error = null);
                  },
                  child: const Text('Renvoyer un code'),
                ),
                TextButton(
                  key: const Key('logout-button'),
                  onPressed: () => context.read<AuthController>().signOut(),
                  child: const Text('Me déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/auth && flutter analyze --no-fatal-infos`
Expected: tous les tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/auth test/auth
git commit -m "feat: pages connexion, inscription et vérification du code" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 6: OnBoarding (modèle de recherche, logos de marques, formulaire)

**Files:**
- Create: `lib/onboarding/search_criteria.dart`, `lib/onboarding/brand_button.dart`, `lib/onboarding/crit_air_section.dart`, `lib/onboarding/onboarding_page.dart`, `assets/brands/peugeot.svg`, `assets/brands/renault.svg`, `assets/brands/audi.svg`, `assets/brands/bmw.svg`
- Modify: `pubspec.yaml` (déclaration des assets)
- Test: `test/onboarding/search_criteria_test.dart`, `test/onboarding/onboarding_page_test.dart`

**Interfaces:**
- Consumes: `AppLogo`, `AuthController.signOut()` (bouton de déconnexion), `go_router`.
- Produces:
  - `enum SearchMode { buy, rent }` (`label` : `Acheter`, `Louer`), `enum Fuel { essence, diesel, hybride, electrique }` (`label` : `Essence`, `Diesel`, `Hybride`, `Électrique`), `enum Brand { peugeot, renault, audi, bmw }` (`label`, `asset`), `const List<String> kCities`, `const double kMinPower = 60`, `const double kMaxPower = 1000`.
  - `class SearchCriteria extends ChangeNotifier` : getters `mode`, `aroundMe`, `city` (String?), `fuels` (Set<Fuel>), `power` (RangeValues), `brands` (Set<Brand>), `critAir` (bool) ; méthodes `setMode(SearchMode)`, `setAroundMe(bool)`, `setCity(String)`, `toggleFuel(Fuel)`, `setPower(RangeValues)`, `toggleBrand(Brand)`, `setCritAir(bool)`, `reset()`. Défauts : `buy`, `aroundMe=true`, `city=null`, aucune motorisation ni marque, `power=RangeValues(60,1000)`, `critAir=false`.
  - `OnboardingPage` (const) ; clés : `location-around`, `location-city`, `city-dropdown`, `fuel-<name>`, `power-label`, `brand-<name>`, `critair-checkbox`, `critair-text`, `validate-button`, `onboarding-logout`. « Valider » appelle `context.go('/feed')`.

- [ ] **Step 1: Créer les logos SVG (illustrations)**

Create `assets/brands/audi.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 32">
  <g fill="none" stroke="#1a1a1a" stroke-width="3">
    <circle cx="14" cy="16" r="10"/>
    <circle cx="26" cy="16" r="10"/>
    <circle cx="38" cy="16" r="10"/>
    <circle cx="50" cy="16" r="10"/>
  </g>
</svg>
```

Create `assets/brands/bmw.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <circle cx="32" cy="32" r="30" fill="#1a1a1a"/>
  <circle cx="32" cy="32" r="24" fill="#ffffff"/>
  <path d="M32 8 A24 24 0 0 1 56 32 L32 32 Z" fill="#1c69d4"/>
  <path d="M32 56 A24 24 0 0 1 8 32 L32 32 Z" fill="#1c69d4"/>
</svg>
```

Create `assets/brands/renault.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <path d="M32 4 L52 32 L32 60 L12 32 Z" fill="#ffcc00" stroke="#1a1a1a" stroke-width="3" stroke-linejoin="round"/>
  <path d="M32 18 L42 32 L32 46 L22 32 Z" fill="#1a1a1a"/>
</svg>
```

Create `assets/brands/peugeot.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <path d="M10 6 H54 V30 C54 46 44 56 32 60 C20 56 10 46 10 30 Z" fill="#1d3f8f"/>
  <path d="M24 22 L32 14 L40 22 L36 30 L40 42 L32 48 L24 42 L28 30 Z" fill="#dfe6f7"/>
</svg>
```

Modify `pubspec.yaml` : dans la section `flutter:` (après `uses-material-design: true`), ajouter :
```yaml
  assets:
    - assets/brands/
```

- [ ] **Step 2: Écrire les tests du modèle (échouent)**

Create `test/onboarding/search_criteria_test.dart`:
```dart
import 'package:autoscope/onboarding/search_criteria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valeurs par défaut', () {
    final c = SearchCriteria();
    expect(c.mode, SearchMode.buy);
    expect(c.aroundMe, isTrue);
    expect(c.city, isNull);
    expect(c.fuels, isEmpty);
    expect(c.brands, isEmpty);
    expect(c.power, const RangeValues(60, 1000));
    expect(c.critAir, isFalse);
  });

  test('choisir « Sélectionner une ville » sélectionne une ville par défaut', () {
    final c = SearchCriteria()..setAroundMe(false);
    expect(c.aroundMe, isFalse);
    expect(c.city, kCities.first);
    c.setCity('Lyon');
    expect(c.city, 'Lyon');
    c.setAroundMe(true);
    c.setAroundMe(false);
    expect(c.city, 'Lyon');
  });

  test('toggleBrand et toggleFuel : deux appels annulent la sélection', () {
    final c = SearchCriteria();
    c.toggleBrand(Brand.audi);
    expect(c.brands, {Brand.audi});
    c.toggleBrand(Brand.audi);
    expect(c.brands, isEmpty);
    c.toggleFuel(Fuel.hybride);
    c.toggleFuel(Fuel.electrique);
    expect(c.fuels, {Fuel.hybride, Fuel.electrique});
    c.toggleFuel(Fuel.hybride);
    expect(c.fuels, {Fuel.electrique});
  });

  test('setPower borne dans 60..1000 et réordonne un intervalle inversé', () {
    final c = SearchCriteria();
    c.setPower(const RangeValues(0, 5000));
    expect(c.power, const RangeValues(60, 1000));
    c.setPower(const RangeValues(500, 300));
    expect(c.power, const RangeValues(300, 500));
  });

  test('reset restaure les valeurs par défaut et notifie', () {
    final c = SearchCriteria()
      ..setMode(SearchMode.rent)
      ..toggleBrand(Brand.bmw)
      ..setCritAir(true)
      ..setPower(const RangeValues(100, 200));
    var notified = 0;
    c.addListener(() => notified++);
    c.reset();
    expect(c.mode, SearchMode.buy);
    expect(c.brands, isEmpty);
    expect(c.critAir, isFalse);
    expect(c.power, const RangeValues(60, 1000));
    expect(notified, 1);
  });

  test('les ensembles exposés ne sont pas modifiables de l\'extérieur', () {
    final c = SearchCriteria();
    expect(() => c.brands.add(Brand.audi), throwsUnsupportedError);
    expect(() => c.fuels.add(Fuel.diesel), throwsUnsupportedError);
  });
}
```
Run: `flutter test test/onboarding/search_criteria_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implémenter le modèle**

Create `lib/onboarding/search_criteria.dart`:
```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

const double kMinPower = 60;
const double kMaxPower = 1000;
const List<String> kCities = [
  'Paris',
  'Lyon',
  'Marseille',
  'Lille',
  'Toulouse',
  'Bordeaux',
];

enum SearchMode {
  buy('Acheter'),
  rent('Louer');

  const SearchMode(this.label);
  final String label;
}

enum Fuel {
  essence('Essence'),
  diesel('Diesel'),
  hybride('Hybride'),
  electrique('Électrique');

  const Fuel(this.label);
  final String label;
}

enum Brand {
  peugeot('Peugeot', 'assets/brands/peugeot.svg'),
  renault('Renault', 'assets/brands/renault.svg'),
  audi('Audi', 'assets/brands/audi.svg'),
  bmw('BMW', 'assets/brands/bmw.svg');

  const Brand(this.label, this.asset);
  final String label;
  final String asset;
}

class SearchCriteria extends ChangeNotifier {
  SearchMode _mode = SearchMode.buy;
  bool _aroundMe = true;
  String? _city;
  final Set<Fuel> _fuels = {};
  RangeValues _power = const RangeValues(kMinPower, kMaxPower);
  final Set<Brand> _brands = {};
  bool _critAir = false;

  SearchMode get mode => _mode;
  bool get aroundMe => _aroundMe;
  String? get city => _city;
  Set<Fuel> get fuels => Set.unmodifiable(_fuels);
  RangeValues get power => _power;
  Set<Brand> get brands => Set.unmodifiable(_brands);
  bool get critAir => _critAir;

  void setMode(SearchMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setAroundMe(bool value) {
    _aroundMe = value;
    if (!value) _city ??= kCities.first;
    notifyListeners();
  }

  void setCity(String city) {
    _city = city;
    notifyListeners();
  }

  void toggleFuel(Fuel fuel) {
    if (!_fuels.remove(fuel)) _fuels.add(fuel);
    notifyListeners();
  }

  void setPower(RangeValues values) {
    final a = values.start.clamp(kMinPower, kMaxPower).toDouble();
    final b = values.end.clamp(kMinPower, kMaxPower).toDouble();
    _power = RangeValues(math.min(a, b), math.max(a, b));
    notifyListeners();
  }

  void toggleBrand(Brand brand) {
    if (!_brands.remove(brand)) _brands.add(brand);
    notifyListeners();
  }

  void setCritAir(bool value) {
    _critAir = value;
    notifyListeners();
  }

  void reset() {
    _mode = SearchMode.buy;
    _aroundMe = true;
    _city = null;
    _fuels.clear();
    _power = const RangeValues(kMinPower, kMaxPower);
    _brands.clear();
    _critAir = false;
    notifyListeners();
  }
}
```
Run: `flutter test test/onboarding/search_criteria_test.dart`
Expected: PASS.

- [ ] **Step 4: Écrire les tests de la page (échouent)**

Create `test/onboarding/onboarding_page_test.dart`:
```dart
import 'package:autoscope/auth/auth_controller.dart';
import 'package:autoscope/auth/mock_auth_repository.dart';
import 'package:autoscope/auth/verification_code_service.dart';
import 'package:autoscope/onboarding/onboarding_page.dart';
import 'package:autoscope/onboarding/search_criteria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

Future<SearchCriteria> _pump(WidgetTester tester) async {
  useTallScreen(tester);
  final criteria = SearchCriteria();
  final auth = AuthController(
    repository: MockAuthRepository(),
    codes: VerificationCodeService(await mockPrefs()),
  );
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/feed', builder: (_, __) => const Text('PAGE FEED')),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchCriteria>.value(value: criteria),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return criteria;
}

void main() {
  testWidgets('affiche logo et toutes les sections du formulaire', (tester) async {
    await _pump(tester);
    expect(find.text('Autoscope'), findsOneWidget);
    expect(find.text('Je cherche une voiture à'), findsOneWidget);
    expect(find.text('Acheter'), findsOneWidget);
    expect(find.text('Louer'), findsOneWidget);
    expect(find.text('Autour de moi'), findsOneWidget);
    expect(find.text('Sélectionner une ville'), findsOneWidget);
    for (final label in ['Essence', 'Diesel', 'Hybride', 'Électrique']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const Key('power-label')), findsOneWidget);
    expect(find.text('60 – 1000 ch'), findsOneWidget);
    for (final b in ['peugeot', 'renault', 'audi', 'bmw']) {
      expect(find.byKey(Key('brand-$b')), findsOneWidget);
    }
    expect(find.byKey(const Key('critair-checkbox')), findsOneWidget);
  });

  testWidgets('Acheter / Louer met à jour le critère', (tester) async {
    final criteria = await _pump(tester);
    await tester.tap(find.text('Louer'));
    await tester.pumpAndSettle();
    expect(criteria.mode, SearchMode.rent);
  });

  testWidgets('la liste de villes n\'apparaît qu\'avec « Sélectionner une ville »', (tester) async {
    final criteria = await _pump(tester);
    expect(find.byKey(const Key('city-dropdown')), findsNothing);
    await tester.tap(find.byKey(const Key('location-city')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('city-dropdown')), findsOneWidget);
    expect(criteria.city, 'Paris');
    await tester.tap(find.byKey(const Key('city-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lyon').last);
    await tester.pumpAndSettle();
    expect(criteria.city, 'Lyon');
    await tester.tap(find.byKey(const Key('location-around')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('city-dropdown')), findsNothing);
  });

  testWidgets('les motorisations sont sélectionnables', (tester) async {
    final criteria = await _pump(tester);
    await tester.tap(find.byKey(const Key('fuel-hybride')));
    await tester.tap(find.byKey(const Key('fuel-electrique')));
    await tester.pumpAndSettle();
    expect(criteria.fuels, {Fuel.hybride, Fuel.electrique});
  });

  testWidgets('une marque cliquée est sélectionnée puis désélectionnée', (tester) async {
    final criteria = await _pump(tester);
    Finder filled() => find.descendant(
        of: find.byKey(const Key('brand-audi')),
        matching: find.byType(FilledButton));
    expect(filled(), findsNothing);
    await tester.tap(find.byKey(const Key('brand-audi')));
    await tester.pumpAndSettle();
    expect(criteria.brands, {Brand.audi});
    expect(filled(), findsOneWidget);
    await tester.tap(find.byKey(const Key('brand-audi')));
    await tester.pumpAndSettle();
    expect(criteria.brands, isEmpty);
  });

  testWidgets('le bouton de marque affiche le logo à gauche du libellé', (tester) async {
    await _pump(tester);
    final logo = find.descendant(
        of: find.byKey(const Key('brand-bmw')),
        matching: find.byType(SvgPicture));
    final label = find.descendant(
        of: find.byKey(const Key('brand-bmw')), matching: find.text('BMW'));
    expect(logo, findsOneWidget);
    expect(tester.getCenter(logo).dx, lessThan(tester.getCenter(label).dx));
  });

  testWidgets('le curseur de puissance affiche l\'intervalle choisi', (tester) async {
    final criteria = await _pump(tester);
    tester.widget<RangeSlider>(find.byType(RangeSlider))
        .onChanged!(const RangeValues(100, 250));
    await tester.pumpAndSettle();
    expect(criteria.power, const RangeValues(100, 250));
    expect(find.text('100 – 250 ch'), findsOneWidget);
  });

  testWidgets('la case Crit\'Air affiche puis masque le texte', (tester) async {
    final criteria = await _pump(tester);
    expect(find.byKey(const Key('critair-text')), findsNothing);
    await tester.tap(find.byKey(const Key('critair-checkbox')));
    await tester.pumpAndSettle();
    expect(criteria.critAir, isTrue);
    expect(find.byKey(const Key('critair-text')), findsOneWidget);
    await tester.tap(find.byKey(const Key('critair-checkbox')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critair-text')), findsNothing);
  });

  testWidgets('Valider ouvre le Feed sans autre effet', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('validate-button')));
    await tester.pumpAndSettle();
    expect(find.text('PAGE FEED'), findsOneWidget);
  });
}
```
Run: `flutter test test/onboarding/onboarding_page_test.dart`
Expected: FAIL (pages manquantes).

- [ ] **Step 5: Implémenter BrandButton et CritAirSection**

Create `lib/onboarding/brand_button.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'search_criteria.dart';

class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.brand,
    required this.selected,
    required this.onPressed,
  });

  final Brand brand;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(brand.asset, width: 28, height: 28);
    final label = Text(brand.label);
    const alignment = Alignment.centerLeft;
    return selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: FilledButton.styleFrom(alignment: alignment),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: OutlinedButton.styleFrom(alignment: alignment),
          );
  }
}
```

Create `lib/onboarding/crit_air_section.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'search_criteria.dart';

class CritAirSection extends StatelessWidget {
  const CritAirSection({super.key});

  @override
  Widget build(BuildContext context) {
    final criteria = context.watch<SearchCriteria>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          key: const Key('critair-checkbox'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Vignette Crit\'Air'),
          subtitle: const Text(
            'De quelle vignette ai-je besoin pour circuler dans ma ville ?',
          ),
          value: criteria.critAir,
          onChanged: (v) => criteria.setCritAir(v ?? false),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: criteria.critAir
              ? Card(
                  key: const Key('critair-text'),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'La vignette Crit\'Air classe les véhicules de 0 '
                      '(électrique et hydrogène) à 5 selon leurs émissions. '
                      'Selon votre ville, certaines zones à faibles émissions '
                      'peuvent limiter l\'accès aux véhicules les plus '
                      'polluants. (Texte de démonstration.)',
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Implémenter OnboardingPage**

Create `lib/onboarding/onboarding_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../core/app_logo.dart';
import 'brand_button.dart';
import 'crit_air_section.dart';
import 'search_criteria.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final criteria = context.watch<SearchCriteria>();
    final power = criteria.power;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('onboarding-logout'),
            tooltip: 'Me déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const Center(child: AppLogo(size: 56)),
            const SizedBox(height: 24),
            const _SectionTitle('Je cherche une voiture à'),
            SegmentedButton<SearchMode>(
              segments: [
                for (final m in SearchMode.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {criteria.mode},
              onSelectionChanged: (s) => criteria.setMode(s.first),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Lieu'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('location-around'),
                  label: const Text('Autour de moi'),
                  selected: criteria.aroundMe,
                  onSelected: (_) => criteria.setAroundMe(true),
                ),
                ChoiceChip(
                  key: const Key('location-city'),
                  label: const Text('Sélectionner une ville'),
                  selected: !criteria.aroundMe,
                  onSelected: (_) => criteria.setAroundMe(false),
                ),
              ],
            ),
            if (!criteria.aroundMe) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Ville'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('city-dropdown'),
                    isExpanded: true,
                    value: criteria.city,
                    items: [
                      for (final c in kCities)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (c) {
                      if (c != null) criteria.setCity(c);
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _SectionTitle('Motorisation'),
            Wrap(
              spacing: 8,
              children: [
                for (final f in Fuel.values)
                  FilterChip(
                    key: Key('fuel-${f.name}'),
                    label: Text(f.label),
                    selected: criteria.fuels.contains(f),
                    onSelected: (_) => criteria.toggleFuel(f),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Nombre de chevaux'),
            Text(
              '${power.start.round()} – ${power.end.round()} ch',
              key: const Key('power-label'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RangeSlider(
              values: power,
              min: kMinPower,
              max: kMaxPower,
              divisions: 94,
              labels: RangeLabels(
                '${power.start.round()} ch',
                '${power.end.round()} ch',
              ),
              onChanged: criteria.setPower,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Marque'),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final b in Brand.values)
                      SizedBox(
                        width: width,
                        child: BrandButton(
                          key: Key('brand-${b.name}'),
                          brand: b,
                          selected: criteria.brands.contains(b),
                          onPressed: () => criteria.toggleBrand(b),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const CritAirSection(),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('validate-button'),
              onPressed: () => context.go('/feed'),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
```

- [ ] **Step 7: Vérifier**

Run: `flutter test test/onboarding && flutter analyze --no-fatal-infos`
Expected: tous les tests PASS. Si `find.text('Louer')` est ambigu avec un autre widget, le test échoue : corriger le code, pas le test.

- [ ] **Step 8: Commit**

```bash
git add assets lib/onboarding test/onboarding pubspec.yaml
git commit -m "feat: page OnBoarding avec formulaire de recherche" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Feed (véhicule, carousel de 3 visuels)

**Files:**
- Create: `lib/feed/vehicle.dart`, `lib/feed/photo_carousel.dart`, `lib/feed/feed_page.dart`, `assets/photos/car_1.svg`, `assets/photos/car_2.svg`, `assets/photos/car_3.svg`
- Modify: `pubspec.yaml` (déclaration des assets)
- Test: `test/feed/vehicle_test.dart`, `test/feed/feed_page_test.dart`

**Interfaces:**
- Consumes: `SearchCriteria.reset()` (Task 6), `go_router`.
- Produces:
  - `String formatNumber(int n)` (séparateur de milliers : espace), `class Vehicle` avec `title, version, price, mileage, year, fuel, power, critAir, city, description, photos`, constante `Vehicle.demo` (3 photos).
  - `PhotoCarousel({required List<String> photos})` ; clés des points : `dot-<i>` / `dot-<i>-active`.
  - `FeedPage` (const) ; clés : `filter-button` (→ `/onboarding`, critères conservés), `contact-button` (sans action), `home-button` (réinitialise les critères puis `/onboarding`).

- [ ] **Step 1: Créer les 3 visuels (illustrations SVG)**

Create `assets/photos/car_1.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 250">
  <rect width="400" height="250" fill="#dce6ff"/>
  <rect y="190" width="400" height="60" fill="#b8c4e0"/>
  <path d="M60 170 L90 120 Q100 105 125 103 L270 103 Q295 105 310 125 L345 150 Q360 158 360 172 L360 185 L40 185 L40 172 Q40 170 60 170Z" fill="#1b4dff"/>
  <path d="M110 120 L135 110 L190 110 L190 150 L95 150Z" fill="#eaf1ff"/>
  <path d="M200 110 L265 110 L295 135 L295 150 L200 150Z" fill="#eaf1ff"/>
  <circle cx="115" cy="188" r="26" fill="#1c1c28"/><circle cx="115" cy="188" r="12" fill="#c9d1e6"/>
  <circle cx="295" cy="188" r="26" fill="#1c1c28"/><circle cx="295" cy="188" r="12" fill="#c9d1e6"/>
</svg>
```

Create `assets/photos/car_2.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 250">
  <rect width="400" height="250" fill="#ffe8d6"/>
  <rect y="190" width="400" height="60" fill="#e3c9b3"/>
  <circle cx="330" cy="60" r="28" fill="#ffd166"/>
  <path d="M60 170 L90 120 Q100 105 125 103 L270 103 Q295 105 310 125 L345 150 Q360 158 360 172 L360 185 L40 185 L40 172 Q40 170 60 170Z" fill="#d62839"/>
  <path d="M110 120 L135 110 L190 110 L190 150 L95 150Z" fill="#fff4ea"/>
  <path d="M200 110 L265 110 L295 135 L295 150 L200 150Z" fill="#fff4ea"/>
  <circle cx="115" cy="188" r="26" fill="#1c1c28"/><circle cx="115" cy="188" r="12" fill="#d9d2c9"/>
  <circle cx="295" cy="188" r="26" fill="#1c1c28"/><circle cx="295" cy="188" r="12" fill="#d9d2c9"/>
</svg>
```

Create `assets/photos/car_3.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 250">
  <rect width="400" height="250" fill="#d8f3dc"/>
  <rect y="190" width="400" height="60" fill="#a9cdb0"/>
  <path d="M20 190 L70 120 L110 190Z" fill="#95d5b2"/>
  <path d="M300 190 L350 110 L400 190Z" fill="#95d5b2"/>
  <path d="M60 170 L90 120 Q100 105 125 103 L270 103 Q295 105 310 125 L345 150 Q360 158 360 172 L360 185 L40 185 L40 172 Q40 170 60 170Z" fill="#343a40"/>
  <path d="M110 120 L135 110 L190 110 L190 150 L95 150Z" fill="#e9f5ec"/>
  <path d="M200 110 L265 110 L295 135 L295 150 L200 150Z" fill="#e9f5ec"/>
  <circle cx="115" cy="188" r="26" fill="#111"/><circle cx="115" cy="188" r="12" fill="#ced4da"/>
  <circle cx="295" cy="188" r="26" fill="#111"/><circle cx="295" cy="188" r="12" fill="#ced4da"/>
</svg>
```

Modify `pubspec.yaml` : la liste `assets:` devient
```yaml
  assets:
    - assets/brands/
    - assets/photos/
```

- [ ] **Step 2: Écrire les tests (échouent)**

Create `test/feed/vehicle_test.dart`:
```dart
import 'package:autoscope/feed/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatNumber insère un espace comme séparateur de milliers', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(999), '999');
    expect(formatNumber(1000), '1 000');
    expect(formatNumber(32900), '32 900');
    expect(formatNumber(1234567), '1 234 567');
  });

  test('le véhicule de démo a 3 photos et une description', () {
    expect(Vehicle.demo.photos, hasLength(3));
    expect(Vehicle.demo.description, isNotEmpty);
  });
}
```

Create `test/feed/feed_page_test.dart`:
```dart
import 'package:autoscope/feed/feed_page.dart';
import 'package:autoscope/feed/photo_carousel.dart';
import 'package:autoscope/feed/vehicle.dart';
import 'package:autoscope/onboarding/search_criteria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

Future<SearchCriteria> _pump(WidgetTester tester) async {
  useTallScreen(tester);
  final criteria = SearchCriteria()..toggleBrand(Brand.audi);
  final router = GoRouter(
    initialLocation: '/feed',
    routes: [
      GoRoute(path: '/feed', builder: (_, __) => const FeedPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const Text('PAGE ONBOARDING')),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<SearchCriteria>.value(
      value: criteria,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return criteria;
}

void main() {
  testWidgets('affiche le récapitulatif du véhicule', (tester) async {
    await _pump(tester);
    expect(find.text(Vehicle.demo.title), findsOneWidget);
    expect(find.text('${formatNumber(Vehicle.demo.price)} €'), findsOneWidget);
    expect(find.text('${formatNumber(Vehicle.demo.mileage)} km'), findsOneWidget);
    expect(find.text(Vehicle.demo.description), findsOneWidget);
  });

  testWidgets('le carousel propose 3 visuels et change au balayage', (tester) async {
    await _pump(tester);
    expect(find.byType(PhotoCarousel), findsOneWidget);
    expect(find.byKey(const Key('dot-0-active')), findsOneWidget);
    expect(find.byKey(const Key('dot-1')), findsOneWidget);
    expect(find.byKey(const Key('dot-2')), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dot-1-active')), findsOneWidget);
    expect(find.byKey(const Key('dot-0')), findsOneWidget);
  });

  testWidgets('l\'icône filtre revient à l\'OnBoarding en conservant les critères', (tester) async {
    final criteria = await _pump(tester);
    await tester.tap(find.byKey(const Key('filter-button')));
    await tester.pumpAndSettle();
    expect(find.text('PAGE ONBOARDING'), findsOneWidget);
    expect(criteria.brands, {Brand.audi});
  });

  testWidgets('« Je souhaite être contacté » n\'a aucune action visible', (tester) async {
    await _pump(tester);
    expect(find.text('Je souhaite être contacté'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contact-button')));
    await tester.pumpAndSettle();
    expect(find.text('Je souhaite être contacté'), findsOneWidget);
    expect(find.text('PAGE ONBOARDING'), findsNothing);
  });

  testWidgets('« Retour à l\'accueil » réinitialise les critères et revient à l\'OnBoarding', (tester) async {
    final criteria = await _pump(tester);
    await tester.tap(find.byKey(const Key('home-button')));
    await tester.pumpAndSettle();
    expect(find.text('PAGE ONBOARDING'), findsOneWidget);
    expect(criteria.brands, isEmpty);
  });
}
```
Run: `flutter test test/feed`
Expected: FAIL.

- [ ] **Step 3: Implémenter Vehicle**

Create `lib/feed/vehicle.dart`:
```dart
String formatNumber(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

class Vehicle {
  const Vehicle({
    required this.title,
    required this.version,
    required this.price,
    required this.mileage,
    required this.year,
    required this.fuel,
    required this.power,
    required this.critAir,
    required this.city,
    required this.description,
    required this.photos,
  });

  final String title;
  final String version;
  final int price;
  final int mileage;
  final int year;
  final String fuel;
  final int power;
  final int critAir;
  final String city;
  final String description;
  final List<String> photos;

  static const Vehicle demo = Vehicle(
    title: 'Peugeot 308',
    version: 'GT Hybrid 225 e-EAT8',
    price: 32900,
    mileage: 18450,
    year: 2023,
    fuel: 'Hybride',
    power: 225,
    critAir: 1,
    city: 'Lyon',
    description:
        'Berline compacte hybride rechargeable en excellent état, première '
        'main, entretien suivi en concession. Équipée du i-Cockpit, '
        'd\'un toit panoramique et des aides à la conduite. Idéale pour la '
        'ville comme pour la route. (Annonce fictive de démonstration.)',
    photos: [
      'assets/photos/car_1.svg',
      'assets/photos/car_2.svg',
      'assets/photos/car_3.svg',
    ],
  );
}
```

- [ ] **Step 4: Implémenter PhotoCarousel et FeedPage**

Create `lib/feed/photo_carousel.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.photos});

  final List<String> photos;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) =>
                SvgPicture.asset(widget.photos[i], fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.photos.length; i++)
                AnimatedContainer(
                  key: Key(i == _index ? 'dot-$i-active' : 'dot-$i'),
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
```

Create `lib/feed/feed_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../onboarding/search_criteria.dart';
import 'photo_carousel.dart';
import 'vehicle.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    const vehicle = Vehicle.demo;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre sélection'),
        actions: [
          IconButton(
            key: const Key('filter-button'),
            tooltip: 'Modifier ma recherche',
            icon: const Icon(Icons.filter_list),
            onPressed: () => context.go('/onboarding'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PhotoCarousel(photos: Vehicle.demo.photos),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.title,
                            style: theme.textTheme.headlineSmall),
                        Text(vehicle.version,
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${formatNumber(vehicle.price)} €',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Spec(Icons.calendar_today, '${vehicle.year}'),
                            _Spec(Icons.speed,
                                '${formatNumber(vehicle.mileage)} km'),
                            _Spec(Icons.local_gas_station, vehicle.fuel),
                            _Spec(Icons.bolt, '${vehicle.power} ch'),
                            _Spec(Icons.eco, 'Crit\'Air ${vehicle.critAir}'),
                            _Spec(Icons.place, vehicle.city),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(vehicle.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('contact-button'),
              onPressed: () {},
              child: const Text('Je souhaite être contacté'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('home-button'),
              onPressed: () {
                context.read<SearchCriteria>().reset();
                context.go('/onboarding');
              },
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/feed && flutter analyze --no-fatal-infos`
Expected: tous les tests PASS.

- [ ] **Step 6: Commit**

```bash
git add assets lib/feed test/feed pubspec.yaml
git commit -m "feat: page Feed avec carousel et fiche véhicule" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Routeur, gardes d'accès et assemblage de l'application

**Files:**
- Create: `lib/router.dart`, `lib/app.dart`
- Modify: `lib/main.dart`
- Test: `test/app_flow_test.dart`

**Interfaces:**
- Consumes: toutes les pages (Tasks 5-7), `AuthController`, `SearchCriteria`, `MockAuthRepository`, `VerificationCodeService`, `buildTheme`, `mockPrefs`, `useTallScreen`.
- Produces: `GoRouter createRouter(AuthController auth, {String initialLocation = '/login'})` ; `AutoscopeApp({required AuthController auth, required SearchCriteria criteria, String initialLocation = '/login'})` ; routes `/login`, `/signup`, `/verify`, `/onboarding`, `/feed`.
- Règles de redirection : non connecté → seulement `/login` et `/signup` ; connecté non vérifié → seulement `/verify` ; connecté vérifié → `/login`, `/signup`, `/verify` redirigent vers `/onboarding`.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/app_flow_test.dart`:
```dart
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
```
Run: `flutter test test/app_flow_test.dart`
Expected: FAIL (`app.dart` manquant).

- [ ] **Step 2: Implémenter le routeur**

Create `lib/router.dart`:
```dart
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'auth/verify_code_page.dart';
import 'feed/feed_page.dart';
import 'onboarding/onboarding_page.dart';

const _publicRoutes = {'/login', '/signup'};

GoRouter createRouter(
  AuthController auth, {
  String initialLocation = '/login',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!auth.isSignedIn) {
        return _publicRoutes.contains(location) ? null : '/login';
      }
      if (!auth.isVerified) {
        return location == '/verify' ? null : '/verify';
      }
      if (_publicRoutes.contains(location) || location == '/verify') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/verify', builder: (_, __) => const VerifyCodePage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/feed', builder: (_, __) => const FeedPage()),
    ],
  );
}
```

- [ ] **Step 3: Implémenter l'application et main**

Create `lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'core/theme.dart';
import 'onboarding/search_criteria.dart';
import 'router.dart';

class AutoscopeApp extends StatefulWidget {
  const AutoscopeApp({
    super.key,
    required this.auth,
    required this.criteria,
    this.initialLocation = '/login',
  });

  final AuthController auth;
  final SearchCriteria criteria;
  final String initialLocation;

  @override
  State<AutoscopeApp> createState() => _AutoscopeAppState();
}

class _AutoscopeAppState extends State<AutoscopeApp> {
  late final GoRouter _router =
      createRouter(widget.auth, initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: widget.auth),
        ChangeNotifierProvider<SearchCriteria>.value(value: widget.criteria),
      ],
      child: MaterialApp.router(
        title: 'Autoscope',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
```

Replace `lib/main.dart`:
```dart
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
```

- [ ] **Step 4: Vérifier**

Run: `flutter test && flutter analyze --no-fatal-infos`
Expected: toute la suite PASS.
Si un test de redirection échoue parce que `GoRouter` évalue `redirect` avant que `auth.isVerified` ne reflète l'état, corriger `router.dart`, pas les tests.

- [ ] **Step 5: Vérification visuelle rapide**

Run: `flutter run -d chrome` (ou `flutter build web --release` si Chrome n'est pas utilisable), parcourir Connexion → Inscription → code → OnBoarding → Feed. Expected : parcours complet en mode mock, sans erreur console.

- [ ] **Step 6: Commit**

```bash
git add lib test/app_flow_test.dart
git commit -m "feat: routeur avec gardes d'accès et assemblage de l'app" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Firebase, déploiement GitHub Pages et README

**Files:**
- Create: `lib/firebase_config.dart`, `.github/workflows/deploy.yml`, `README.md`
- Modify: `lib/main.dart`
- Test: `test/firebase_config_test.dart`

**Interfaces:**
- Consumes: `FirebaseAuthRepository`, `MockAuthRepository`.
- Produces: `class FirebaseConfig { static bool get isConfigured; static FirebaseOptions get options; }` lue via `String.fromEnvironment` (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`). Sans configuration, l'app démarre en mode mock.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/firebase_config_test.dart`:
```dart
import 'package:autoscope/firebase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans --dart-define, Firebase n\'est pas considéré comme configuré', () {
    expect(FirebaseConfig.isConfigured, isFalse);
  });
}
```
Run: `flutter test test/firebase_config_test.dart`
Expected: FAIL.

- [ ] **Step 2: Implémenter la config et brancher main**

Create `lib/firebase_config.dart`:
```dart
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
```

Replace `lib/main.dart`:
```dart
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
```
Run: `flutter test && flutter analyze --no-fatal-infos`
Expected: tout PASS.

- [ ] **Step 3: Workflow GitHub Pages**

Create `.github/workflows/deploy.yml`:
```yaml
name: Déploiement GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze --no-fatal-infos
      - run: flutter test
      - name: Build web
        run: >
          flutter build web --release
          --base-href "/${{ github.event.repository.name }}/"
          --dart-define=FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }}
          --dart-define=FIREBASE_APP_ID=${{ secrets.FIREBASE_APP_ID }}
          --dart-define=FIREBASE_MESSAGING_SENDER_ID=${{ secrets.FIREBASE_MESSAGING_SENDER_ID }}
          --dart-define=FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
          --dart-define=FIREBASE_AUTH_DOMAIN=${{ secrets.FIREBASE_AUTH_DOMAIN }}
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 4: README avec guide Firebase**

Create `README.md`:
````markdown
# Autoscope : démo Flutter

Démo web mobile-first : Connexion/Inscription, OnBoarding (recherche de voiture), Feed (fiche véhicule). Données fictives.

## Lancer en local

```bash
flutter pub get
flutter run -d chrome   # sans config Firebase : mode démo (comptes en mémoire)
flutter test
```

## Vérification email (démo)

Firebase Auth n'envoie pas de code à 6 chiffres (seulement un lien) et GitHub Pages est statique. Le code à 6 chiffres est donc **généré et stocké côté client** (localStorage) puis **affiché dans un bandeau « Mode démo »**. Aucun email n'est envoyé et ce n'est **pas sécurisé**. En production : une Cloud Function (plan Blaze) générerait, enverrait et vérifierait le code.

## Configurer Firebase (4 étapes)

1. Console Firebase → **Ajouter un projet**.
2. **Authentication → Méthode de connexion** → activer **Adresse e-mail/Mot de passe**. Dans **Paramètres → Domaines autorisés**, ajouter `<utilisateur>.github.io`.
3. **Paramètres du projet → Vos applications → Web (`</>`)** → enregistrer l'app et copier la config (`apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`).
4. Dépôt GitHub → **Settings → Secrets and variables → Actions** : créer `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`.

En local avec Firebase :
```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=...
```

## Déploiement GitHub Pages

Dépôt GitHub → **Settings → Pages → Source : GitHub Actions**. Chaque push sur `main` lance `.github/workflows/deploy.yml` (analyse, tests, build, publication). Sans secrets, le site est publié en mode démo (comptes en mémoire).

## Remplacer les visuels

Les logos de marques (`assets/brands/`) et les visuels véhicule (`assets/photos/`) sont des illustrations SVG. Pour utiliser de vraies photos, remplacer les fichiers et mettre à jour `Vehicle.demo.photos` dans `lib/feed/vehicle.dart`.
````

- [ ] **Step 5: Vérifier le build web de production**

Run:
```bash
flutter build web --release --base-href "/autoscope/"
grep -o '<base href="[^"]*"' build/web/index.html
```
Expected: build OK ; la sortie contient `<base href="/autoscope/"`.

- [ ] **Step 6: Commit**

```bash
git add lib/firebase_config.dart lib/main.dart .github README.md test/firebase_config_test.dart
git commit -m "feat: config Firebase, workflow GitHub Pages et README" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: Publication (uniquement avec l'accord explicite de l'utilisateur)**

Ne pas exécuter sans confirmation. Poser la question à l'utilisateur : nom du dépôt, visibilité (public requis pour Pages gratuit), puis :
```bash
gh repo create <nom> --public --source=. --push
gh api -X POST repos/{owner}/<nom>/pages -f build_type=workflow
```
Puis surveiller le workflow : `gh run watch`.
