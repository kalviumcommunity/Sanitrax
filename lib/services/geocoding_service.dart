import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

class GeocodingService {
  /// Resolves [query] (e.g. "Anna Nagar, Chennai") to a [ll.LatLng] using
  /// the free Nominatim / OpenStreetMap geocoding API.
  /// Returns null if nothing is found or the request fails.
  Future<ll.LatLng?> geocode(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query.trim(),
        'format': 'json',
        'limit': '1',
        'addressdetails': '0',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Sanitrax/1.0', 'Accept-Language': 'en'},
      );
      if (response.statusCode != 200) return null;
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return ll.LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }
}
