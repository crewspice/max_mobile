import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverStatisticsScreen extends StatefulWidget {
  final String driverId;
  const DriverStatisticsScreen({super.key, required this.driverId});

  @override
  State<DriverStatisticsScreen> createState() => _DriverStatisticsScreenState();
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
      appBar: AppBar(title: const Text('Driver Statistics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data."));
          }

          final data = snapshot.data!;
          final driverInitial = data['driver'];
          final driverSeconds = (data['driverSeconds'] as int).toDouble();
          final driverMinutes = driverSeconds / 60;
          final monthTotalSeconds = (data['monthTotalSeconds'] as int).toDouble();
          final monthTotalMinutes = monthTotalSeconds / 60;
          final percent = monthTotalSeconds > 0
              ? (driverSeconds / monthTotalSeconds * 100).toStringAsFixed(1)
              : '0';


          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  "Driver: $driverInitial",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // --- BIG NUMBER ---
                Text(
                  "$percent%",
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "of all assigned drive time this month",
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 40),

                // --- BAR GRAPH ---
                LinearProgressIndicator(
                  value: monthTotalMinutes > 0 ? driverMinutes / monthTotalMinutes : 0.0,
                  minHeight: 18,
                ),


                const SizedBox(height: 10),
                Text(
                "${driverMinutes.toStringAsFixed(0)} min / ${monthTotalMinutes.toStringAsFixed(0)} min",
                style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
