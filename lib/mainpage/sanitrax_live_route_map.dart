import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

class SanitraxLiveRouteMap extends StatefulWidget {
  final List<ll.LatLng>? routePoints;
  const SanitraxLiveRouteMap({super.key, this.routePoints});

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
  late List<ll.LatLng> _stops;
  late List<ll.LatLng> _routePoints;
  late List<ll.LatLng> _pathPoints;

  late final AnimationController _controller;
  late final Animation<double> _t;
  int _segment = 0;
  late ll.LatLng _truck;
  double _bearingRad = 0;
  double _zoom = 15.5;
  final ll.Distance _distance = const ll.Distance();
  late final List<double> _segmentLengths;
  late final double _totalLength;
  static const Duration _baseLoop = Duration(seconds: 12);
  static const double _resampleStepMeters = 15.0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    final stops = widget.routePoints ?? _defaultStops;
    _stops = stops;
    final decoded = await fetchOsrmRoute(stops);
    _routePoints = decoded;
    _pathPoints = _resamplePath(_routePoints, 10.0);
    _truck = _pathPoints.first;
    _computeSegmentMetrics();
    _controller = AnimationController(
      vsync: this,
      duration: _segmentDuration(0),
    );
    _t =
        Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear))
          ..addListener(_onTick)
          ..addStatusListener(_onStatus);
    setState(() {
      _ready = true;
    });
    _controller.forward();
  }

  Future<List<ll.LatLng>> fetchOsrmRoute(List<ll.LatLng> stops) async {
    final coords = stops.map((p) => '${p.longitude},${p.latitude}').join(';');
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('OSRM HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
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
    if (_ready) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      _segment = (_segment + 1) % (_pathPoints.length - 1);
      _controller.duration = _segmentDuration(_segment);
      _controller.forward(from: 0);
    }
  }

  void _onTick() {
    final a = _pathPoints[_segment];
    final b = _pathPoints[_segment + 1];
    final p = _interpolate(a, b, _t.value);
    final prevT = (_t.value - 0.02).clamp(0.0, 1.0);
    final prev = _interpolate(a, b, prevT);
    final bearing = _bearing(prev, p);
    _truck = p;
    _bearingRad = bearing;
    _mapController.move(_truck, _zoom);
    if (mounted) setState(() {});
  }

  void _computeSegmentMetrics() {
    _segmentLengths = <double>[];
    double sum = 0;
    for (var i = 0; i < _pathPoints.length - 1; i++) {
      final d = _distance(_pathPoints[i], _pathPoints[i + 1]);
      _segmentLengths.add(d);
      sum += d;
    }
    _totalLength = sum == 0 ? 1 : sum;
  }

  Duration _segmentDuration(int idx) {
    final frac = _segmentLengths[idx] / _totalLength;
    final ms = (_baseLoop.inMilliseconds * frac).clamp(
      200.0,
      _baseLoop.inMilliseconds.toDouble(),
    );
    return Duration(milliseconds: ms.round());
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

  double _bearing(ll.LatLng a, ll.LatLng b) {
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    var brng = math.atan2(y, x);
    if (brng < 0) brng += 2 * math.pi;
    return brng;
  }

  double _toRad(double d) => d * math.pi / 180.0;

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
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.sanitrax',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _pathPoints,
                  color: const Color(0xFFFFFFFF),
                  strokeWidth: 5,
                  borderStrokeWidth: 0,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (int i = 0; i < _stops.length; i++) _stopMarker(i),
                _truckMarker(),
              ],
            ),
          ],
        ),
        Positioned(bottom: 20, left: 20, right: 20, child: _etaCard()),
      ],
    );
  }

  Marker _truckMarker() {
    return Marker(
      point: _truck,
      width: 46,
      height: 46,
      child: Transform.rotate(
        angle: _bearingRad,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF5E6F52),
            ),
            child: const Icon(
              Icons.local_shipping,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Marker _stopMarker(int i) {
    final isCurrent = i == _segment + 1;
    final isCompleted = i <= _segment;
    final scale = isCurrent
        ? 1.0 + 0.08 * math.sin(DateTime.now().millisecondsSinceEpoch / 120.0)
        : 1.0;
    final Color fill = isCompleted
        ? const Color(0xFF2F4F2E)
        : const Color(0xFF5E6F52);
    final Color border = isCompleted
        ? const Color(0xFF2F4F2E)
        : const Color(0xFFE0E8DA);
    return Marker(
      point: _stops[i],
      width: 22,
      height: 22,
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _etaCard() {
    final progress = (_segment + _t.value) / (_pathPoints.length - 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF5E6F52),
        borderRadius: BorderRadius.circular(30),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ESTIMATED ARRIVAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '12 min',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'On Time',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              Container(
                height: 76,
                width: 76,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'TRACK',
                    style: TextStyle(
                      color: Color(0xFF5E6F52),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Route A • Stop 8 of 12',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
