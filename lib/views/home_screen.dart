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

  const HomeScreen({
    super.key,
    required this.currentUserId,
    required this.userName,
    required this.truckId,
    this.maintenanceOnly = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Unlocked only by real production conditions - active route, truck away
  // from shop, phone GPS within range of the truck. No dev/debug bypass;
  // this check runs the same way in every build.
  bool _driverChatUnlocked = false;
  Timer? _driverChatUnlockTimer;

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

  Future<void> _refreshDriverChatUnlockStatus() async {
    bool unlocked = false;

    try {
      final status = await ApiService().fetchShopStatus(widget.currentUserId);
      final position = await shop_geofence.getCurrentPosition();

      final hasActiveRoute = status['hasActiveRoute'] == true;
      final truckNearShop = status['truckNearShop'] == true;
      final truckLat = (status['truckLat'] as num?)?.toDouble();
      final truckLng = (status['truckLng'] as num?)?.toDouble();

      if (hasActiveRoute &&
          !truckNearShop &&
          truckLat != null &&
          truckLng != null &&
          position != null) {
        final distance = shop_geofence.distanceBetweenMiles(
          position.latitude,
          position.longitude,
          truckLat,
          truckLng,
        );
        unlocked = distance <= shop_geofence.kNearTruckThresholdMiles;
      }
    } catch (_) {
      unlocked = false;
    }

    if (mounted && unlocked != _driverChatUnlocked) {
      setState(() => _driverChatUnlocked = unlocked);
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
            ),
            TruckView(
              truckId: widget.truckId,
              driverId: widget.currentUserId,
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