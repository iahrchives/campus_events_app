/// Static definition of the campus building's 7 floors and the venues/areas
/// available on each. Used by the Campus Map and the Event creation form so
/// events are always tied to a real venue on a real floor.
class CampusFloors {
  CampusFloors._();

  /// Floor name → list of venues/areas on that floor.
  static const Map<String, List<String>> floors = {
    'First Floor': ['Main Lobby', 'Admissions Office', 'Clinic'],
    'Second Floor': ['Cafe', 'Library'],
    'Third Floor': ['Room 301', 'Room 302', 'Computer Lab'],
    'Fourth Floor': ['Room 401', 'Room 402', 'Science Lab'],
    'Fifth Floor': ['Room 501', 'Room 502', 'Drawing Studio'],
    'Sixth Floor': ['Room 601', 'Room 602', 'AVR'],
    'Seventh Floor': [
      'Gymnasium (Left)',
      'Gymnasium (Right)',
      'Bleachers (Left)',
      'Bleachers (Right)',
      'Meeting Room 1',
      'Meeting Room 2',
    ],
  };

  static List<String> get names => floors.keys.toList();

  static List<String> venuesOf(String floor) => floors[floor] ?? const [];

  /// Which floor a given venue belongs to (null if it isn't a known venue).
  static String? floorOf(String venue) {
    for (final entry in floors.entries) {
      if (entry.value.contains(venue)) return entry.key;
    }
    return null;
  }
}
