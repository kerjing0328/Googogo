import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Services
import '../../services/location_service.dart';
import '../../services/navigation_service.dart';
import '../../services/tts_service.dart';
import '../../services/navigation_firebase_service.dart';

// Models
import '../../models/route_option.dart';
import '../../models/route_step.dart';
import '../../models/damage.dart';

// Widgets
import '../../widgets/navigation/mode_selector_dialog.dart';
import '../../widgets/navigation/damage_info_card.dart';
import '../../widgets/navigation/location_search_bar.dart';
import '../../widgets/navigation/map_controls.dart';
import '../../widgets/navigation/navigation_overlay.dart';
import '../../widgets/navigation/route_sheet.dart';

// Utils
import '../../utils/map_utils.dart';

class OkuMapScreen extends StatefulWidget {
  const OkuMapScreen({super.key});

  @override
  State<OkuMapScreen> createState() => _OkuMapScreenState();
}

class _OkuMapScreenState extends State<OkuMapScreen> {
  final String _currentUserId = "navigator_demo_user";

  // Services
  final NavigationService _navService = NavigationService();
  late final NavigationFirebaseService _firebaseService;
  final TtsService _tts = TtsService();
  final Completer<GoogleMapController> _mapController = Completer();

  // Input controllers
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  // State
  UserMode _selectedMode = UserMode.standard;
  LatLng? _currentPosition;
  double _currentHeading = 0.0;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Damage> _damages = [];

  Damage? _selectedDamage;
  bool _showDamageCard = false;
  List<RouteOption> _routeOptions = [];
  RouteOption? _selectedRoute;
  bool _isRouteSelectionMode = false;
  bool _isNavigating = false;
  String _currentInstruction = "";
  EdgeInsets _mapPadding = EdgeInsets.zero;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<Damage>>? _damageSubscription;
  final Set<String> _alertedIds = {};

