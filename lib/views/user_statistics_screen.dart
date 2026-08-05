import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class UserStatisticsScreen extends StatefulWidget {
  final String driverId;

  const UserStatisticsScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<UserStatisticsScreen> createState() =>
      _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen> {
  late Future<Map<String, dynamic>> futureStats;
  late DateTime selectedMonth;
  bool viewingHistorical = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(
      now.year,
      now.month,
    );
    futureStats = ApiService().fetchUserStatistics(
      widget.driverId,
    );
  }

  Widget buildStatCard({
    required String title,
    required String subtitle,
    required double percent,
    required double current,
    required double total,
    required Color color,
    String? unit,
  }) {
    final progress = total > 0 ? current / total : 0.0;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "${percent.toStringAsFixed(1)}%",
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
          ),
        ),

        const SizedBox(height: 15),

        LinearProgressIndicator(
          value: progress,
          minHeight: 16,
          backgroundColor: AppColors.main,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),

        const SizedBox(height: 8),

        // Text(
        //   unit != null
        //       ? "${current.toStringAsFixed(0)} $unit / "
        //         "${total.toStringAsFixed(0)} $unit"
        //       : "${current.toStringAsFixed(0)} / "
        //         "${total.toStringAsFixed(0)}",
        //   style: TextStyle(
        //     fontSize: 16,
        //     color: color,
        //   ),
        // ),
      ],
    );
  }

  void loadStats() {
    if (viewingHistorical) {
      futureStats = ApiService().fetchUserStatistics(
        widget.driverId,
        year: selectedMonth.year,
        month: selectedMonth.month,
      );
    } else {
      futureStats = ApiService().fetchUserStatistics(
        widget.driverId,
      );
    }

    setState(() {});
  }

  void resetToRolling() {
    setState(() {
      viewingHistorical = false;
    });

    loadStats();
  }

  // Only fully completed months can have a finished report;
  // the in-progress current month is covered by the rolling stat instead.
  List<int> get completedMonths {
    final now = DateTime.now();
    return [for (int m = 1; m < now.month; m++) m];
  }

  void openMonthYearPicker() {
    final now = DateTime.now();
    final months = completedMonths;

    if (months.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No completed months yet this year.")),
      );
      return;
    }

    int initialMonthIndex = months.indexOf(selectedMonth.month);
    if (initialMonthIndex == -1) {
      initialMonthIndex = months.length - 1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.main,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 260,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController: FixedExtentScrollController(
                            initialItem: initialMonthIndex,
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              viewingHistorical = true;
                              selectedMonth = DateTime(now.year, months[index]);
                            });
                            loadStats();
                          },
                          children: [
                            for (final m in months)
                              Center(
                                child: Text(
                                  getMonthName(m),
                                  style: const TextStyle(
                                    color: AppColors.yellow,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.4,
                            child: CupertinoPicker(
                              itemExtent: 40,
                              scrollController: FixedExtentScrollController(
                                initialItem: 0,
                              ),
                              onSelectedItemChanged: (_) {},
                              children: [
                                Center(
                                  child: Text(
                                    "${now.year}",
                                    style: const TextStyle(
                                      color: AppColors.yellow,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            "User Statistics",
            style: GoogleFonts.permanentMarker(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.5,
            ),
          ),
        ),
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(
          color: AppColors.yellow,
        ),
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
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(
                  color: AppColors.yellow,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "No data.",
                style: TextStyle(
                  color: AppColors.yellow,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          final userName = data['userName'] ?? widget.driverId;

          final driveSeconds =
              ((data['driveSeconds'] ?? 0) as num).toDouble();

          final driveTotalSeconds =
              ((data['driveTotalSeconds'] ?? 0) as num).toDouble();

          final pmChecks =
              ((data['pmChecks'] ?? 0) as num).toDouble();

          final pmTotalChecks =
              ((data['pmTotalChecks'] ?? 0) as num).toDouble();

          final repairs =
              ((data['repairs'] ?? 0) as num).toDouble();

          final repairTotal =
              ((data['repairTotal'] ?? 0) as num).toDouble();

          final periodStart = data['periodStart'] != null
              ? DateTime.tryParse(data['periodStart'] as String)
              : null;

          final double drivePercent = driveTotalSeconds > 0
              ? driveSeconds / driveTotalSeconds * 100
              : 0.0;

          final double pmPercent = pmTotalChecks > 0
              ? pmChecks / pmTotalChecks * 100
              : 0.0;

          final double repairPercent = repairTotal > 0
              ? repairs / repairTotal * 100
              : 0.0;


          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow,
                  ),
                ),

                if (viewingHistorical) ...[
                  const SizedBox(height: 10),
                  Text(
                    "${getMonthName(selectedMonth.month)} ${selectedMonth.year} report",
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.yellow,
                    ),
                  ),
                ],

                const SizedBox(height: 15),

                buildStatCard(
                  title: "Driving",
                  subtitle:
                      "of all assigned drive time",
                  percent: drivePercent,
                  current: driveSeconds / 60,
                  total: driveTotalSeconds / 60,
                  color: AppColors.yellow,
                  unit: "min",
                ),

                const SizedBox(height: 45),

                buildStatCard(
                  title: "PMs",
                  subtitle:
                      "of all preventative maintenance checks",
                  percent: pmPercent,
                  current: pmChecks,
                  total: pmTotalChecks,
                  color: AppColors.green,
                ),

                const SizedBox(height: 45),

                buildStatCard(
                  title: "Repairs",
                  subtitle:
                      "of all completed repairs",
                  percent: repairPercent,
                  current: repairs,
                  total: repairTotal,
                  color: AppColors.red,
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (viewingHistorical)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 24,
                          color: AppColors.yellow,
                        ),
                        onPressed: resetToRolling,
                      ),

                    if (!viewingHistorical && periodStart != null)
                      Text(
                        "Since ${getMonthName(periodStart.month).substring(0, 3)} ${periodStart.day}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.yellow,
                        ),
                      ),

                    IconButton(
                      icon: const Icon(
                        Icons.date_range_rounded,
                        size: 24,
                        color: AppColors.yellow,
                      ),
                      onPressed: openMonthYearPicker,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String getMonthName(int month) {

    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return months[month - 1];
  }
}