import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../services/firestore_service.dart';
import '../services/map_config.dart';
import '../services/routing_service.dart';

class AdminLiveTrackingMapPage extends StatefulWidget {
  const AdminLiveTrackingMapPage({super.key});

  @override
  State<AdminLiveTrackingMapPage> createState() =>
      _AdminLiveTrackingMapPageState();
}

class _AdminLiveTrackingMapPageState extends State<AdminLiveTrackingMapPage> {
  final FirestoreService _firestore = FirestoreService();
  final RoutingService _routingService = RoutingService();
  final MapController _mapController = MapController();

  List<ll.LatLng> _routeLine = <ll.LatLng>[];
  String _routeKey = '';
  String? _selectedArea;
  String? _selectedDriverId;
  bool _mapIsReady = false;
  final double _zoom = 15.5;

  Future<void> _ensureRouteFor({
    required ll.LatLng driver,
    required ll.LatLng destination,
  }) async {
    final key =
        '${driver.latitude},${driver.longitude}|${destination.latitude},${destination.longitude}';
    if (key == _routeKey) {
      return;
    }
    _routeKey = key;
    final points = await _routingService.getRoutePoints(
      origin: driver,
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A5D4A),
        title: const Text(
          'Admin Live Route',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.streamActiveDriversToday(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load live drivers: ${snapshot.error}'),
            );
          }

          final drivers = snapshot.data ?? <Map<String, dynamic>>[];
          if (drivers.isEmpty) {
            return const Center(
              child: Text(
                'No active driver trip right now. Ask driver to start GPS.',
              ),
            );
          }

          final areas =
              drivers
                  .map((d) => (d['areaName']?.toString() ?? '').trim())
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          final selectedArea =
              (_selectedArea != null && areas.contains(_selectedArea))
              ? _selectedArea
              : (areas.isNotEmpty ? areas.first : null);

          final areaDrivers = selectedArea == null
              ? drivers
              : drivers
                    .where(
                      (d) => (d['areaName']?.toString() ?? '') == selectedArea,
                    )
                    .toList();

          final selectedDriverId =
              (_selectedDriverId != null &&
                  areaDrivers.any((d) => d['id'] == _selectedDriverId))
              ? _selectedDriverId
              : (areaDrivers.isNotEmpty
                    ? areaDrivers.first['id']?.toString()
                    : null);

          if (areaDrivers.isEmpty || selectedDriverId == null) {
            return const Center(
              child: Text('No active drivers available for the selected area.'),
            );
          }

          final active = areaDrivers.firstWhere(
            (d) => d['id']?.toString() == selectedDriverId,
            orElse: () => areaDrivers.first,
          );

          final lat = (active['latitude'] as num?)?.toDouble();
          final lng = (active['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) {
            return const Center(child: Text('Invalid driver location data'));
          }

          final driverPoint = ll.LatLng(lat, lng);
          final targetLat = (active['targetLat'] as num?)?.toDouble();
          final targetLng = (active['targetLng'] as num?)?.toDouble();
          final hasTarget = targetLat != null && targetLng != null;
          final targetPoint = hasTarget
              ? ll.LatLng(targetLat, targetLng)
              : null;

          if (targetPoint != null) {
            _ensureRouteFor(driver: driverPoint, destination: targetPoint);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _mapIsReady) {
              _mapController.move(driverPoint, _zoom);
            }
          });

          final markers = <Marker>[
            Marker(
              point: driverPoint,
              width: 54,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 30,
                  color: Color(0xFF3E5E4B),
                ),
              ),
            ),
          ];
          if (targetPoint != null) {
            markers.add(
              Marker(
                point: targetPoint,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.location_pin,
                  color: Color(0xFFEF5350),
                  size: 40,
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: driverPoint,
                  initialZoom: _zoom,
                  onMapReady: () {
                    _mapIsReady = true;
                    _mapController.move(driverPoint, _zoom);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.osmTileUrl,
                    userAgentPackageName: MapConfig.userAgentPackageName,
                  ),
                  if (hasTarget && _routeLine.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routeLine,
                          color: const Color(0xFF3E5E4B),
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedArea,
                        decoration: const InputDecoration(
                          labelText: 'Select Area',
                          isDense: true,
                        ),
                        items: areas
                            .map(
                              (area) => DropdownMenuItem<String>(
                                value: area,
                                child: Text(
                                  area,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedArea = value;
                            _selectedDriverId = null;
                            _routeLine = <ll.LatLng>[];
                            _routeKey = '';
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Select Driver',
                          isDense: true,
                        ),
                        items: areaDrivers
                            .map(
                              (driver) => DropdownMenuItem<String>(
                                value: driver['id']?.toString(),
                                child: Text(
                                  '${driver['driverName'] ?? 'Driver'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDriverId = value;
                            _routeLine = <ll.LatLng>[];
                            _routeKey = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
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
                        'Realtime Driver Tracking',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${active['driverName'] ?? 'Driver'} • ${active['areaName'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTarget
                            ? 'Route shown from driver to destination'
                            : 'No destination set for this driver yet',
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
