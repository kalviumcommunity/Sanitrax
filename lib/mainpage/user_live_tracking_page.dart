import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../services/firestore_service.dart';
import '../services/map_config.dart';
import '../services/routing_service.dart';

class UserLiveTrackingPage extends StatefulWidget {
  const UserLiveTrackingPage({super.key});

  @override
  State<UserLiveTrackingPage> createState() => _UserLiveTrackingPageState();
}

class _UserLiveTrackingPageState extends State<UserLiveTrackingPage> {
  final RoutingService _routingService = RoutingService();
  ll.LatLng? _userPoint;
  bool _loadingLocation = true;
  List<ll.LatLng> _routeLine = <ll.LatLng>[];
  String _routeKey = '';

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() => _loadingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _userPoint = ll.LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _ensureRouteFor({
    required ll.LatLng origin,
    required ll.LatLng destination,
  }) async {
    final key =
        '${origin.latitude},${origin.longitude}|${destination.latitude},${destination.longitude}';
    if (key == _routeKey) {
      return;
    }
    _routeKey = key;
    final points = await _routingService.getRoutePoints(
      origin: origin,
      destination: destination,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _routeLine = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A5D4A),
        title: const Text(
          'Track Your Sanitrax Truck',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.streamActiveDriversToday(),
        builder: (context, snapshot) {
          final drivers = snapshot.data ?? <Map<String, dynamic>>[];
          if (_loadingLocation &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (drivers.isEmpty) {
            return const Center(
              child: Text('No active Sanitrax truck is on duty right now.'),
            );
          }

          Map<String, dynamic> selected = drivers.first;
          if (_userPoint != null && drivers.length > 1) {
            final distance = ll.Distance();
            selected = drivers.reduce((a, b) {
              final aPoint = ll.LatLng(
                (a['latitude'] as num).toDouble(),
                (a['longitude'] as num).toDouble(),
              );
              final bPoint = ll.LatLng(
                (b['latitude'] as num).toDouble(),
                (b['longitude'] as num).toDouble(),
              );
              final da = distance(_userPoint!, aPoint);
              final db = distance(_userPoint!, bPoint);
              return da <= db ? a : b;
            });
          }

          final driverPoint = ll.LatLng(
            (selected['latitude'] as num).toDouble(),
            (selected['longitude'] as num).toDouble(),
          );
          final driverName = (selected['driverName'] as String?) ?? 'Driver';
          final areaName = (selected['areaName'] as String?) ?? 'Assigned area';
          final updatedAt = selected['updatedAt'];
          final updatedText = updatedAt is Timestamp
              ? TimeOfDay.fromDateTime(updatedAt.toDate()).format(context)
              : '--:--';

          final markers = <Marker>[
            Marker(
              point: driverPoint,
              width: 58,
              height: 58,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Color(0xFF3D5F4A),
                  size: 30,
                ),
              ),
            ),
          ];

          if (_userPoint != null) {
            markers.add(
              Marker(
                point: _userPoint!,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.person_pin_circle,
                  size: 40,
                  color: Color(0xFFEF5350),
                ),
              ),
            );
            _ensureRouteFor(origin: _userPoint!, destination: driverPoint);
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _userPoint ?? driverPoint,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.osmTileUrl,
                    userAgentPackageName: MapConfig.userAgentPackageName,
                  ),
                  if (_routeLine.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routeLine,
                          color: const Color(0xFF4A5D4A),
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5D4A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Live Driver Tracking',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$driverName • $areaName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated at $updatedText',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
