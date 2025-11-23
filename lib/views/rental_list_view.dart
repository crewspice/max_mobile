import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/stop.dart';
import '../widgets/rental_card.dart';
import '../widgets/service_card.dart';
import '../widgets/base_card.dart';

class RentalListView extends StatefulWidget {
  final String driverId;

  const RentalListView({super.key, required this.driverId});

  @override
  _RentalListViewState createState() => _RentalListViewState();
}

class _RentalListViewState extends State<RentalListView> {
  late Future<List<Stop>> futureStops;
  List<TextEditingController> serialControllers = [];

  @override
  void initState() {
    super.initState();
    futureStops = ApiService().fetchStopsByDriver(widget.driverId);
  }

  @override
  void dispose() {
    for (var controller in serialControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _mapDriverId(String driverId) {
    const driverMap = {
      'JS': 'Jacob',
      'K': 'Kaleb',
      'A': 'Adrian',
      'JC': 'Jackson',
      'J': 'John',
      'B': 'Byron',
    };
    return driverMap[driverId] ?? driverId;
  }
Future<void> _refreshRentals() async {
  setState(() {
    futureStops = _fetchStopsForDriverWithFallback(widget.driverId);
  });
}

// Fetch stops for one driver, but fallback to all drivers if empty/error
Future<List<Stop>> _fetchStopsForDriverWithFallback(String driverId) async {
  try {
    final stops = await ApiService().fetchStopsByDriver(driverId);
    if (stops.isNotEmpty) {
      return stops; // normal route data exists → show it
    }
  } catch (_) {
    // ignore errors for primary driver
  }

  // fallback: fetch all drivers to build summary
  const driverIds = ['JS', 'K', 'A', 'JC', 'J', 'B'];
  Map<String, bool> driverHasRoutes = {};

  for (var id in driverIds) {
    try {
      final s = await ApiService().fetchStopsByDriver(id);
      driverHasRoutes[id] = s.isNotEmpty;
    } catch (_) {
      driverHasRoutes[id] = false;
    }
  }

  // Build ghost summary stop objects
  List<Stop> ghostStops = [
    Stop(
      id: -1,
      orderId: -1,
      type: 'GHOST_SUMMARY',
      driverId: '',
      liftType: '',
      // optionally fill other fields if Stop requires them
    )
  ];

  // attach summary as a property inside ghost stop
  ghostStops[0] = ghostStops[0].copyWith(
    driverId: _buildDriverSummary(driverHasRoutes),
  );

  return ghostStops;
}

// Helper to build summary string
String _buildDriverSummary(Map<String, bool> driverHasRoutes) {
  const driverMap = {
    'JS': 'Jacob',
    'K': 'Kaleb',
    'A': 'Adrian',
    'JC': 'Jackson',
    'J': 'John',
    'B': 'Byron',
  };

  final withRoutes = driverHasRoutes.entries
      .where((e) => e.value)
      .map((e) => driverMap[e.key] ?? e.key)
      .toList();

  if (withRoutes.isEmpty) return "Nobody has routes";

  return "${withRoutes.join(', ')} have routes";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasks for: ${_mapDriverId(widget.driverId)}")),
      body: FutureBuilder<List<Stop>>(
        future: futureStops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No stops available.'));
          }

          List<Stop> stops = snapshot.data!;
          if (serialControllers.length != stops.length) {
            serialControllers =
                List.generate(stops.length, (index) => TextEditingController());
          }

          return RefreshIndicator(
            onRefresh: _refreshRentals,
            child: ListView.builder(
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];

                if (stop.type == 'RENTAL') {
                  return RentalCard(
                    stop: stop,
                    serialController: serialControllers[index],
                    onRefresh: _refreshRentals,
                  );
                } else if (stop.type == 'SERVICE') {
                  return ServiceCard(
                    stop: stop,
                    onRefresh: _refreshRentals,
                  );
                } else if (stop.liftType == 'HQ') {
                  return BaseCard(
                    stop: stop,
                    onRefresh: _refreshRentals, // refresh after HQ deletion
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
