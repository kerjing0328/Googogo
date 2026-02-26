import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/damage.dart';
import '../models/route_option.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class NavigationFirebaseService {
  final String userId;

  NavigationFirebaseService({required this.userId});

  Stream<List<Damage>> watchWalkwayDamage() {
    return FirebaseFirestore.instance
        .collection('walkway_damage')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Damage.fromFirestore(doc)).toList());
  }

  /// Logs which routes were considered and credits volunteers whose reports helped.
  Future<void> logHelpedReports({
    required List<RouteOption> routeOptions,
    required RouteOption? selectedRoute,
    required String navigatorId,
  }) async {
    if (routeOptions.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final Set<String> uniqueHelpedReporters = {};

      for (var route in routeOptions) {
        bool isSelected = (route == selectedRoute);
        bool hasIssues = route.issueCount > 0;

        // Log if this route was taken OR if it had issues (helped us avoid hazards)
        if (isSelected || hasIssues) {
          final doc = FirebaseFirestore.instance.collection('navigation_logs').doc();
          batch.set(doc, {
            'navigatorId': navigatorId,
            'routeId': route.id,
            'timestamp': FieldValue.serverTimestamp(),
            'helpedReporterIds': route.reporterIds,
            'issueCount': route.issueCount,
            'status': isSelected ? 'taken' : 'avoided_hazard',
          });

          uniqueHelpedReporters.addAll(route.reporterIds);
        }
      }

      // Increment `usersHelped` for each unique reporter
      for (String reporterId in uniqueHelpedReporters) {
        if (reporterId.isNotEmpty) {
          final userRef = FirebaseFirestore.instance.collection('users').doc(reporterId);
          batch.set(userRef, {
            'usersHelped': FieldValue.increment(1),
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();
      debugPrint("Logged routes and credited ${uniqueHelpedReporters.length} volunteers.");
    } catch (e) {
      debugPrint("Help logging failed: $e");
    }
  }
}