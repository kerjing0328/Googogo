import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class LocationService {
  static Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  static Future<String> getStateFromCoordinates(double lat, double lon) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first.administrativeArea ?? '';
      }
    } catch (e) {
      // ignore
    }
    return '';
  }

  static String normalizeStateName(String? rawInput) {
    if (rawInput == null) return "Unknown State";
    String input = rawInput.toLowerCase();
    if (input.contains('johor')) return 'Johor';
    if (input.contains('kedah')) return 'Kedah';
    if (input.contains('kelantan')) return 'Kelantan';
    if (input.contains('melaka') || input.contains('malacca')) return 'Malacca';
    if (input.contains('negeri sembilan')) return 'Negeri Sembilan';
    if (input.contains('pahang')) return 'Pahang';
    if (input.contains('penang') || input.contains('pulau pinang')) return 'Penang';
    if (input.contains('perak')) return 'Perak';
    if (input.contains('perlis')) return 'Perlis';
    if (input.contains('selangor')) return 'Selangor';
    if (input.contains('terengganu')) return 'Terengganu';
    if (input.contains('sabah')) return 'Sabah';
    if (input.contains('sarawak')) return 'Sarawak';
    if (input.contains('kuala lumpur')) return 'Kuala Lumpur';
    if (input.contains('putrajaya')) return 'Putrajaya';
    if (input.contains('labuan')) return 'Labuan';
    return "Unknown State";
  }
}