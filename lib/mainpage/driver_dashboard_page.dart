import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../auth/login_page.dart';
import '../mainpage/driver_live_map_page.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  StreamSubscription<Position>? _positionSub;
  bool _loading = false;
  bool _tripActive = false;

  User get _user => _auth.currentUser!;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _uploadSelfie(XFile file) async {
    return _cloudinary.uploadDriverSelfie(
      file: file,
      driverUid: _user.uid,
      dayKey: _firestore.todayKey(),
    );
  }

  Future<void> _checkIn({required String areaName}) async {
    try {
      setState(() => _loading = true);
      final selfie = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1440,
      );
      if (selfie == null) {
        await _showMessage('Check-in cancelled.');
        return;
      }

      final pos = await _getCurrentPosition();
      final selfieUrl = await _uploadSelfie(selfie);
      await _firestore.submitDriverCheckIn(
        driverUid: _user.uid,
        driverName: _user.displayName ?? _user.email ?? 'Driver',
        areaName: areaName,
        selfieUrl: selfieUrl,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      await _showMessage(
        'Check-in successful. You are marked present for today.',
      );
    } catch (e) {
      await _showMessage('Check-in failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startTrip({
    required String areaName,
    double? targetLat,
    double? targetLng,
  }) async {
    if (_tripActive) return;
    try {
      setState(() => _loading = true);

      var effectiveTargetLat = targetLat;
      var effectiveTargetLng = targetLng;
      if (effectiveTargetLat == null || effectiveTargetLng == null) {
        final latestAssignment = await _firestore
            .watchTodayDriverAssignment(_user.uid)
            .first;
        effectiveTargetLat = (latestAssignment?['targetLat'] as num?)
            ?.toDouble();
        effectiveTargetLng = (latestAssignment?['targetLng'] as num?)
            ?.toDouble();
      }

      await _firestore.setDriverTripStatus(
        driverUid: _user.uid,
        status: 'active_trip',
      );

      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 15,
            ),
          ).listen((position) {
            _firestore.updateDriverLiveLocation(
              driverUid: _user.uid,
              driverName: _user.displayName ?? _user.email ?? 'Driver',
              areaName: areaName,
              latitude: position.latitude,
              longitude: position.longitude,
              onDuty: true,
              targetLat: effectiveTargetLat,
              targetLng: effectiveTargetLng,
            );
          });

      setState(() => _tripActive = true);
      await _showMessage(
        effectiveTargetLat != null && effectiveTargetLng != null
            ? 'Trip started. Live GPS + destination route is active.'
            : 'Trip started. Live GPS is active (destination not set).',
      );
    } catch (e) {
      await _showMessage('Failed to start trip: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _stopTrip({
    required String areaName,
    double? targetLat,
    double? targetLng,
  }) async {
    try {
      setState(() => _loading = true);
      await _positionSub?.cancel();
      _positionSub = null;
      final pos = await _getCurrentPosition();
      await _firestore.updateDriverLiveLocation(
        driverUid: _user.uid,
        driverName: _user.displayName ?? _user.email ?? 'Driver',
        areaName: areaName,
        latitude: pos.latitude,
        longitude: pos.longitude,
        onDuty: false,
        targetLat: targetLat,
        targetLng: targetLng,
      );
      await _firestore.setDriverTripStatus(
        driverUid: _user.uid,
        status: 'completed',
      );
      setState(() => _tripActive = false);
      await _showMessage('Trip completed. GPS tracking stopped.');
    } catch (e) {
      await _showMessage('Failed to stop trip: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A5D4A),
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _positionSub?.cancel();
              await _auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestore.watchTodayDriverAssignment(_user.uid),
        builder: (context, snapshot) {
          final assignment = snapshot.data;
          final areaName =
              (assignment?['areaName'] as String?) ?? 'Unassigned Area';
          final status = (assignment?['status'] as String?) ?? 'assigned';
          final targetLat = (assignment?['targetLat'] as num?)?.toDouble();
          final targetLng = (assignment?['targetLng'] as num?)?.toDouble();
          final targetPoint = (targetLat != null && targetLng != null)
              ? ll.LatLng(targetLat, targetLng)
              : null;
          final canCheckin = assignment != null && status == 'assigned';
          final hasCheckedIn =
              status == 'checked_in' ||
              status == 'active_trip' ||
              status == 'completed';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today Assignment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Area: $areaName',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      assignment == null
                          ? 'No assignment found for today. Ask admin to assign route.'
                          : 'Status: ${status.replaceAll('_', ' ')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: assignment == null
                            ? Colors.red.shade700
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7C59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading || !canCheckin
                    ? null
                    : () => _checkIn(areaName: areaName),
                icon: const Icon(Icons.verified_user),
                label: Text(
                  _loading
                      ? 'Please wait...'
                      : 'Driver Check-In (Selfie + GPS)',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tripActive
                      ? Colors.red.shade700
                      : const Color(0xFF2F5D7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading || !hasCheckedIn
                    ? null
                    : () => _tripActive
                          ? _stopTrip(
                              areaName: areaName,
                              targetLat: targetLat,
                              targetLng: targetLng,
                            )
                          : _startTrip(
                              areaName: areaName,
                              targetLat: targetLat,
                              targetLng: targetLng,
                            ),
                icon: Icon(
                  _tripActive ? Icons.stop_circle : Icons.play_circle_fill,
                ),
                label: Text(
                  _tripActive ? 'Stop Trip & GPS' : 'Start Trip & GPS',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A5D4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: !hasCheckedIn
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverLiveMapPage(
                              driverUid: _user.uid,
                              areaName: areaName,
                              targetPoint: targetPoint,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.map),
                label: const Text('Open Live Trip Map'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Flow: Assignment -> Check-In -> Start Trip -> Live GPS -> Stop Trip',
                style: TextStyle(
                  color: Color(0xFF667066),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
