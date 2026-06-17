import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverStatisticsScreen extends StatefulWidget {
  final String driverId;
  const DriverStatisticsScreen({super.key, required this.driverId});

  @override
  State<DriverStatisticsScreen> createState() =>
      _DriverStatisticsScreenState();
}

class _DriverStatisticsScreenState extends State<DriverStatisticsScreen> {
  late Future<Map<String, dynamic>> futureStats;

  @override
  void initState() {
    super.initState();
    futureStats = ApiService().fetchDriverStatistics(widget.driverId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
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
            "Driver Statistics",
            style: GoogleFonts.permanentMarker(
              fontSize: 26, // slightly smaller than header
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.5,
            ),
          ),
        ),
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.yellow,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: AppColors.yellow),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "No data.",
                style: TextStyle(color: AppColors.yellow),
              ),
            );
          }

          final data = snapshot.data!;
          final driverInitial = data['driver'];
          final driverSeconds =
              (data['driverSeconds'] as int).toDouble();
          final driverMinutes = driverSeconds / 60;
          final monthTotalSeconds =
              (data['monthTotalSeconds'] as int).toDouble();
          final monthTotalMinutes = monthTotalSeconds / 60;

          final percent = monthTotalSeconds > 0
              ? (driverSeconds / monthTotalSeconds * 100)
                  .toStringAsFixed(1)
              : '0';

          final progressValue = monthTotalMinutes > 0
              ? driverMinutes / monthTotalMinutes
              : 0.0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  "Driver: $driverInitial",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  "$percent%",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow,
                  ),
                ),

                const Text(
                  "of all assigned drive time this month",
                  style: TextStyle(color: AppColors.yellow),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 18,
                  backgroundColor: AppColors.main,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.yellow,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "${driverMinutes.toStringAsFixed(0)} min / "
                  "${monthTotalMinutes.toStringAsFixed(0)} min",
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}