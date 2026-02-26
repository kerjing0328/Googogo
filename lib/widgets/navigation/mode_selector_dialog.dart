import 'package:flutter/material.dart';
import '../../models/route_option.dart';

class ModeSelectorDialog extends StatelessWidget {
  final Function(UserMode) onModeSelected;

  const ModeSelectorDialog({super.key, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Assistance Mode"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeTile(
            context,
            UserMode.voice,
            "Voice",
            Icons.record_voice_over,
            "Audio-first navigation.",
          ),
          _buildModeTile(
            context,
            UserMode.wheelchair,
            "Wheelchair",
            Icons.wheelchair_pickup,
            "Prioritize ramps & smooth paths.",
          ),
          _buildModeTile(
            context,
            UserMode.standard,
            "Standard",
            Icons.person,
            "Avoids path blockages.",
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile(
    BuildContext context,
    UserMode mode,
    String label,
    IconData icon,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal, size: 30),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        onModeSelected(mode);
        Navigator.pop(context);
      },
    );
  }
}