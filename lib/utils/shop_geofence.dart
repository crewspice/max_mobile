import 'package:geolocator/geolocator.dart';

/// How close the driver's phone must be to their assigned truck's
/// last-reported position to count as "with the truck" (miles).
const double kNearTruckThresholdMiles = 0.5;

const double _metersPerMile = 1609.344;

/// Same haversine distance geolocator already uses internally
/// (Geolocator.distanceBetween), just converted to miles so it lines up
/// with the mile-based thresholds used on the backend (RouteService's
/// distanceBetweenMiles/isNearStop).
double distanceBetweenMiles(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  return meters / _metersPerMile;
}

/// Returns the phone's current position, or null if permission is denied
/// or the position can't be determined. Callers should treat null as
/// "not close" (fail closed) rather than revealing anything on error.
Future<Position?> getCurrentPosition() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  } catch (_) {
    return null;
  }
}
