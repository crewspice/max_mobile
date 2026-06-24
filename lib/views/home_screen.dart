import 'package:flutter/material.dart';
import 'rental_list_view.dart';
import 'maintenance_view.dart';
import 'truck_view.dart';
import 'driver_statistics_screen.dart';
import 'user_selection_screen.dart';
import 'completed_stops_screen.dart';
import 'menu_screen.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeScreen extends StatefulWidget {
  final String currentUserId;
  final String userName;
  final String? truckId;

  const HomeScreen({
    super.key,
    required this.currentUserId,
    required this.userName,
    required this.truckId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _showMenu() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          currentUserId: widget.currentUserId,
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
    final pages = <Widget>[
      RentalListView(driverId: widget.currentUserId),
      MaintenanceView(currentUserId: widget.currentUserId),
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
              fontWeight: FontWeight.bold,
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
      bottomNavigationBar: SafeArea(
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