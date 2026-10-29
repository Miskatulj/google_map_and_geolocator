import 'package:flutter_test/flutter_test.dart';
import 'package:google_map_and_geolocator/main.dart';

void main() {
  testWidgets('location tracker app can be created', (tester) async {
    expect(const LocationTrackerApp(), isNotNull);
  });
}
