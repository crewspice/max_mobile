import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'completed_stops_screen.dart';
import 'user_statistics_screen.dart';
import 'edit_profile_screen.dart';
import 'driver_chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';


class MenuScreen extends StatelessWidget {
  final String currentUserId;
  final String userName;
  final bool maintenanceOnly;
  final bool driverChatUnlocked;
  final VoidCallback? onAssessDriverStatus;

  const MenuScreen({
    super.key,
    required this.currentUserId,
    required this.userName,
    this.maintenanceOnly = false,
    this.driverChatUnlocked = false,
    this.onAssessDriverStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
        appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
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
            "Menu",
            style: GoogleFonts.permanentMarker(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3.5,
            ),
            ),
        ),
        ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.bar_chart, color: AppColors.yellow),
            title: const Text(
              'User Statistics',
              style: TextStyle(color: AppColors.yellow),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/statistics',
                arguments: currentUserId,
              );
            },
          ),

          const Divider(color: AppColors.yellow),

          if (!maintenanceOnly)
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: AppColors.yellow,
              ),
              title: const Text(
                'Completed Stops',
                style: TextStyle(color: AppColors.yellow),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompletedStopsScreen(
                      driverId: currentUserId,
                    ),
                  ),
                );
              },
            ),

          if (!maintenanceOnly)
            const Divider(color: AppColors.yellow),
          if (!maintenanceOnly)
            ListTile(
              leading: const Icon(Icons.pending_actions,
                  color: AppColors.yellow),
              title: const Text(
                'Unassigned Stops',
                style: TextStyle(color: AppColors.yellow),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompletedStopsScreen(
                      driverId: currentUserId,
                      unassigned: true,
                    ),
                  ),
                );
              },
            ),

          if (!maintenanceOnly) const Divider(color: AppColors.yellow),

          ListTile(
            leading: const Icon(Icons.account_circle, color: AppColors.yellow),
            title: const Text(
              'Profile Picture',
              style: TextStyle(color: AppColors.yellow),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    currentUserId: currentUserId,
                  ),
                ),
              );
            },
          ),

          Divider(color: AppColors.yellow.withOpacity(driverChatUnlocked ? 1 : 0.4)),

          if (driverChatUnlocked)
            ListTile(
              leading: const Icon(Icons.lock_open, color: AppColors.yellow),
              title: const Text(
                'Driver Chat',
                style: TextStyle(color: AppColors.yellow),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverChatScreen(
                      currentUserId: currentUserId,
                      userName: userName,
                    ),
                  ),
                );
              },
            )
          else
            ListTile(
              leading: Icon(Icons.lock_outline, color: AppColors.yellow.withOpacity(0.4)),
              title: Text(
                "assess if I'm a driver",
                style: TextStyle(color: AppColors.yellow.withOpacity(0.4)),
              ),
              onTap: onAssessDriverStatus == null
                  ? null
                  : () {
                      onAssessDriverStatus!();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assessing...')),
                      );
                    },
            ),
        ],
      ),
    );
  }
}