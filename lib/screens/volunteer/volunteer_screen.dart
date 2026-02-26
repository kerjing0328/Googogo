import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';  
import 'package:geolocator/geolocator.dart';            
import 'package:firebase_auth/firebase_auth.dart';

// Services
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/compass_service.dart';
import '../../services/firebase_service.dart';
import '../../services/image_picker_service.dart';

// Models
import '../../models/damage_report.dart';

// Widgets
import '../../widgets/volunteer/volunteer_history_sheet.dart';
import '../../widgets/volunteer/volunteer_profile_sheet.dart';
import '../../widgets/volunteer/marker_info_card.dart';
import '../../widgets/volunteer/review_bottom_sheet.dart';
import '../../widgets/volunteer/rejection_dialog.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // Services
  late final FirebaseService _firebaseService;
  final ImagePickerService _imagePickerService = ImagePickerService();

  // State
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoadingMap = true;
  String _areaStatusText = "Checking area...";
  Color _areaStatusColor = Colors.grey;
  IconData _areaStatusIcon = Icons.search;
  int _userPoints = 0;
  int _totalReports = 0;
  int _totalHelped = 0;
  double? _currentHeading = 0.0;

  DamageReport? _selectedReport;
  bool _showFloatingCard = false;

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<DamageReport>>? _damageSubscription;

  // final String _userId = "volunteer_demo_user";
  late final String _userId;
  
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _userId = currentUser?.uid ?? "anonymous";
    _firebaseService = FirebaseService(userId: _userId);
    _startLocationTracking();
    _listenToWalkwayDamage();
    _fetchUserStats();
    _compassSubscription = CompassService.listenToCompass((heading) {
      if (mounted) setState(() => _currentHeading = heading);
    });
  }

  @override
  void dispose() {
    _damageSubscription?.cancel();
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  Color _getSeverityColor(int severity) {
    if (severity >= 8) return Colors.red;
    if (severity >= 4) return Colors.orange;
    return Colors.green;
  }

  void _listenToWalkwayDamage() {
    _damageSubscription = _firebaseService.watchWalkwayDamage().listen((reports) {
      final newMarkers = reports.map((report) {
        double hue = BitmapDescriptor.hueGreen;
        if (report.severity >= 4) hue = BitmapDescriptor.hueOrange;
        if (report.severity >= 8) hue = BitmapDescriptor.hueRed;

        return Marker(
          markerId: MarkerId(report.id),
          position: report.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            setState(() {
              _selectedReport = report;
              _showFloatingCard = true;
            });
          },
        );
      }).toSet();

      if (mounted) {
        setState(() => _markers = newMarkers);
        _updateAreaStatus();
      }
    });
  }

  Future<void> _captureAndAnalyze() async {
    final imageFile = await _imagePickerService.pickImageFromCamera();
    if (imageFile == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Analyzing & Locating..."),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pos = await LocationService.getCurrentPosition();
      final rawState = await LocationService.getStateFromCoordinates(
          pos.latitude, pos.longitude);
      final detectedState = LocationService.normalizeStateName(rawState);

      final aiResult = await AiService.analyzeImage(imageFile);

      if (!mounted) return;
      Navigator.pop(context);

      if (aiResult['is_valid_path'] == false) {
        showRejectionDialog(
            context, aiResult['rejection_reason'] ?? "Not a valid path.");
      } else {
        _showReviewSheet(imageFile, aiResult, detectedState);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showReviewSheet(
      File imageFile, Map<String, dynamic> aiResult, String state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewBottomSheet(
        imageFile: imageFile,
        aiResult: aiResult,
        detectedState: state,
        getSeverityColor: _getSeverityColor,
        onDiscard: () => Navigator.pop(ctx),
        onConfirm: (damageType, severity, description) async {
          Navigator.pop(ctx); // close bottom sheet
          await _uploadDamage(
              imageFile, damageType, severity, description, state);
        },
      ),
    );
  }

  Future<void> _uploadDamage(File imageFile, String damageType, int severity,
      String description, String state) async {
    try {
      final pos = await LocationService.getCurrentPosition();
      await _firebaseService.uploadDamageReport(
        imageFile: imageFile,
        damageType: damageType,
        severity: severity,
        shortDesc: description,
        state: state,
        heading: _currentHeading,
        position: pos,
      );
      await _firebaseService.incrementUserPoints(100);
      await _fetchUserStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Report Submitted!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _updateAreaStatus() {
    if (_currentPosition == null) return;
    int nearbyCount = 0;
    for (var marker in _markers) {
      double dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      if (dist < 150) nearbyCount++;
    }
    setState(() {
      if (nearbyCount == 0) {
        _areaStatusText = "Unmapped. Upload photos!";
        _areaStatusColor = Colors.red;
        _areaStatusIcon = Icons.add_a_photo;
      } else {
        _areaStatusText = "Area mapped ($nearbyCount).";
        _areaStatusColor = Colors.teal;
        _areaStatusIcon = Icons.check_circle;
      }
    });
  }

  Future<void> _startLocationTracking() async {
    try {
      final initialPos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition =
              LatLng(initialPos.latitude, initialPos.longitude);
          _isLoadingMap = false;
        });
        final controller = await _mapController.future;
        controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 17));
      }

      _locationSubscription =
          LocationService.getPositionStream().listen((pos) {
        if (mounted) {
          setState(() =>
              _currentPosition = LatLng(pos.latitude, pos.longitude));
          _updateAreaStatus();
        }
      });
    } catch (e) {
      // handle permission denied etc.
    }
  }

  Future<void> _fetchUserStats() async {
    try {
      final stats = await _firebaseService.fetchUserStats();
      if (mounted) {
        setState(() {
          _userPoints = stats['points']!;
          _totalReports = stats['totalReports']!;
          _totalHelped = stats['totalHelped']!;
        });
      }
    } catch (e) {
      debugPrint("Fetch stats error: $e");
    }
  }

  void _showProfileStats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VolunteerProfileSheet(
        points: _userPoints,
        reports: _totalReports,
        helped: _totalHelped,
      ),
    );
  }

  void _showUploadHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, controller) => VolunteerHistorySheet(
          userId: _userId,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoadingMap
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(3.1390, 101.6869),
                    zoom: 17,
                  ),
                  myLocationEnabled: true,
                  markers: _markers,
                  onMapCreated: (c) => _mapController.complete(c),
                  onTap: (_) => setState(() => _showFloatingCard = false),
                ),

          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: _showProfileStats,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.volunteer_activism,
                          color: Colors.teal),
                      const SizedBox(width: 8),
                      const Text("Volunteer Mode",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Text("⭐ $_userPoints",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _showUploadHistory,
              backgroundColor: Colors.white,
              child: const Icon(Icons.history, color: Colors.blueGrey),
            ),
          ),

          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _areaStatusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_areaStatusIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _areaStatusText,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            child: ElevatedButton.icon(
              onPressed: _captureAndAnalyze,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text("Report Damage",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),

          if (_showFloatingCard && _selectedReport != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: MarkerInfoCard(
                report: _selectedReport!,
                getSeverityColor: _getSeverityColor,
                onClose: () => setState(() => _showFloatingCard = false),
              ),
            ),
        ],
      ),
    );
  }
}