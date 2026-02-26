import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton.small(
          heroTag: "zoom_in",
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black87),
          onPressed: onZoomIn,
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "zoom_out",
          backgroundColor: Colors.white,
          child: const Icon(Icons.remove, color: Colors.black87),
          onPressed: onZoomOut,
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "recenter_btn",
          backgroundColor: Colors.white,
          child: const Icon(Icons.navigation, color: Colors.blue),
          onPressed: onRecenter,
        ),
      ],
    );
  }
}