import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class TruckLocationService {
  final DatabaseReference _truckRef = FirebaseDatabase.instance.ref(
    "sanitrax/trucks/truck_01",
  );

  Stream<LatLng> getTruckLocationStream() {
    return _truckRef.onValue.map((event) {
      try {
        final data = event.snapshot.value;
        if (data == null || data is! Map) {
          // Fallback to a default location or re-throw
          return const LatLng(11.1271, 78.6569);
        }

        final lat = (data["latitude"] as num?)?.toDouble() ?? 11.1271;
        final lng = (data["longitude"] as num?)?.toDouble() ?? 78.6569;

        return LatLng(lat, lng);
      } catch (e) {
        debugPrint("Error parsing truck location: $e");
        return const LatLng(11.1271, 78.6569);
      }
    });
  }
}
