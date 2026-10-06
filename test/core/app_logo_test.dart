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
