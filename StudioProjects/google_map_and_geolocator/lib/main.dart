import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const LocationTrackerApp());

class LocationTrackerApp extends StatelessWidget {
  const LocationTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Location Tracker',
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        home: const LocationTrackerPage(),
      );
}

class LocationTrackerPage extends StatefulWidget {
  const LocationTrackerPage({super.key});

  @override
  State<LocationTrackerPage> createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage>
    with WidgetsBindingObserver {
  static const _initialCamera = CameraPosition(target: LatLng(0, 0), zoom: 2);
  static const _markerId = MarkerId('current-location');
  static const _polylineId = PolylineId('tracked-route');

  final Completer<GoogleMapController> _mapController = Completer();
  final List<LatLng> _routePoints = [];
  Timer? _trackingTimer;
  Position? _position;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _firstLocationReceived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTracking();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTracking();
    }
  }

  Future<void> _startTracking() async {
    await _fetchLocation();
    if (!mounted || _errorMessage != null) return;
    _trackingTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchLocation(),
    );
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  Future<void> _fetchLocation() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationException(
          'Location services are disabled. Please enable them and try again.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const _LocationException('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _LocationException(
          'Location permission is permanently denied. Enable it in device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      final lastPoint = _routePoints.isEmpty ? null : _routePoints.last;
      final isNewPoint = lastPoint == null ||
          lastPoint.latitude != point.latitude ||
          lastPoint.longitude != point.longitude;
      setState(() {
        _position = position;
        _isLoading = false;
        _errorMessage = null;
        if (isNewPoint) _routePoints.add(point);
      });
      await _moveCamera(point, firstLocation: !_firstLocationReceived);
      _firstLocationReceived = true;
    } on _LocationException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to get the current location. Please try again.');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _moveCamera(LatLng target, {required bool firstLocation}) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: firstLocation ? 16 : 17),
    ));
  }

  void _showError(String message) {
    if (!mounted) return;
    _stopTracking();
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPoint = _position == null
        ? null
        : LatLng(_position!.latitude, _position!.longitude);
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Location Tracker')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            myLocationButtonEnabled: false,
            markers: currentPoint == null
                ? const {}
                : {
                    Marker(
                      markerId: _markerId,
                      position: currentPoint,
                      infoWindow: InfoWindow(
                        title: 'My current location',
                        snippet: '${currentPoint.latitude.toStringAsFixed(6)}, '
                            '${currentPoint.longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  },
            polylines: _routePoints.length < 2
                ? const {}
                : {
                    Polyline(
                      polylineId: _polylineId,
                      points: _routePoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
            onMapCreated: (controller) async {
              if (!_mapController.isCompleted) _mapController.complete(controller);
              if (currentPoint != null) {
                await _moveCamera(
                  currentPoint,
                  firstLocation: !_firstLocationReceived,
                );
              }
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _startTracking();
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationException implements Exception {
  const _LocationException(this.message);
  final String message;
}
