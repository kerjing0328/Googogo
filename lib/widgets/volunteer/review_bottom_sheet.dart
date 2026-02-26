import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/location_service.dart'; // for normalizeStateName maybe, but we can pass state as string.

class ReviewBottomSheet extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> aiResult;
  final String detectedState;
  final Function(String damageType, int severity, String description) onConfirm;
  final VoidCallback onDiscard;
  final Color Function(int) getSeverityColor;

  const ReviewBottomSheet({
    super.key,
    required this.imageFile,
    required this.aiResult,
    required this.detectedState,
    required this.onConfirm,
    required this.onDiscard,
    required this.getSeverityColor,
  });

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  late String currentType;
  late double currentSeverity;
  late TextEditingController descController;

  final List<String> validTypes = ['CRACK', 'HOLE', 'OBSTACLE', 'NARROW', 'HAZARDS', 'OTHER', 'NO_PATH'];

  @override
  void initState() {
    super.initState();
    String initialType = widget.aiResult['damage_type'].toString().toLowerCase();
    if (!validTypes.contains(initialType)) initialType = 'obstacle';
    currentType = initialType;

    if (widget.aiResult['severity'] is int) {
      currentSeverity = (widget.aiResult['severity'] as int).toDouble();
    } else if (widget.aiResult['severity'] is String) {
      currentSeverity = double.tryParse(widget.aiResult['severity']) ?? 5.0;
    } else {
      currentSeverity = 5.0;
    }

    descController = TextEditingController(text: widget.aiResult['short_desc']);
  }

  @override
  void dispose() {
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Edit & Verify Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.imageFile,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Damage Type",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentType,
                        isExpanded: true,
                        items: validTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        )).toList(),
                        onChanged: (val) => setState(() => currentType = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Severity Level", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        "${currentSeverity.round()}/10",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.getSeverityColor(currentSeverity.round()),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentSeverity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: widget.getSeverityColor(currentSeverity.round()),
                    onChanged: (val) => setState(() => currentSeverity = val),
                  ),
                  const Text("Description", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Describe the issue...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 5),
                      Text(
                        "Location: ${widget.detectedState}",
                        style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDiscard,
                    child: const Text("Discard"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(currentType, currentSeverity.round(), descController.text);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("Confirm & Earn", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}