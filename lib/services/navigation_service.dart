import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/route_step.dart';

class NavigationService {
  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<List<dynamic>> fetchPlaceSuggestions(String input) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey";
    
    try {
      final response = await http.get(Uri.parse(url));
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        return json['predictions'];
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> calculateRoutes(LatLng origin, String destinationInput) async {
    double destLat = 0;
    double destLng = 0;

    try {
      List<Location> locations = await locationFromAddress(destinationInput);
      if (locations.isNotEmpty) {
        destLat = locations.first.latitude;
        destLng = locations.first.longitude;
      }
    } catch (e) {
      print("Geocoding failed, using fallback offset.");
      destLat = origin.latitude + 0.005;
      destLng = origin.longitude + 0.005;
    }

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=$destLat,$destLng&mode=walking&alternatives=true&key=$_apiKey";

    final response = await http.get(Uri.parse(url));
    final json = jsonDecode(response.body);

    if (json['status'] == 'OK' && (json['routes'] as List).isNotEmpty) {
      List<Map<String, dynamic>> routeOptions = [];

      for (var routeData in json['routes']) {
        
        String encodedPoints = routeData['overview_polyline']['points'];
        List<PointLatLng> decodedPoints = PolylinePoints().decodePolyline(encodedPoints);
        List<LatLng> polylineCoords = decodedPoints
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        List<dynamic> stepsData = routeData['legs'][0]['steps'];
        List<RouteStep> navSteps = stepsData.map((step) {
          String text = step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
          return RouteStep(
            instruction: text,
            endLocation: LatLng(step['end_location']['lat'], step['end_location']['lng']),
          );
        }).toList();

        var leg = routeData['legs'][0];
        
        routeOptions.add({
          'polyline': polylineCoords,
          'steps': navSteps,
          'bounds': routeData['bounds'],
          'summary': routeData['summary'] ?? 'Route', 
          'distance': leg['distance']['text'],
          'duration': leg['duration']['text'],
          'destLat': destLat,
          'destLng': destLng,
        });
      }

      return routeOptions;
    }

    throw Exception("No routes found");
  }
}