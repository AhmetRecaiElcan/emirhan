class AppConstants {
  static const int maxProfiles = 3;

  static const List<int> depotNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<String> depotLetters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  static const String specialDepot = 'Z1';

  static String buildDepot(int number, String letter) => '$number$letter';

  static ({int number, String letter, bool special}) parseDepot(String depot) {
    if (depot == specialDepot) {
      return (number: depotNumbers.first, letter: depotLetters.first, special: true);
    }
    final match = RegExp(r'^(\d+)([A-H])$').firstMatch(depot);
    if (match != null) {
      return (
        number: int.parse(match.group(1)!),
        letter: match.group(2)!,
        special: false,
      );
    }
    return (number: depotNumbers.first, letter: depotLetters.first, special: false);
  }

  static List<String> get allDepotLocations {
    return [
      for (final n in depotNumbers)
        for (final l in depotLetters) buildDepot(n, l),
      specialDepot,
    ];
  }

  static const List<String> unitTypes = [
    'Adet',
    'kg',
    'Lt',
  ];

  static const List<String> purchaseTypes = [
    'İşletme Geliriyle Alınanlar',
    'Devlet Kredisiyle Alınanlar',
  ];

  static const String appName = 'Ambar Stok';
  static const String organizationName = 'İkmal Kısım Amirliği';
}
