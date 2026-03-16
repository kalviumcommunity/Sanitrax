import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'map_config.dart';

class RoutingService {
  Future<List<ll.LatLng>> getRoutePoints({
    required ll.LatLng origin,
    required ll.LatLng destination,
  }) async {
    return _osrmRoute(origin: origin, destination: destination);
  }

  Future<List<ll.LatLng>> _osrmRoute({
    required ll.LatLng origin,
    required ll.LatLng destination,
  }) async {
    try {
      final coords =
          '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final uri = Uri.parse(
        '${MapConfig.osrmRouteBaseUrl}/$coords?overview=full&geometries=geojson',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return <ll.LatLng>[];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return <ll.LatLng>[];
      }

      final geometry =
          (routes.first as Map<String, dynamic>)['geometry']
              as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        return <ll.LatLng>[];
      }

      return coordinates.map((point) {
        final pair = point as List<dynamic>;
        return ll.LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return <ll.LatLng>[];
    }
  }
}
