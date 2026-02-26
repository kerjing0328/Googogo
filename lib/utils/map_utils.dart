import 'package:flutter/material.dart';
import '../models/route_option.dart';

Color getSeverityColor(int severity) {
  if (severity >= 8) return Colors.red;
  if (severity >= 4) return Colors.orange;
  return Colors.green;
}

IconData getModeIcon(UserMode mode) {
  switch (mode) {
    case UserMode.voice:
      return Icons.record_voice_over;
    case UserMode.wheelchair:
      return Icons.wheelchair_pickup;
    default:
      return Icons.person;
  }
}