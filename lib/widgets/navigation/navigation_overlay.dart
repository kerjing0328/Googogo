import 'package:flutter/material.dart';

class NavigationOverlay extends StatelessWidget {
  final String instruction;
  final VoidCallback onStop;

  const NavigationOverlay({
    super.key,
    required this.instruction,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                instruction,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onStop,
            ),
          ],
        ),
      ),
    );
  }
}