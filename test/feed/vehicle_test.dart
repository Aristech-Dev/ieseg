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
