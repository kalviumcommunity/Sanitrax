import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../services/truck_location_service.dart';

class SanitraxLiveRouteMap extends StatefulWidget {
  const SanitraxLiveRouteMap({super.key});

  @override
  State<SanitraxLiveRouteMap> createState() => _SanitraxLiveRouteMapState();
}

class _SanitraxLiveRouteMapState extends State<SanitraxLiveRouteMap> {
  final MapController _mapController = MapController();
  final TruckLocationService truckService = TruckLocationService();

  List<LatLng> routePoints = [];

  LatLng truckPosition = const LatLng(11.1271, 78.6569);
  LatLng previousPosition = const LatLng(11.1271, 78.6569);

  double truckRotation = 0.0;

  bool isLoading = true;
  bool mapReady = false;

  final LatLng start = const LatLng(11.1271, 78.6569);
  final LatLng destination = const LatLng(11.1315, 78.6620);

  StreamSubscription? truckSubscription;

  @override
  void initState() {
    super.initState();

    fetchRoute();

    /// Listen to Firebase live truck location
    truckSubscription = truckService.getTruckLocationStream().listen((
      position,
    ) {
      final bearing = _calculateBearing(previousPosition, position);

      setState(() {
        previousPosition = truckPosition;
        truckPosition = position;
        truckRotation = bearing - (math.pi / 2);
      });

      if (mapReady) {
        _mapController.move(position, 16.5);
      }
    });
  }

  Future<void> fetchRoute() async {
    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};"
        "${destination.longitude},${destination.latitude}"
        "?overview=full&geometries=geojson";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final coords =
            data["routes"][0]["geometry"]["coordinates"] as List<dynamic>;

        List<LatLng> points = coords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();

        if (mounted) {
          setState(() {
            routePoints = points;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double _calculateBearing(LatLng p1, LatLng p2) {
    final lat1 = p1.latitude * math.pi / 180;
    final lon1 = p1.longitude * math.pi / 180;

    final lat2 = p2.latitude * math.pi / 180;
    final lon2 = p2.longitude * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  @override
  void dispose() {
    truckSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5E6F52)),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,

                  options: MapOptions(
                    initialCenter: start,
                    initialZoom: 16,
                    maxZoom: 18,
                    minZoom: 12,

                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom,
                    ),

                    onMapReady: () {
                      mapReady = true;
                    },
                  ),

                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      retinaMode: RetinaMode.isHighDensity(context),
                      tileProvider: CancellableNetworkTileProvider(),
                    ),

                    /// Route
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 8,
                          color: const Color(0xFF3A5F44).withOpacity(0.3),
                        ),

                        Polyline(
                          points: routePoints,
                          strokeWidth: 4,
                          color: const Color(0xFF3A5F44),
                        ),
                      ],
                    ),

                    /// Markers
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints.isNotEmpty
                              ? routePoints.last
                              : destination,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ),

                        Marker(
                          point: truckPosition,
                          width: 60,
                          height: 60,
                          rotate: false,
                          child: Transform.rotate(
                            angle: truckRotation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 15,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Color(0xFF3A5F44),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                /// Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 10, color: Colors.black12),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ),

                /// ETA Card
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E6F52),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E6F52).withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ESTIMATED ARRIVAL",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "10:20 – 10:35",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.route,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Route Status",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    "West Village • Sector 4",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
