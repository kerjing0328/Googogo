import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // This saves the Gemini analysis and location to the cloud
  Future<void> saveAccessibilityData({
    required double lat,
    required double lng,
    required String description,
    required int score,
    required String imageUrl,
  }) async {
    await _db.collection('barriers').add({
      'location': GeoPoint(lat, lng),
      'description': description,
      'score': score,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // This fetches all barriers to show markers on the Google Map
  Stream<QuerySnapshot> getBarriers() {
    return _db.collection('barriers').snapshots();
  }
}