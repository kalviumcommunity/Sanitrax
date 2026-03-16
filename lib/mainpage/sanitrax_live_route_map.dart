import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;

import '../services/map_config.dart';

class SanitraxLiveRouteMap extends StatefulWidget {
  final List<ll.LatLng>? routePoints;
  final bool snapWithOsrm;
  const SanitraxLiveRouteMap({
    super.key,
    this.routePoints,
    this.snapWithOsrm = false,
  });

  @override
  State<SanitraxLiveRouteMap> createState() => _SanitraxLiveRouteMapState();
}

class _SanitraxLiveRouteMapState extends State<SanitraxLiveRouteMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final List<ll.LatLng> _defaultStops = const [
    ll.LatLng(11.1271, 78.6569),
    ll.LatLng(11.1285, 78.6590),
    ll.LatLng(11.1300, 78.6625),
    ll.LatLng(11.1325, 78.6660),
  ];
  late List<ll.LatLng> _routePoints;
  late List<ll.LatLng> _pathPoints;

  AnimationController? _controller;
  late ll.LatLng _truck;
  double _zoom = 15.5;
  final ll.Distance _distance = const ll.Distance();
  double _progress = 0;
  double _totalDistanceMeters = 1;
  bool _arrived = false;
  static const double _assumedSpeedKmph = 24;
  bool _ready = false;
  bool _mapIsReady = false;

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    try {
      final stops = widget.routePoints ?? _defaultStops;
      final decoded = await fetchOsrmRoute(stops);
      _routePoints = decoded;
      if (_routePoints.length < 10) {
        // keep going but warn
        // print
        // ignore: avoid_print
        print(
          'Warning: OSRM returned a short geometry: ${_routePoints.length} points',
        );
      }
      // ignore: avoid_print
      print('OSRM route loaded with ${_routePoints.length} points');
      _pathPoints = _resamplePath(_routePoints, 10.0);
      if (_pathPoints.length < 2) {
        throw Exception('Route path is too short for animation');
      }
      _truck = _pathPoints.first;
      _totalDistanceMeters = _calculatePathDistance(_pathPoints);
      _controller =
          AnimationController(
              vsync: this,
              duration: _durationForDistance(_totalDistanceMeters),
            )
            ..addListener(_onTick)
            ..addStatusListener(_onStatus)
            ..forward();
      setState(() {
        _ready = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print('OSRM route load failed: $e');
      rethrow;
    }
  }

  Future<List<ll.LatLng>> fetchOsrmRoute(List<ll.LatLng> stops) async {
    if (stops.length < 2) {
      throw Exception('At least two stops required');
    }
    final coords = stops.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url =
        '${MapConfig.osrmRouteBaseUrl}/$coords?overview=full&geometries=geojson';
    final uri = Uri.parse(url);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('OSRM HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['routes'] == null || (data['routes'] as List).isEmpty) {
      throw Exception('OSRM: no routes returned');
    }
    final route0 = (data['routes'] as List).first as Map<String, dynamic>;
    final geometry = route0['geometry'] as Map<String, dynamic>;
    final coordsList = geometry['coordinates'] as List<dynamic>;
    final points = <ll.LatLng>[];
    for (final item in coordsList) {
      final pair = item as List<dynamic>;
      final lon = (pair[0] as num).toDouble();
      final lat = (pair[1] as num).toDouble();
      points.add(ll.LatLng(lat, lon));
    }
    return points;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _progress = 1;
      _truck = _pathPoints.last;
      _arrived = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || _arrived) return;
    final totalSegments = _pathPoints.length - 1;
    final raw = controller.value * totalSegments;
    final segment = raw.floor().clamp(0, totalSegments - 1);
    final localT = raw - segment;
    final a = _pathPoints[segment];
    final b = _pathPoints[segment + 1];
    _truck = _interpolate(a, b, localT);
    _progress = controller.value.clamp(0.0, 1.0);
    if (_mapIsReady) {
      _mapController.move(_truck, _zoom);
    }
    if (mounted) setState(() {});
  }

  Duration _durationForDistance(double meters) {
    final seconds = ((meters / 1000) / _assumedSpeedKmph * 3600).round();
    return Duration(seconds: seconds.clamp(12, 180));
  }

  double _calculatePathDistance(List<ll.LatLng> points) {
    if (points.length < 2) return 1;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _distance(points[i], points[i + 1]);
    }
    return total <= 0 ? 1 : total;
  }

  ll.LatLng _interpolate(ll.LatLng a, ll.LatLng b, double t) {
    return ll.LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  List<ll.LatLng> _resamplePath(List<ll.LatLng> pts, double stepMeters) {
    if (pts.length < 2) return pts;
    final out = <ll.LatLng>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      out.add(a);
      final segLen = _distance(a, b);
      if (segLen <= 0) continue;
      final n = (segLen / stepMeters).floor().clamp(0, 10000);
      for (var k = 1; k < n; k++) {
        final t = k / n;
        out.add(_interpolate(a, b, t));
      }
    }
    out.add(pts.last);
    return out;
  }

  List<ll.LatLng> _traveledPoints() {
    if (_pathPoints.length < 2) return _pathPoints;
    final upto = (_progress * (_pathPoints.length - 1)).floor().clamp(
      1,
      _pathPoints.length - 1,
    );
    return _pathPoints.take(upto + 1).toList();
  }

  double _remainingDistanceKm() {
    final remaining = _totalDistanceMeters * (1 - _progress);
    return remaining <= 0 ? 0 : remaining / 1000;
  }

  int _remainingEtaMinutes() {
    final km = _remainingDistanceKm();
    if (km <= 0.01) return 0;
    return ((km / _assumedSpeedKmph) * 60).ceil();
  }

  String _etaText() {
    if (_arrived) return 'Reached';
    final minutes = _remainingEtaMinutes();
    if (minutes <= 1) return '1 min';
    return '$minutes mins';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _pathPoints.first,
            initialZoom: _zoom,
            onMapReady: () {
              _mapIsReady = true;
              _mapController.move(_truck, _zoom);
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.osmTileUrl,
              userAgentPackageName: MapConfig.userAgentPackageName,
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _pathPoints,
                  color: const Color(0xFFBFC8BC),
                  strokeWidth: 7,
                ),
                Polyline(
                  points: _traveledPoints(),
                  color: const Color(0xFF3E5E4B),
                  strokeWidth: 5,
                ),
              ],
            ),
            MarkerLayer(markers: [_destinationMarker(), _truckMarker()]),
          ],
        ),
        Positioned(
          top: 18,
          left: 18,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 10)],
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF5F6F5A)),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        Positioned(bottom: 20, left: 20, right: 20, child: _etaCard()),
      ],
    );
  }

  Marker _truckMarker() {
    return Marker(
      point: _truck,
      width: 54,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x22000000),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF5E6F52),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Marker _destinationMarker() {
    return Marker(
      point: _pathPoints.last,
      width: 42,
      height: 42,
      child: const Icon(Icons.location_pin, size: 40, color: Color(0xFFEF5350)),
    );
  }

  Widget _etaCard() {
    final remainingKm = _remainingDistanceKm();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF5E6F52),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E6F52).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ESTIMATED ARRIVAL',
                style: TextStyle(
                  color: Color(0xFFDCE5D5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  decoration: TextDecoration.none,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8CA188),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _arrived ? 'Arrived' : 'On Route',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _etaText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${remainingKm.toStringAsFixed(1)} km left',
                style: const TextStyle(
                  color: Color(0xFFDCE5D5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Avg speed 24 km/h',
                style: TextStyle(
                  color: Color(0xFFDCE5D5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF8DA08A),
                child: Icon(Icons.route, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Route Status',
                      style: TextStyle(
                        color: Color(0xFFDCE5D5),
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'West Village - Sector 4',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_arrived) ...[
            const SizedBox(height: 12),
            const Text(
              'Truck has reached the destination location.',
              style: TextStyle(
                color: Color(0xFFDCE5D5),
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
