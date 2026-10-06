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
