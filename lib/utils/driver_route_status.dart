import '../services/api_service.dart';
import 'shop_geofence.dart' as shop_geofence;

// Whether the driver is confirmed on-route right now: an active route, the
// truck away from the shop, and the phone's GPS within range of the truck's
// last-reported position. Same check HomeScreen._computeDriverChatUnlock
// uses to unlock Driver Chat - shared here so other features (the cancel
// dialog's fee display) gate on the identical real-world condition.
Future<bool> isDriverOnRoute(String? driverId) async {
  if (driverId == null || driverId.isEmpty) return false;

  try {
    final status = await ApiService().fetchShopStatus(driverId);
    final position = await shop_geofence.getCurrentPosition();

    final hasActiveRoute = status['hasActiveRoute'] == true;
    final truckNearShop = status['truckNearShop'] == true;
    final truckLat = (status['truckLat'] as num?)?.toDouble();
    final truckLng = (status['truckLng'] as num?)?.toDouble();

    if (!hasActiveRoute || truckNearShop || position == null ||
        truckLat == null || truckLng == null) {
      return false;
    }

    final distance = shop_geofence.distanceBetweenMiles(
      position.latitude,
      position.longitude,
      truckLat,
      truckLng,
    );

    return distance <= shop_geofence.kNearTruckThresholdMiles;
  } catch (_) {
    return false;
  }
}
