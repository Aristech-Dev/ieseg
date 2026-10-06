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
      GoRoute(path: '/feed', builder: (_, _) => const FeedPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const Text('PAGE ONBOARDING')),
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
