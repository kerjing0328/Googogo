import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/route_step.dart';

class NavigationService {
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<List<dynamic>> fetchPlaceSuggestions(String input) async {
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') return json['predictions'];
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<Map<String, dynamic>> calculateRoute(LatLng origin, String destinationInput) async {
    double destLat = 0, destLng = 0;
    
    // 1. Get Destination Coordinates
    try {
      List<Location> locations = await locationFromAddress(destinationInput);
      if (locations.isNotEmpty) {
        destLat = locations.first.latitude;
        destLng = locations.first.longitude;
      }
    } catch (e) {
      // Fallback if geocoding fails (demo purpose from original code)
      destLat = origin.latitude + 0.005;
      destLng = origin.longitude + 0.005;
    }

    // 2. Fetch Directions
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=$destLat,$destLng&mode=walking&key=$_apiKey";
    final response = await http.get(Uri.parse(url));
    final json = jsonDecode(response.body);

    if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
      var bestRoute = json['routes'][0];
      List<dynamic> stepsData = bestRoute['legs'][0]['steps'];
      
      List<RouteStep> navSteps = stepsData.map((step) {
        String text = step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
        return RouteStep(
          instruction: text,
          endLocation: LatLng(step['end_location']['lat'], step['end_location']['lng']),
        );
      }).toList();

      String points = bestRoute['overview_polyline']['points'];
      List<PointLatLng> result = PolylinePoints().decodePolyline(points);
      List<LatLng> polylineCoords = result.map((p) => LatLng(p.latitude, p.longitude)).toList();

      return {
        'steps': navSteps,
        'polyline': polylineCoords,
        'destLat': destLat,
        'destLng': destLng,
      };
    }
    throw Exception("Route not found");
  }
}