import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/stop.dart';
import '../widgets/rental_card.dart';
import '../widgets/service_card.dart';
import '../widgets/base_card.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';


class RentalListView extends StatefulWidget {
  final String driverId;
  final bool completed;
  final bool unassigned;

  const RentalListView({
    super.key,
    required this.driverId,
    this.completed = false,
    this.unassigned = false,
  });

  @override
  _RentalListViewState createState() => _RentalListViewState();
}

class _RentalListViewState extends State<RentalListView> {
  late Future<List<Stop>> futureStops;
  List<Stop> stops = [];
  List<TextEditingController> serialControllers = [];

  @override
  void initState() {
    super.initState();
    futureStops = _loadStops();
  }

  Future<List<Stop>> _loadStops() async {
    final result = await ApiService().fetchStopsByDriver(
      widget.driverId,
      completed: widget.completed,
      unassigned: widget.unassigned,
    );

    setState(() {
      stops = result;
    });

    return result;
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
    final result = await _fetchStopsForDriverWithFallback(widget.driverId);

    setState(() {
      stops = result;
      futureStops = Future.value(result);
    });
  }

  // Fetch stops for one driver, but fallback to all drivers if empty/error
  Future<List<Stop>> _fetchStopsForDriverWithFallback(String driverId) async {
    try {
      final stops = await ApiService().fetchStopsByDriver(
        driverId,
        completed: widget.completed,
        unassigned: widget.unassigned,
      );
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

  Widget gradientText(String text) {
    return ShaderMask(
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
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white, // required for ShaderMask
          letterSpacing: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: FutureBuilder<List<Stop>>(
        future: futureStops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && stops.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError && stops.isEmpty) {
            return Center(
              child: gradientText('${snapshot.error}'),
            );
          }

          if (snapshot.hasData && stops.isEmpty) {
            stops = snapshot.data!;
          }

          if (stops.isEmpty) {
            return Center(
              child: gradientText('No stops available'),
            );
          }

          if (serialControllers.length != stops.length) {
            serialControllers = List.generate(
              stops.length,
              (_) => TextEditingController(),
            );
          }

          return RefreshIndicator(
            color: AppColors.main,
            backgroundColor: AppColors.yellow,
            onRefresh: _refreshRentals,
            child: ListView.builder(
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];

                if (stop.type == 'RENTAL') {
                  return RentalCard(
                    stop: stop,
                    serialController: serialControllers[index],
                    completedView: widget.completed,
                    unassignedView: widget.unassigned,
                    onRefresh: _refreshRentals,
                    onNotesUpdated: (updatedStop) {
                      setState(() {
                        stops[index] = updatedStop;
                      });
                    },
                  );
                }

                if (stop.type == 'SERVICE') {
                  return ServiceCard(
                    stop: stop,
                    onRefresh: _refreshRentals,
                    completedView: widget.completed,
                    unassignedView: widget.unassigned,
                  );
                }

                if (stop.liftType == 'HQ') {
                  return BaseCard(
                    stop: stop,
                    onRefresh: _refreshRentals,
                    completedView: widget.completed,
                    onNotesUpdated: (updatedStop) {
                      setState(() {
                        stops[index] = updatedStop;
                      });
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}
