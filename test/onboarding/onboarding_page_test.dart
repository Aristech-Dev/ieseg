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
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/feed', builder: (_, _) => const Text('PAGE FEED')),
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
