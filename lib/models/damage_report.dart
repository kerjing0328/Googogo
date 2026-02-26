import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

class DamageReport {
  final String id;
  final String reportId;
  final String status;
  final String adminNotes;
  final String imageUrl;
  final GeoPoint location;
  final String state;
  final String damageType;
  final int severity;
  final String shortDesc;
  final double? heading;
  final Timestamp? timestamp;
  final String reporterId;

  DamageReport({
    required this.id,
    required this.reportId,
    required this.status,
    required this.adminNotes,
    required this.imageUrl,
    required this.location,
    required this.state,
    required this.damageType,
    required this.severity,
    required this.shortDesc,
    this.heading,
    this.timestamp,
    required this.reporterId,
  });

  factory DamageReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DamageReport(
      id: doc.id,
      reportId: data['reportId'] ?? '',
      status: data['status'] ?? 'submitted',
      adminNotes: data['admin_notes'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      state: data['state'] ?? '',
      damageType: data['damage_type'] ?? '',
      severity: data['severity'] is int ? data['severity'] : int.tryParse(data['severity'].toString()) ?? 0,
      shortDesc: data['short_desc'] ?? '',
      heading: (data['heading'] as num?)?.toDouble(),
      timestamp: data['timestamp'],
      reporterId: data['reporterId'] ?? '',
    );
  }

  LatLng get latLng => LatLng(location.latitude, location.longitude);
}