import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'rental_list_view.dart';
import 'driver_statistics_screen.dart';


class DriverSelectionScreen extends StatefulWidget {
  const DriverSelectionScreen({super.key});

  @override
  _DriverSelectionScreenState createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  late Future<List<String>> futureDriversWithRoutes;

  static const driverMap = {
    'JS': 'Jacob',
    'K': 'Kaleb',
    'A': 'Adrian',
    'JC': 'Jackson',
    'J': 'John',
    'B': 'Byron',
  };

  @override
  void initState() {
    super.initState();
    futureDriversWithRoutes = ApiService().fetchDriversWithRoutes();
  }

  Future<void> _refreshDrivers() async {
    setState(() {
      futureDriversWithRoutes = ApiService().fetchDriversWithRoutes();
    });
  }

  _openDriverStatistics(driverId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverStatisticsScreen(driverId: driverId),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Driver')),
      body: FutureBuilder<List<String>>(
        future: futureDriversWithRoutes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No drivers available.'));
          }

          final driversWithRoutes = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshDrivers,
            child: ListView.builder(
              itemCount: driverMap.length,
              itemBuilder: (context, index) {
                final driverId = driverMap.keys.elementAt(index);
                final driverName = driverMap[driverId]!;
                final hasRoute = driversWithRoutes.contains(driverId);

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(driverId),
                    backgroundColor: hasRoute ? Colors.green : Colors.grey,
                  ),
                  title: Text(driverName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasRoute)
                        IconButton(
                          icon: Image.asset(
                            'assets/assignment.png',
                            width: 26,
                            height: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RentalListView(driverId: driverId),
                              ),
                            );
                          },
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'statistics') {
                            _openDriverStatistics(driverId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'statistics',
                            child: Text('Driver Stats'),
                          ),
                          // Add more niche views here later
                        ],
                      ),
                    ],
                  ),
                  onTap: hasRoute
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RentalListView(driverId: driverId),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

