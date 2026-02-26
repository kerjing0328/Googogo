import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../models/damage_report.dart';

class FirebaseService {
  final String userId;

  FirebaseService({required this.userId});

  Stream<List<DamageReport>> watchWalkwayDamage() {
    return FirebaseFirestore.instance
        .collection('walkway_damage')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DamageReport.fromFirestore(doc)).toList());
  }

  Future<void> uploadDamageReport({
    required File imageFile,
    required String damageType,
    required int severity,
    required String shortDesc,
    required String state,
    required double? heading,
    required Position position,
  }) async {
    String fileName = 'walkway/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);
    await storageRef.putFile(imageFile);
    String downloadUrl = await storageRef.getDownloadURL();
    String reportId = "RPT-${Random().nextInt(90000) + 10000}";

    await FirebaseFirestore.instance.collection('walkway_damage').add({
      'reportId': reportId,
      'status': 'submitted',
      'admin_notes': '',
      'imageUrl': downloadUrl,
      'location': GeoPoint(position.latitude, position.longitude),
      'state': state,
      'damage_type': damageType,
      'severity': severity,
      'short_desc': shortDesc,
      'heading': heading,
      'timestamp': FieldValue.serverTimestamp(),
      'reporterId': userId,
    });
  }

  Future<void> incrementUserPoints(int points) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'points': FieldValue.increment(points),
    }, SetOptions(merge: true));
  }

  Future<Map<String, int>> fetchUserStats() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final reportSnap = await FirebaseFirestore.instance
        .collection('walkway_damage')
        .where('reporterId', isEqualTo: userId)
        .get();

    int points = userDoc.exists ? (userDoc.data()?['points'] ?? 0) : 0;
    int totalReports = reportSnap.docs.length;
    int totalHelped = userDoc.exists ? (userDoc.data()?['usersHelped'] ?? 0) : 0;

    return {
      'points': points,
      'totalReports': totalReports,
      'totalHelped': totalHelped,
    };
  }
}