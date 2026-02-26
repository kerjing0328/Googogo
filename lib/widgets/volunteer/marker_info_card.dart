import 'package:flutter/material.dart';
import '../../models/damage_report.dart';

class MarkerInfoCard extends StatelessWidget {
  final DamageReport report;
  final VoidCallback onClose;
  final Color Function(int) getSeverityColor;

  const MarkerInfoCard({
    super.key,
    required this.report,
    required this.onClose,
    required this.getSeverityColor,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = getSeverityColor(report.severity);
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (report.imageUrl.isNotEmpty)
            Stack(
              children: [
                Image.network(
                  report.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 140,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (ctx, _, __) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: severityColor.withOpacity(0.1)),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: severityColor.withOpacity(0.1),
              child: Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: severityColor,
                  size: 32,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report.damageType.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "LVL ${report.severity}/10",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 24),
                Text(
                  report.shortDesc.isNotEmpty ? report.shortDesc : "No description provided.",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}