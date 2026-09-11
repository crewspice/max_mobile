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
import '../utils/driver_route_status.dart';
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

  // Unlocked only by real production conditions - active route, truck away
  // from shop, phone GPS within range of the truck. Shared with the cancel
  // dialog's cancellation-fee display via isDriverOnRoute.
  Future<bool> _computeDriverChatUnlock() {
    return isDriverOnRoute(widget.currentUserId);
  }

  // Periodic background refresh - just keeps _driverChatUnlocked current so
  // the menu item shows/hides correctly.
  Future<void> _refreshDriverChatUnlockStatus() async {
    final unlocked = await _computeDriverChatUnlock();

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
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
