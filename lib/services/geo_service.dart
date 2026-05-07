import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

class GeoService {
  /// Emits true/false when the user crosses the geofence boundary.
  /// - Checks current position immediately on subscribe (no cold-start delay)
  /// - debounceTime BEFORE distinct so rapid oscillation is smoothed first
  /// - 30-second debounce (was 2 min — too long for a real gym app)
  static Stream<bool> watchGeofence({
    required double gymLat,
    required double gymLng,
    required double radiusMeters,
  }) {
    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    // Prepend current position so we get an immediate reading on start
    final initialPosition = Stream.fromFuture(
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).catchError((_) => Future<Position>.error('no position')),
    ).handleError((_) {});

    return initialPosition
        .mergeWith([positionStream])
        .map((pos) =>
            Geolocator.distanceBetween(
                pos.latitude, pos.longitude, gymLat, gymLng) <=
            radiusMeters)
        .debounceTime(const Duration(seconds: 30))
        .distinct();
  }

  /// Returns true if location permission is granted.
  /// Opens app settings if permanently denied.
  static Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  static Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }
}
