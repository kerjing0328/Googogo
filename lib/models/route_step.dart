import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteStep {
  final String instruction;
  final LatLng endLocation;
  RouteStep({required this.instruction, required this.endLocation});
}