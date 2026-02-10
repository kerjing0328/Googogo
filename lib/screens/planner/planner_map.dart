import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class PlannerMap extends StatefulWidget {
  const PlannerMap({super.key});

  @override
  State<PlannerMap> createState() => _PlannerMapState();
}

class _PlannerMapState extends State<PlannerMap> {
  final Completer<GoogleMapController> _mapController = Completer();
  
  Set<Marker> _markers = {};
  List<DocumentSnapshot> _allReports = [];
  StreamSubscription? _reportSubscription;
  LatLng _initialPosition = const LatLng(3.1390, 101.6869);
  bool _isLoadingLocation = true;

  String _selectedSeverity = 'All';
  String _selectedState = 'All';
  List<String> _availableStates = ['All'];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _subscribeToReports();
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { if(mounted) setState(() => _isLoadingLocation = false); return; }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { if(mounted) setState(() => _isLoadingLocation = false); return; }
    }
    if (permission == LocationPermission.deniedForever) { if(mounted) setState(() => _isLoadingLocation = false); return; }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      if (_mapController.future != null) {
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14));
      }
    }
  }

  void _subscribeToReports() {
    _reportSubscription = FirebaseFirestore.instance.collection('walkway_damage').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _allReports = snapshot.docs;
          Set<String> states = {'All'};
          for (var doc in snapshot.docs) {
            var data = doc.data();
            if (data.containsKey('state') && data['state'] != null) states.add(data['state']);
          }
          List<String> sortedStates = states.toList()..sort();
          if (sortedStates.contains('All')) { sortedStates.remove('All'); sortedStates.insert(0, 'All'); }
          _availableStates = sortedStates;
        });
        _updateMarkers();
      }
    });
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};
    for (var doc in _allReports) {
      var data = doc.data() as Map<String, dynamic>;
      GeoPoint pos = data['location'];
      String type = data['damage_type'] ?? 'Issue';
      String status = data['status'] ?? 'submitted';
      int severity = data['severity'] is int ? data['severity'] : 0;
      String state = data['state'] ?? 'Unknown';

      if (_selectedState != 'All' && state != _selectedState) continue;
      if (_selectedSeverity == 'Critical (8-10)' && severity < 8) continue;
      if (_selectedSeverity == 'Moderate (4-7)' && (severity < 4 || severity > 7)) continue;
      if (_selectedSeverity == 'Minor (1-3)' && severity > 3) continue;

      double hue;
      if (status == 'resolved') hue = BitmapDescriptor.hueGreen; 
      else if (severity >= 8) hue = BitmapDescriptor.hueRed;
      else if (severity >= 4) hue = BitmapDescriptor.hueOrange;
      else hue = BitmapDescriptor.hueYellow;

      newMarkers.add(Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(pos.latitude, pos.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(title: "$type ($status)", snippet: "Severity: $severity"),
      ));
    }
    setState(() => _markers = newMarkers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoadingLocation 
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12),
                markers: _markers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) {
                  _mapController.complete(c);
                  if (!_isLoadingLocation) c.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14));
                },
              ),

          // FILTER CARD
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_alt, color: Color(0xFF4953B9)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _availableStates.contains(_selectedState) ? _selectedState : 'All',
                        isExpanded: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        items: _availableStates.map((s) => DropdownMenuItem(value: s, child: Text("Region: $s"))).toList(),
                        onChanged: (val) { setState(() { _selectedState = val!; _updateMarkers(); }); },
                      ),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSeverity,
                        isExpanded: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        items: ['All', 'Critical (8-10)', 'Moderate (4-7)', 'Minor (1-3)'].map((s) => DropdownMenuItem(value: s, child: Text("Severity: $s"))).toList(),
                        onChanged: (val) { setState(() { _selectedSeverity = val!; _updateMarkers(); }); },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}