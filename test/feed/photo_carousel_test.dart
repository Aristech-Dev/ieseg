import 'package:autoscope/feed/photo_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String path) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: PhotoCarousel(photos: [path]))),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'avif', 'JPG']) {
    testWidgets('une photo .$ext est affichée comme image matricielle', (tester) async {
      await _pump(tester, 'assets/photos/absente.$ext');
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });
  }

  testWidgets('une photo .svg reste affichée comme SVG', (tester) async {
    await _pump(tester, 'assets/photos/car_1.svg');
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('une image introuvable affiche un repère au lieu de planter', (tester) async {
    await _pump(tester, 'assets/photos/absente.jpg');
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
