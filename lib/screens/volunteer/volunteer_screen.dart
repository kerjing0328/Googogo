import 'dart:io';
import 'dart:async';
import 'dart:math'; // Import for Random ID generation
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../services/ai_service.dart';
import 'volunteer_history_sheet.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoadingMap = true;
  String _areaStatusText = "Checking area...";
  Color _areaStatusColor = Colors.grey;
  IconData _areaStatusIcon = Icons.search;
  int _userPoints = 0; 
  double? _currentHeading = 0.0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _locationSubscription;
  final _picker = ImagePicker();
  StreamSubscription? _damageSubscription;
  final String _userId = "volunteer_demo_user";

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _listenToWalkwayDamage();
    _fetchUserStats(); 
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (mounted) setState(() => _currentHeading = event.heading);
    });
  }

  @override
  void dispose() {
    _damageSubscription?.cancel();
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  // --- STATE NORMALIZATION ---
  String _normalizeStateName(String? rawInput) {
    if (rawInput == null) return "Unknown State";
    String input = rawInput.toLowerCase();
    if (input.contains('johor')) return 'Johor';
    if (input.contains('kedah')) return 'Kedah';
    if (input.contains('kelantan')) return 'Kelantan';
    if (input.contains('melaka') || input.contains('malacca')) return 'Malacca';
    if (input.contains('negeri sembilan')) return 'Negeri Sembilan';
    if (input.contains('pahang')) return 'Pahang';
    if (input.contains('penang') || input.contains('pulau pinang')) return 'Penang';
    if (input.contains('perak')) return 'Perak';
    if (input.contains('perlis')) return 'Perlis';
    if (input.contains('selangor')) return 'Selangor';
    if (input.contains('terengganu')) return 'Terengganu';
    if (input.contains('sabah')) return 'Sabah';
    if (input.contains('sarawak')) return 'Sarawak';
    if (input.contains('kuala lumpur')) return 'Kuala Lumpur';
    if (input.contains('putrajaya')) return 'Putrajaya';
    if (input.contains('labuan')) return 'Labuan';
    return "Unknown State"; 
  }

  // --- CAPTURE & ANALYZE ---
  Future<void> _captureAndAnalyze() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo == null) return;
    File tempImage = File(photo.path);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: Card(child: Padding(padding: EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Analyzing & Locating...")])))),
    );

    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
      String rawState = placemarks.isNotEmpty ? (placemarks.first.administrativeArea ?? "") : "";
      String detectedState = _normalizeStateName(rawState);

      // Call the AI Service
      final aiResult = await AiService.analyzeImage(tempImage);

      if (!mounted) return;
      Navigator.pop(context); 

      if (aiResult['is_valid_path'] == false) {
        _showRejectionDialog(aiResult['rejection_reason'] ?? "Not a valid path.");
      } else {
        _showReviewDialog(tempImage, aiResult, detectedState);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- REVIEW DIALOG (UPDATED WITH EDITING) ---
  void _showReviewDialog(File imageFile, Map<String, dynamic> result, String state) {
    // 1. Initialize Editable Values
    String currentType = result['damage_type'].toString().toLowerCase();
    final validTypes = ['hole', 'uneven', 'obstacle', 'narrow', 'clear'];
    if (!validTypes.contains(currentType)) currentType = 'obstacle';

    double currentSeverity;
    if (result['severity'] is int) {
      currentSeverity = (result['severity'] as int).toDouble();
    } else if (result['severity'] is String) {
      currentSeverity = double.tryParse(result['severity']) ?? 5.0;
    } else {
      currentSeverity = 5.0;
    }
    if (currentSeverity < 1) currentSeverity = 1;
    if (currentSeverity > 10) currentSeverity = 10;

    TextEditingController descController = TextEditingController(text: result['short_desc']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          
          Color severityColor = Colors.green; 
          if (currentSeverity >= 4) severityColor = Colors.orange; 
          if (currentSeverity >= 8) severityColor = Colors.red;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Edit & Verify Report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(imageFile, height: 200, width: double.infinity, fit: BoxFit.cover)),
                        const SizedBox(height: 20),

                        // 1. EDITABLE TYPE
                        const Text("Damage Type", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentType,
                              isExpanded: true,
                              items: validTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setModalState(() {
                                  currentType = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 2. EDITABLE SEVERITY
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Severity Level", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text("${currentSeverity.round()}/10", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: severityColor)),
                          ],
                        ),
                        Slider(
                          value: currentSeverity,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: severityColor,
                          label: currentSeverity.round().toString(),
                          onChanged: (double value) {
                            setModalState(() {
                              currentSeverity = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),

                        // 3. EDITABLE DESCRIPTION
                        const Text("Description", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Describe the issue...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.blueGrey), const SizedBox(width: 5), Text("Detected Location: $state", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500))]),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.only(
                    left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 10
                  ),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("Discard"))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Map<String, dynamic> finalResult = {
                            'damage_type': currentType,
                            'severity': currentSeverity.round(),
                            'short_desc': descController.text,
                          };
                          _uploadDamage(imageFile, finalResult, state);
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 15)), 
                        child: const Text("Confirm & Earn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      )),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // --- UPLOAD (UPDATED WITH REPORT ID & STATUS) ---
  Future<void> _uploadDamage(File imageFile, Map<String, dynamic> result, String state) async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      String fileName = 'walkway/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      // Generate a readable ID (e.g., RPT-83921)
      String reportId = "RPT-${Random().nextInt(90000) + 10000}";

      await FirebaseFirestore.instance.collection('walkway_damage').add({
        'reportId': reportId, // NEW: Readable ID
        'status': 'submitted', // NEW: Initial Status
        'admin_notes': '', // NEW: Placeholder for authority response
        'imageUrl': downloadUrl,
        'location': GeoPoint(pos.latitude, pos.longitude),
        'state': state,
        'damage_type': result['damage_type'],
        'severity': result['severity'],
        'short_desc': result['short_desc'],
        'heading': _currentHeading,
        'timestamp': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(), // NEW: Track status changes
        'reporterId': _userId,
      });

      await FirebaseFirestore.instance.collection('users').doc(_userId).set({'points': FieldValue.increment(100)}, SetOptions(merge: true));
      _fetchUserStats(); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Report #$reportId Submitted! +100 Points"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _fetchUserStats() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (mounted) setState(() => _userPoints = userDoc.exists ? (userDoc.data()?['points'] ?? 0) : 0);
  }

  void _showProfileStats() {
    String badge = "Street Scout";
    Color badgeColor = Colors.brown.shade300;
    int nextLevelPoints = 200;

    if (_userPoints >= 500) { badge = "Urban Legend"; badgeColor = Colors.amber; nextLevelPoints = 1000; } 
    else if (_userPoints >= 200) { badge = "City Guardian"; badgeColor = Colors.grey.shade400; nextLevelPoints = 500; }

    double progress = (_userPoints % nextLevelPoints) / (nextLevelPoints > 500 ? 500 : 200);
    if (_userPoints >= 1000) progress = 1.0;
    if (progress > 1.0) progress = progress - progress.floor();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.shield, size: 60, color: badgeColor)),
            const SizedBox(height: 15),
            Text(badge, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Your Volunteer Rank", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("$_userPoints XP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)), Text("${nextLevelPoints - _userPoints} to next level", style: const TextStyle(fontSize: 12, color: Colors.grey))]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 12, borderRadius: BorderRadius.circular(6), backgroundColor: Colors.grey.shade200, color: badgeColor),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), child: const Text("Keep Contributing", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(String reason) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Invalid Image"), content: Text("We couldn't accept this image.\n\nReason: $reason"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
  }

  Future<void> _startLocationTracking() async {
    bool permissionGranted = await _handleLocationPermission();
    if (!permissionGranted) return;
    Position initialPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() { _currentPosition = LatLng(initialPos.latitude, initialPos.longitude); _isLoadingMap = false; });
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _currentPosition!, zoom: 17)));
      _updateAreaStatus();
    }
    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) { setState(() => _currentPosition = LatLng(position.latitude, position.longitude)); _updateAreaStatus(); }
    });
  }

  void _listenToWalkwayDamage() {
    _damageSubscription = FirebaseFirestore.instance.collection('walkway_damage').snapshots().listen((snapshot) {
      Set<Marker> newMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        final GeoPoint point = data['location'];
        final String type = data['damage_type'] ?? 'unknown';
        int severity = 0;
        if (data['severity'] is int) severity = data['severity'];
        else if (data['severity'] is String) severity = int.tryParse(data['severity']) ?? 0;
        double hue = BitmapDescriptor.hueGreen; 
        if (severity >= 4) hue = BitmapDescriptor.hueOrange; 
        if (severity >= 8) hue = BitmapDescriptor.hueRed;    
        return Marker(markerId: MarkerId(doc.id), position: LatLng(point.latitude, point.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(hue), infoWindow: InfoWindow(title: "${type.toUpperCase()} (Lvl $severity)", snippet: data['short_desc']));
      }).toSet();
      if (mounted) { setState(() => _markers = newMarkers); _updateAreaStatus(); }
    });
  }

  void _updateAreaStatus() {
    if (_currentPosition == null) return;
    int nearbyCount = 0;
    for (var marker in _markers) {
      double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, marker.position.latitude, marker.position.longitude);
      if (dist < 150) nearbyCount++;
    }
    setState(() {
      if (nearbyCount == 0) { _areaStatusText = "Unmapped. Upload photos!"; _areaStatusColor = Colors.red; _areaStatusIcon = Icons.add_a_photo; } 
      else { _areaStatusText = "Area mapped ($nearbyCount). Good job!"; _areaStatusColor = Colors.teal; _areaStatusIcon = Icons.check_circle; }
    });
  }

  void _showUploadHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
        builder: (_, controller) => VolunteerHistorySheet(userId: _userId, scrollController: controller),
      ),
    );
  }

  Future<bool> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoadingMap ? const Center(child: CircularProgressIndicator()) : GoogleMap(initialCameraPosition: const CameraPosition(target: LatLng(3.1390, 101.6869), zoom: 17), myLocationEnabled: true, markers: _markers, onMapCreated: (c) => _mapController.complete(c)),
          Positioned(top: 50, left: 16, child: GestureDetector(onTap: _showProfileStats, child: Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [const Icon(Icons.volunteer_activism, color: Colors.teal), const SizedBox(width: 8), const Text("Volunteer Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 12), Container(width: 1, height: 20, color: Colors.grey[300]), const SizedBox(width: 12), const Icon(Icons.star, color: Colors.amber, size: 18), const SizedBox(width: 4), Text("$_userPoints", style: const TextStyle(fontWeight: FontWeight.bold))]))))),
          Positioned(top: 110, left: 16, right: 16, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: _areaStatusColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_areaStatusIcon, color: Colors.white, size: 18), const SizedBox(width: 8), Text(_areaStatusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))),
          Positioned(top: 50, right: 16, child: FloatingActionButton.small(heroTag: "historyBtn", onPressed: _showUploadHistory, backgroundColor: Colors.white, child: const Icon(Icons.history, color: Colors.blueGrey))),
          Positioned(bottom: 40, left: 20, child: ElevatedButton.icon(onPressed: _captureAndAnalyze, icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20), label: const Text("Report Damage", style: TextStyle(color: Colors.white, fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 6))),
        ],
      ),
    );
  }
}