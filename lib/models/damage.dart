import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Damage {
  final String id;
  final String damageType;
  final int severity;
  final String shortDesc;
  final String imageUrl;
  final GeoPoint location;
  final String reporterId;

  Damage({
    required this.id,
    required this.damageType,
    required this.severity,
    required this.shortDesc,
    required this.imageUrl,
    required this.location,
    required this.reporterId,
  });

  factory Damage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Damage(
      id: doc.id,
      damageType: data['damage_type'] ?? '',
      severity: data['severity'] is int
          ? data['severity']
          : int.tryParse(data['severity'].toString()) ?? 0,
      shortDesc: data['short_desc'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      reporterId: data['reporterId'] ?? '',
    );
  }

  LatLng get latLng => LatLng(location.latitude, location.longitude);
}