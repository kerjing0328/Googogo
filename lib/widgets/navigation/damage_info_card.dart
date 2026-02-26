import 'package:flutter/material.dart';
import '../../models/damage.dart';
import '../../utils/map_utils.dart';

class DamageInfoCard extends StatelessWidget {
  final Damage damage;
  final VoidCallback onClose;

  const DamageInfoCard({
    super.key,
    required this.damage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = getSeverityColor(damage.severity);
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (damage.imageUrl.isNotEmpty)
            Stack(
              children: [
                Image.network(
                  damage.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 140,
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
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
                  Icons.warning_rounded,
                  color: severityColor,
                  size: 40,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        damage.damageType.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "SEVERITY: ${damage.severity}/10",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 25),
                Text(
                  damage.shortDesc.isEmpty
                      ? "No additional details provided."
                      : damage.shortDesc,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
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