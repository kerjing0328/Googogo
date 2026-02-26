import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_step.dart';

class RouteOption {
  final String id;
  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final String summary;
  final String duration;
  final int issueCount;
  final int safetyScore;
  final Map<int, List<String>> issuesPerStep;
  final List<String> reporterIds; 

  RouteOption({
    required this.id,
    required this.polyline,
    required this.steps,
    required this.summary,
    required this.duration,
    required this.issueCount,
    required this.safetyScore,
    this.issuesPerStep = const {},
    this.reporterIds = const [], 
  });
}

enum UserMode { standard, voice, wheelchair }