  @override
  void initState() {
    super.initState();
    _firebaseService = NavigationFirebaseService(userId: _currentUserId);
    _initializeLocation();
    _listenToWalkwayDamage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showModeSelector());
  }

  @override
  void dispose() {
    _stopNavigation();
    _damageSubscription?.cancel();
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  // --- Initialization ---
  Future<void> _initializeLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _currentHeading = pos.heading;
      });
      final c = await _mapController.future;
      c.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));
    } catch (e) {}
  }

  void _listenToWalkwayDamage() {
    _damageSubscription = _firebaseService.watchWalkwayDamage().listen((
      damages,
    ) {
      setState(() {
        _damages = damages;
        _updateMarkers();
      });
    });
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};

    for (var damage in _damages) {
      double hue = BitmapDescriptor.hueGreen;
      if (damage.severity >= 4) hue = BitmapDescriptor.hueOrange;
      if (damage.severity >= 8) hue = BitmapDescriptor.hueRed;

      newMarkers.add(
        Marker(
          markerId: MarkerId(damage.id),
          position: damage.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            setState(() {
              _selectedDamage = damage;
              _showDamageCard = true;
            });
          },
        ),
      );
    }

    if (_selectedRoute != null && _selectedRoute!.steps.isNotEmpty) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _selectedRoute!.steps.last.endLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() => _markers = newMarkers);
  }

  // --- Map Controls ---
  Future<void> _zoomIn() async {
    (await _mapController.future).animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    (await _mapController.future).animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _recenterMap() async {
    if (_currentPosition == null) return;
    final c = await _mapController.future;
    if (_isNavigating) {
      c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 20.0,
            tilt: 50.0,
            bearing: 0.0,
          ),
        ),
      );
    } else {
      c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 16.0),
        ),
      );
    }
  }

  // --- Routing ---
  Future<void> _findRoutes() async {
    if (_destController.text.isEmpty) return;
    FocusScope.of(context).unfocus();

    LatLng start = _currentPosition!;
    if (_originController.text.isNotEmpty) {
      try {
        final locs = await locationFromAddress(_originController.text);
        if (locs.isNotEmpty) {
          start = LatLng(locs.first.latitude, locs.first.longitude);
        }
      } catch (e) {
        return;
      }
    }

    _speak("Finding safe routes...");

    try {
      final results = await _navService.calculateRoutes(
        start,
        _destController.text,
      );
      List<RouteOption> options = [];
      for (var r in results) {
        options.add(_scoreRoute(r));
      }
      // Smart sorting
      options.sort((a, b) {
        if (_selectedMode == UserMode.wheelchair) {
          bool aBad = a.issuesPerStep.values.any(
            (list) => list.any(
              (i) => [
                'HOLE',
                'HAZARDS',
                'OBSTACLE',
                'NARROW',
                'CRACK',
                'NO_PATH',
                'OTHER',
              ].contains(i),
            ),
          );
          bool bBad = b.issuesPerStep.values.any(
            (list) => list.any(
              (i) => [
                'HOLE',
                'HAZARDS',
                'OBSTACLE',
                'NARROW',
                'CRACK',
                'NO_PATH',
                'OTHER',
              ].contains(i),
            ),
          );
          if (aBad != bBad) return aBad ? 1 : -1;
          return a.safetyScore.compareTo(b.safetyScore);
        } else if (_selectedMode == UserMode.standard) {
          bool aBlocked = a.issuesPerStep.values.any(
            (list) => list.contains('OBSTACLE'),
          );
          bool bBlocked = b.issuesPerStep.values.any(
            (list) => list.contains('OBSTACLE'),
          );
          if (aBlocked != bBlocked) return aBlocked ? 1 : -1;
          return a.safetyScore.compareTo(b.safetyScore);
        } else {
          return a.safetyScore.compareTo(b.safetyScore);
        }
      });

      setState(() {
        _routeOptions = options;
        _isRouteSelectionMode = true;
        _mapPadding = EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.55,
        );
        if (options.isNotEmpty) _previewRoute(options.first);
      });

      if (_selectedMode == UserMode.voice) {
        _speak("Found ${options.length} routes. Showing best route.");
      }
    } catch (e) {
      _speak("No routes found.");
    }
  }

  RouteOption _scoreRoute(Map<String, dynamic> raw) {
    List<LatLng> polyline = raw['polyline'];
    List<RouteStep> steps = raw['steps'];
    int score = 0;
    int issues = 0;
    Map<int, List<String>> stepIssues = {};
    Set<String> contributors = {};

    for (var damage in _damages) {
      String type = damage.damageType.toLowerCase();
      bool isNearRoute = false;

      for (int i = 0; i < polyline.length; i++) {
        if (Geolocator.distanceBetween(
              damage.location.latitude,
              damage.location.longitude,
              polyline[i].latitude,
              polyline[i].longitude,
            ) <
            50) {
          isNearRoute = true;
          break;
        }
      }

      if (isNearRoute) {
        if (type == 'clear') continue;

        if (damage.reporterId.isNotEmpty) {
          contributors.add(damage.reporterId);
        }

        issues++;
        String typeUpper = type.toUpperCase();
        if (_selectedMode == UserMode.wheelchair) {
          if ([
            'NO_PATH',
            'OBSTACLE',
            'HOLE',
            'HAZARDS',
            'NARROW',
            'OTHER',
            'CRACK',
          ].contains(type)) {
            score += 100;
          } else {
            score += 10;
          }
        } else {
          score += 10;
        }

        double minDistance = 99999;
        int nearestStepIndex = -1;
        for (int s = 0; s < steps.length; s++) {
          double d = Geolocator.distanceBetween(
            damage.location.latitude,
            damage.location.longitude,
            steps[s].endLocation.latitude,
            steps[s].endLocation.longitude,
          );
          if (d < minDistance) {
            minDistance = d;
            nearestStepIndex = s;
          }
        }
        if (nearestStepIndex != -1) {
          stepIssues.putIfAbsent(nearestStepIndex, () => []);
          if (!stepIssues[nearestStepIndex]!.contains(typeUpper)) {
            stepIssues[nearestStepIndex]!.add(typeUpper);
          }
        }
      }
    }

    return RouteOption(
      id: DateTime.now().toString(),
      polyline: polyline,
      steps: steps,
      summary: raw['summary'],
      duration: raw['duration'],
      issueCount: issues,
      safetyScore: score,
      issuesPerStep: stepIssues,
      reporterIds: contributors.toList(), 
    );
  }

  void _previewRoute(RouteOption route) {
    setState(() {
      _selectedRoute = route;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('preview'),
          color: _selectedMode == UserMode.wheelchair && route.safetyScore > 50
              ? Colors.red
              : Colors.blue,
          width: 6,
          points: route.polyline,
        ),
      };
      _updateMarkers();
    });
  }

  // --- Navigation ---
  void _startNavigation() async {
    if (_selectedRoute == null) return;
    await _firebaseService.logHelpedReports(
      routeOptions: _routeOptions,
      selectedRoute: _selectedRoute,
      navigatorId: _currentUserId,
    );
    setState(() {
      _isRouteSelectionMode = false;
      _isNavigating = true;
      _mapPadding = const EdgeInsets.only(top: 100, bottom: 20);
      _alertedIds.clear();
      _currentInstruction = _selectedRoute!.steps.first.instruction;
    });

    _speak("Starting navigation.");
    _recenterMap();

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen((pos) {
          setState(() {
            _currentPosition = LatLng(pos.latitude, pos.longitude);
            _currentHeading = pos.heading;
          });

          _mapController.future.then((c) {
            c.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _currentPosition!,
                  zoom: 20.0,
                  tilt: 50.0,
                  bearing: 0.0,
                ),
              ),
            );
          });

          _checkProximityToNextStep(pos);
          _checkProximityToDamage(pos);
        });
  }

  void _stopNavigation() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isNavigating = false;
      _polylines.clear();
      _mapPadding = EdgeInsets.zero;
    });
    _recenterMap();
  }

  void _checkProximityToDamage(Position pos) {
    for (var damage in _damages) {
      if (damage.damageType.toLowerCase() == 'clear') continue;
      double dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        damage.location.latitude,
        damage.location.longitude,
      );
      if (dist < 15 && !_alertedIds.contains(damage.id)) {
        _alertedIds.add(damage.id);
        _speak("Caution. ${damage.damageType} ahead.");
      }
    }
  }

  void _checkProximityToNextStep(Position pos) {
    if (_selectedRoute!.steps.isEmpty) return;
    double dist = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      _selectedRoute!.steps.first.endLocation.latitude,
      _selectedRoute!.steps.first.endLocation.longitude,
    );
    if (dist < 15) {
      setState(() {
        _selectedRoute!.steps.removeAt(0);
        if (_selectedRoute!.steps.isNotEmpty) {
          _currentInstruction = _selectedRoute!.steps.first.instruction;
          _speak(_currentInstruction);
        } else {
          _speak("You have arrived.");
          _stopNavigation();
        }
      });
    }
  }

  Future<void> _speak(String text) async {
    if (_selectedMode == UserMode.voice) {
      await _tts.speak(text);
    }
  }

  void _showModeSelector() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ModeSelectorDialog(
        onModeSelected: (mode) {
          setState(() => _selectedMode = mode);
          if (mode == UserMode.voice) _speak("Voice mode active.");
          _updateMarkers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.55;
    final double controlsBottom = _isRouteSelectionMode
        ? sheetHeight + 10
        : 100;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(3.14, 101.68),
              zoom: 16,
            ),
            padding: _mapPadding,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (c) => _mapController.complete(c),
            onTap: (_) => setState(() => _showDamageCard = false),
          ),

          // Search bar (when not navigating or selecting route)
          if (!_isNavigating && !_isRouteSelectionMode)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: LocationSearchBar(
                  originController: _originController,
                  destController: _destController,
                  selectedMode: _selectedMode,
                  onFindRoutes: _findRoutes,
                  onSpeak: _speak,
                ),
              ),
            ),

          // Map controls (zoom/recenter)
          Positioned(
            bottom: controlsBottom,
            right: 15,
            child: MapControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onRecenter: _recenterMap,
            ),
          ),

          // Mode selection button
          if (!_isNavigating && !_isRouteSelectionMode)
            Positioned(
              bottom: 30,
              left: 15,
              child: FloatingActionButton(
                heroTag: "mode_btn",
                backgroundColor: Colors.white,
                child: Icon(getModeIcon(_selectedMode), color: Colors.teal),
                onPressed: _showModeSelector,
              ),
            ),

          // Route selection sheet
          if (_isRouteSelectionMode)
            RouteSheet(
              routes: _routeOptions,
              selectedRoute: _selectedRoute,
              onPreviewRoute: _previewRoute,
              onStartNavigation: _startNavigation,
              onClose: () {
                setState(() {
                  _isRouteSelectionMode = false;
                  _mapPadding = EdgeInsets.zero;
                  _polylines.clear();
                });
              },
            ),

          if (_isNavigating)
            NavigationOverlay(
              instruction: _currentInstruction,
              onStop: _stopNavigation,
            ),

          if (_showDamageCard && _selectedDamage != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: DamageInfoCard(
                damage: _selectedDamage!,
                onClose: () => setState(() => _showDamageCard = false),
              ),
            ),
        ],
      ),
    );
  }
}
