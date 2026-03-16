import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../services/firestore_service.dart';
import '../services/map_config.dart';
import '../services/routing_service.dart';

class DriverLiveMapPage extends StatefulWidget {
  final String driverUid;
  final String areaName;
  final ll.LatLng? targetPoint;

  const DriverLiveMapPage({
    super.key,
    required this.driverUid,
    required this.areaName,
    this.targetPoint,
  });

  @override
  State<DriverLiveMapPage> createState() => _DriverLiveMapPageState();
}

class _DriverLiveMapPageState extends State<DriverLiveMapPage> {
  final RoutingService _routingService = RoutingService();
  List<ll.LatLng> _routeLine = <ll.LatLng>[];
  String _routeKey = '';

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
          'Driver Live Trip Map',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: firestore.watchDriverLiveLocation(widget.driverUid),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('No live location yet. Start GPS trip first.'),
            );
          }

          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) {
            return const Center(child: Text('Location data unavailable.'));
          }

          final liveTargetLat = (data['targetLat'] as num?)?.toDouble();
          final liveTargetLng = (data['targetLng'] as num?)?.toDouble();
          final effectiveTarget =
              widget.targetPoint ??
              ((liveTargetLat != null && liveTargetLng != null)
                  ? ll.LatLng(liveTargetLat, liveTargetLng)
                  : null);

          final driverPoint = ll.LatLng(lat, lng);
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

          if (effectiveTarget != null) {
            markers.add(
              Marker(
                point: effectiveTarget,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Color(0xFFEF5350),
                ),
              ),
            );
            _ensureRouteFor(origin: driverPoint, destination: effectiveTarget);
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: driverPoint,
                  initialZoom: 16,
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
                          color: const Color(0xFF3D5F4A),
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
                        'Live Trip Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.areaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        effectiveTarget == null
                            ? 'Driver is sharing live GPS location (no destination set)'
                            : 'Driver is sharing live GPS location',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
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
