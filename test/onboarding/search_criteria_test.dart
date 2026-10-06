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
