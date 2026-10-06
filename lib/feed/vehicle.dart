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
