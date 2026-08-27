import 'dart:async';
import 'package:flutter/material.dart';
import 'rental_list_view.dart';
import 'maintenance_view.dart';
import 'maintenance_view.dart';
import 'truck_view.dart';
import 'user_statistics_screen.dart';
import 'user_selection_screen.dart';
import 'completed_stops_screen.dart';
import 'menu_screen.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../utils/shop_geofence.dart' as shop_geofence;
import 'package:google_fonts/google_fonts.dart';


class HomeScreen extends StatefulWidget {
  final String currentUserId;
  final String userName;
  final String? truckId;
  final bool maintenanceOnly;
  final int initialTabIndex;

  const HomeScreen({
    super.key,
    required this.currentUserId,
    required this.userName,
    required this.truckId,
    this.maintenanceOnly = false,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex = widget.maintenanceOnly ? 0 : widget.initialTabIndex;

  // Unlocked only by real production conditions - active route, truck away
  // from shop, phone GPS within range of the truck. No dev/debug bypass;
  // this check runs the same way in every build.
  bool _driverChatUnlocked = false;
  Timer? _driverChatUnlockTimer;

  // Set by the truck-view lift dialog's maintenance shortcut so the newly
  // mounted MaintenanceView picks up the right lift on its first build,
  // then cleared post-frame so revisiting the tab later doesn't keep
  // re-selecting it.
  String? _pendingMaintenanceSerial;

  void _openLiftInMaintenance(String serialNumber) {
    setState(() {
      _selectedIndex = 1;
      _pendingMaintenanceSerial = serialNumber;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _pendingMaintenanceSerial = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshDriverChatUnlockStatus();
    _driverChatUnlockTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _refreshDriverChatUnlockStatus(),
    );
  }

  @override
  void dispose() {
    _driverChatUnlockTimer?.cancel();
    super.dispose();
  }

  // Runs the unlock heuristic and returns everything it computed along the
  // way, without doing anything else - callers decide whether to persist
  // it or just apply the outcome.
  Future<_DriverChatCheck> _computeDriverChatUnlock() async {
    bool unlocked = false;

    bool? hasActiveRoute;
    bool? truckNearShop;
    double? truckLat;
    double? truckLng;
    double? phoneLat;
    double? phoneLng;
    double? distance;
    String? error;

    try {
      final status = await ApiService().fetchShopStatus(widget.currentUserId);
      final position = await shop_geofence.getCurrentPosition();

      hasActiveRoute = status['hasActiveRoute'] == true;
      truckNearShop = status['truckNearShop'] == true;
      truckLat = (status['truckLat'] as num?)?.toDouble();
      truckLng = (status['truckLng'] as num?)?.toDouble();
      phoneLat = position?.latitude;
      phoneLng = position?.longitude;

      if (truckLat != null && truckLng != null && position != null) {
        distance = shop_geofence.distanceBetweenMiles(
          position.latitude,
          position.longitude,
          truckLat,
          truckLng,
        );
      }

      if (hasActiveRoute && !truckNearShop && distance != null) {
        unlocked = distance <= shop_geofence.kNearTruckThresholdMiles;
      }
    } catch (e) {
      unlocked = false;
      error = e.toString();
    }

    return _DriverChatCheck(
      unlocked: unlocked,
      hasActiveRoute: hasActiveRoute,
      truckNearShop: truckNearShop,
      truckLat: truckLat,
      truckLng: truckLng,
      phoneLat: phoneLat,
      phoneLng: phoneLng,
      distanceMiles: distance,
      error: error,
    );
  }

  // Periodic background refresh - just keeps _driverChatUnlocked current so
  // the menu item shows/hides correctly. Not logged: logging only happens
  // when the driver explicitly asks to be assessed (see
  // _assessDriverStatusAndLog), so the debug table stays one row per
  // deliberate check instead of one every 45s.
  Future<void> _refreshDriverChatUnlockStatus() async {
    final result = await _computeDriverChatUnlock();

    if (mounted && result.unlocked != _driverChatUnlocked) {
      setState(() => _driverChatUnlocked = result.unlocked);
    }
  }

  // Triggered by tapping "assess if I'm a driver" in the menu. Runs the same
  // check as the background refresh, but also records the inputs/outcome to
  // the dev-only debug table.
  Future<void> _assessDriverStatusAndLog() async {
    final result = await _computeDriverChatUnlock();

    ApiService().logDriverChatRevealDebug(
      driverId: widget.currentUserId,
      hasActiveRoute: result.hasActiveRoute,
      truckNearShop: result.truckNearShop,
      truckLat: result.truckLat,
      truckLng: result.truckLng,
      phoneLat: result.phoneLat,
      phoneLng: result.phoneLng,
      gpsAvailable: result.phoneLat != null && result.phoneLng != null,
      distanceMiles: result.distanceMiles,
      thresholdMiles: shop_geofence.kNearTruckThresholdMiles,
      unlocked: result.unlocked,
      error: result.error,
    );

    if (mounted && result.unlocked != _driverChatUnlocked) {
      setState(() => _driverChatUnlocked = result.unlocked);
    }
  }

  Future<void> _showMenu() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          currentUserId: widget.currentUserId,
          userName: widget.userName,
          maintenanceOnly: widget.maintenanceOnly,
          driverChatUnlocked: _driverChatUnlocked,
          onAssessDriverStatus: _assessDriverStatusAndLog,
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final bool active = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            height: double.infinity,
            width: double.infinity, // forces full hit area
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: active
                      ? activeColor
                      : activeColor.withOpacity(0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: active
                        ? activeColor
                        : activeColor.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: active
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.maintenanceOnly
        ? <Widget>[
            MaintenanceView(
              currentUserId: widget.currentUserId,
            ),
          ]
        : <Widget>[
            RentalListView(
              driverId: widget.currentUserId,
            ),
            MaintenanceView(
              currentUserId: widget.currentUserId,
              initialSerialNumber: _pendingMaintenanceSerial,
            ),
            TruckView(
              truckId: widget.truckId,
              driverId: widget.currentUserId,
              onOpenLiftMaintenance: _openLiftInMaintenance,
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        foregroundColor: AppColors.red,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.yellow,
                AppColors.green,
                AppColors.red,
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.userName,
            style: GoogleFonts.permanentMarker(
              fontSize: 26, // slightly smaller than header
              // fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.5,
            ),
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.person),
          color: AppColors.yellow,
          tooltip: 'Switch user',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const UserSelectionScreen(),
              ),
              (route) => false,
            );
          },
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onPressed: _showMenu,
          ),
        ],
      ),

      body: pages[_selectedIndex],
      bottomNavigationBar: widget.maintenanceOnly
          ? null
          : SafeArea(
        top: false,
        child: Container(
          height: 70,
          color: AppColors.mainBackground,
          child: Row(
            children: [
              _navItem(
                index: 0,
                icon: Icons.directions_car,
                label: "Routes",
                activeColor: AppColors.yellow,
              ),
              _navItem(
                index: 1,
                icon: Icons.build,
                label: "Maintenance",
                activeColor: AppColors.green,
              ),
              _navItem(
                index: 2,
                icon: Icons.local_shipping,
                label: "Truck",
                activeColor: AppColors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverChatCheck {
  final bool unlocked;
  final bool? hasActiveRoute;
  final bool? truckNearShop;
  final double? truckLat;
  final double? truckLng;
  final double? phoneLat;
  final double? phoneLng;
  final double? distanceMiles;
  final String? error;

  _DriverChatCheck({
    required this.unlocked,
    this.hasActiveRoute,
    this.truckNearShop,
    this.truckLat,
    this.truckLng,
    this.phoneLat,
    this.phoneLng,
    this.distanceMiles,
    this.error,
  });
}