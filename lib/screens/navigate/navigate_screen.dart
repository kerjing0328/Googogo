import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/navigation_service.dart';
import '../../models/route_step.dart';

enum UserMode { standard, voice, wheelchair }

class OkuMapScreen extends StatefulWidget {
  const OkuMapScreen({super.key});

  @override
  State<OkuMapScreen> createState() => _OkuMapScreenState();
}

class _OkuMapScreenState extends State<OkuMapScreen> {
  final NavigationService _navService = NavigationService();
  UserMode _selectedMode = UserMode.standard;
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _destinationController = TextEditingController();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;

  List<RouteStep> _navigationSteps = [];
  String _currentInstruction = "Ready to navigate";
  bool _isNavigating = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  List<dynamic> _placeSuggestions = [];
  List<Map<String, dynamic>> _walkwayDamages = [];
  final Set<String> _alertedIds = {};

  Timer? _debounceTimer;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchWalkwayDamage();
    _initTts();
  }

  @override
  void dispose() {
    _stopNavigation();
    _debounceTimer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
  }

  Future<void> _speak(String text) async {
    if (_selectedMode == UserMode.voice || _selectedMode == UserMode.wheelchair) {
      await _tts.speak(text);
    }
  }

  void _startVoiceModeSequence() async {
    await _tts.speak("Voice mode active. Where would you like to go?");
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _handleMicPress();
  }

  void _handleMicPress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic, size: 50, color: Colors.red), SizedBox(height: 20), Text("Listening...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); 
        setState(() { _destinationController.text = "KL Sentral"; });
        _speak("Navigating to KL Sentral");
        _calculateRoute("KL Sentral");
      }
    });
  }

  void _fetchWalkwayDamage() {
    FirebaseFirestore.instance.collection('walkway_damage').get().then((snapshot) {
      setState(() {
        _walkwayDamages = snapshot.docs.map((doc) { var data = doc.data(); data['id'] = doc.id; return data; }).toList();
        _updateMarkers();
      });
    });
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};
    for (var damage in _walkwayDamages) {
      GeoPoint loc = damage['location'];
      String type = damage['damage_type'] ?? 'issue';
      int severity = damage['severity'] ?? 5;

      bool showPin = true;
      if (_selectedMode == UserMode.wheelchair && type == 'obstacle' && severity < 5) showPin = false;

      if (showPin) {
        newMarkers.add(Marker(markerId: MarkerId(damage['id']), position: LatLng(loc.latitude, loc.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(_getPinColor(severity)), infoWindow: InfoWindow(title: "Warning: ${type.toUpperCase()} (Lvl $severity)", snippet: damage['short_desc'])));
      }
    }
    if (_markers.any((m) => m.markerId.value == "dest")) { newMarkers.add(_markers.firstWhere((m) => m.markerId.value == "dest")); }
    setState(() => _markers = newMarkers);
  }

  double _getPinColor(int severity) {
    if (severity >= 8) return BitmapDescriptor.hueRed; 
    if (severity >= 4) return BitmapDescriptor.hueOrange; 
    return BitmapDescriptor.hueGreen; 
  }

  void _checkProximityToDamage(Position userPos) {
    for (var damage in _walkwayDamages) {
      GeoPoint loc = damage['location'];
      String id = damage['id'];
      String type = damage['damage_type'] ?? 'issue';
      int severity = damage['severity'] ?? 0;

      double dist = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, loc.latitude, loc.longitude);

      if (dist < 15 && !_alertedIds.contains(id)) {
        bool shouldAlert = false;
        String alertMsg = "";

        if (_selectedMode == UserMode.wheelchair) {
          if (type == 'hole' || type == 'uneven') { shouldAlert = true; alertMsg = "Warning. ${type} surface ahead. Difficulty level $severity."; }
        } else if (_selectedMode == UserMode.voice) {
          if (type == 'obstacle' || type == 'hole') { shouldAlert = true; alertMsg = "Stop. ${type} detected. ${damage['short_desc']}"; }
        } else {
          if (severity >= 8) { shouldAlert = true; alertMsg = "Path blockage ahead."; }
        }

        if (shouldAlert) {
          _alertedIds.add(id);
          _speak(alertMsg);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(alertMsg)));
        }
      }
    }
  }

  void _onSearchChanged(String input) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (input.isNotEmpty) _fetchPlaceSuggestions(input);
      else setState(() => _placeSuggestions = []);
    });
  }

  Future<void> _fetchPlaceSuggestions(String input) async {
    List<dynamic> suggestions = await _navService.fetchPlaceSuggestions(input);
    setState(() => _placeSuggestions = suggestions);
  }

  Future<void> _calculateRoute(String destinationInput) async {
    if (_currentPosition == null || destinationInput.isEmpty) return;
    setState(() { _placeSuggestions = []; _alertedIds.clear(); });
    FocusScope.of(context).unfocus();
    _speak("Finding route to $destinationInput");

    try {
      final result = await _navService.calculateRoute(_currentPosition!, destinationInput);
      
      List<RouteStep> navSteps = result['steps'];
      List<LatLng> polylineCoords = result['polyline'];
      double destLat = result['destLat'];
      double destLng = result['destLng'];

      int damageCount = 0;
      for (var d in _walkwayDamages) {
        GeoPoint loc = d['location'];
        for (var p in polylineCoords) {
          if (Geolocator.distanceBetween(loc.latitude, loc.longitude, p.latitude, p.longitude) < 20) damageCount++;
        }
      }

      setState(() {
        _navigationSteps = navSteps;
        _currentInstruction = navSteps.isNotEmpty ? navSteps[0].instruction : "Follow path";
        _isNavigating = true;
        _polylines.clear();
        _polylines.add(Polyline(polylineId: const PolylineId("route"), width: 6, color: damageCount > 0 ? Colors.orange : Colors.blue, points: polylineCoords));
        _markers.add(Marker(markerId: const MarkerId("dest"), position: LatLng(destLat, destLng)));
      });

      if (damageCount > 0) _speak("Route found, but contains $damageCount reported issues.");
      else _speak("Clear route found.");

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngBounds(_boundsFromLatLngList(polylineCoords), 80));
      _startTrackingMovement();
    } catch (e) {
      _speak("Route error.");
    }
  }

  void _startTrackingMovement() {
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)).listen((Position position) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _checkProximityToNextStep(position);
      _checkProximityToDamage(position);
    });
  }

  void _checkProximityToNextStep(Position userPos) {
    if (_navigationSteps.isEmpty) return;
    if (Geolocator.distanceBetween(userPos.latitude, userPos.longitude, _navigationSteps[0].endLocation.latitude, _navigationSteps[0].endLocation.longitude) < 20) {
      setState(() {
        _navigationSteps.removeAt(0);
        if (_navigationSteps.isNotEmpty) {
          _currentInstruction = _navigationSteps[0].instruction;
          _speak("In 20 meters, $_currentInstruction");
        } else {
          _currentInstruction = "Arrived";
          _speak("You have arrived");
          _stopNavigation();
        }
      });
    }
  }

  void _stopNavigation() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) { x0 = x1 = latLng.latitude; y0 = y1 = latLng.longitude; } 
      else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0!) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  Future<void> _initializeLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    setState(() { _currentPosition = LatLng(pos.latitude, pos.longitude); });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showModeSelector());
  }

  Future<void> _showModeSelector() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(title: const Text("Select User Mode"), content: Column(mainAxisSize: MainAxisSize.min, children: [_modeButton(ctx, UserMode.voice, "Voice (Blind)", Icons.record_voice_over), _modeButton(ctx, UserMode.wheelchair, "Wheelchair", Icons.wheelchair_pickup), _modeButton(ctx, UserMode.standard, "Standard", Icons.person)])),
    );
  }

  Widget _modeButton(BuildContext ctx, UserMode mode, String label, IconData icon) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.teal), icon: Icon(icon, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white)), onPressed: () {
      setState(() => _selectedMode = mode);
      Navigator.pop(ctx);
      _updateMarkers();
      if (mode == UserMode.voice) _startVoiceModeSequence();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accessible Nav"), backgroundColor: Colors.teal, actions: [IconButton(icon: const Icon(Icons.settings_accessibility), onPressed: _showModeSelector)]),
      body: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.amber.withOpacity(0.2), child: Center(child: Text("Mode: ${_selectedMode.name.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)))),
          Expanded(
            child: Stack(
              children: [
                _currentPosition == null ? const Center(child: CircularProgressIndicator()) : GoogleMap(initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 16), myLocationEnabled: true, polylines: _polylines, markers: _markers, onMapCreated: (c) => _mapController.complete(c)),
                if (!_isNavigating)
                  Positioned(top: 10, left: 15, right: 15, child: Column(children: [Container(color: Colors.white, child: TextField(controller: _destinationController, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: "Where to?", suffixIcon: IconButton(icon: Icon(_selectedMode == UserMode.voice ? Icons.mic : Icons.search), onPressed: () { if (_selectedMode == UserMode.voice) _handleMicPress(); else _calculateRoute(_destinationController.text); })))), if (_placeSuggestions.isNotEmpty) Container(color: Colors.white, height: 200, child: ListView.builder(itemCount: _placeSuggestions.length, itemBuilder: (context, index) => ListTile(title: Text(_placeSuggestions[index]['description']), onTap: () { _destinationController.text = _placeSuggestions[index]['description']; _calculateRoute(_destinationController.text); })))])),
                if (_isNavigating)
                  Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(20), color: Colors.white, child: Column(children: [Text(_currentInstruction, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), ElevatedButton(onPressed: () { setState(() { _isNavigating = false; _stopNavigation(); _polylines.clear(); }); }, child: const Text("Exit"))]))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}