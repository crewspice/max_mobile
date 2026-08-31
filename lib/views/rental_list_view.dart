import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/stop.dart';
import '../widgets/rental_card.dart';
import '../widgets/service_card.dart';
import '../widgets/base_card.dart';
import '../widgets/maintenance/inspection_prompt_card.dart';
import '../theme/app_colors.dart';
import '../utils/shop_geofence.dart' as shop_geofence;
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
  Map<int, TextEditingController> serialControllers = {};

  // Trucks used on this route with no inspection in the last rolling week,
  // and which of those the driver has dismissed for this app session only
  // (no persistence - reappears next cold start / screen re-entry).
  Set<String> staleTrucks = {};
  Set<String> dismissedTrucks = {};

  @override
  void initState() {
    super.initState();
    futureStops = _loadStops();
  }

  Future<List<Stop>> _loadStops() async {
    final position = await shop_geofence.getCurrentPosition();

    final result = await ApiService().fetchStopsByDriver(
      widget.driverId,
      completed: widget.completed,
      unassigned: widget.unassigned,
      deviceLat: position?.latitude,
      deviceLng: position?.longitude,
    );

    setState(() {
      stops = result;
    });

    _checkStaleTrucks(result);

    return result;
  }

  // Only the driver's active route (not the completed/unassigned history
  // screens, which reuse this same view) should warn about upcoming trucks.
  Future<void> _checkStaleTrucks(List<Stop> loadedStops) async {
    if (widget.completed || widget.unassigned) return;

    final truckIds = loadedStops
        .map((s) => s.truck)
        .whereType<String>()
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    if (truckIds.isEmpty) return;

    try {
      final stale = await ApiService().needsInspectionRollingWeek(truckIds);
      if (!mounted) return;
      setState(() {
        staleTrucks = stale.toSet();
      });
    } catch (_) {
      // Non-critical - just skip the reminder if the check fails.
    }
  }

  @override
  void dispose() {
    for (var controller in serialControllers.values) {
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
      stops = [];
      serialControllers.clear();
    });

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    setState(() {
      stops = result;
      futureStops = Future.value(result);
    });

    _checkStaleTrucks(result);
  }

  // Fetch stops for one driver, but fallback to all drivers if empty/error
  Future<List<Stop>> _fetchStopsForDriverWithFallback(String driverId) async {
    try {
      final position = await shop_geofence.getCurrentPosition();

      final stops = await ApiService().fetchStopsByDriver(
        driverId,
        completed: widget.completed,
        unassigned: widget.unassigned,
        deviceLat: position?.latitude,
        deviceLng: position?.longitude,
      );
      if (stops.isNotEmpty) {
        return stops; // normal route data exists → show it
      }
    } catch (_) {
      // ignore errors for primary driver
    }

    // fallback: fetch all drivers to build a company-wide summary. This is
    // browsing, not the driver viewing their own route, so device location
    // is not sent — must not mark other drivers' routes as "seen" by them
    // just because this phone happens to be near their truck (e.g. everyone
    // parked together at the shop).
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
        siteId: -1,
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

          for (final stop in stops) {
            serialControllers.putIfAbsent(
              stop.id,
              () => TextEditingController(),
            );
          }

          serialControllers.removeWhere(
            (id, controller) => !stops.any((s) => s.id == id),
          );

          final visibleStaleTrucks = staleTrucks
              .difference(dismissedTrucks)
              .toList()
            ..sort();

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.main,
                backgroundColor: AppColors.yellow,
                onRefresh: _refreshRentals,
                child: ListView.builder(
                  itemCount: stops.length,
                  itemBuilder: (context, index) {
                    final stop = stops[index];

                    if (stop.type == 'RENTAL') {
                      return RentalCard(
                        key: ValueKey(stop.id),
                        stop: stop,
                        serialController: serialControllers[stop.id]!,
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
                        key: ValueKey(stop.id),
                        stop: stop,
                        onRefresh: _refreshRentals,
                        completedView: widget.completed,
                        unassignedView: widget.unassigned,
                      );
                    }

                    if (stop.liftType == 'HQ') {
                      return BaseCard(
                        key: ValueKey(stop.id),
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
              ),
              if (visibleStaleTrucks.isNotEmpty)
                _buildStaleTruckOverlay(visibleStaleTrucks.first),
            ],
          );
        },
      ),
    );
  }

  // Styled to match the truck-page inspection warning (truck_view.dart),
  // but blown up into a full-screen barrier so the driver has to deal with
  // it (or explicitly Dismiss) before they can get back to the route -
  // dismissal isn't persisted, so it reappears on next cold start / screen
  // re-entry.
  Widget _buildStaleTruckOverlay(String truckId) {
    void dismiss() {
      setState(() {
        dismissedTrucks.add(truckId);
      });
    }

    return Positioned.fill(
      child: GestureDetector(
        // Tapping the barrier dismisses like the card's own Dismiss button;
        // the inner GestureDetector around the card absorbs taps on the
        // card itself so they don't fall through to this one.
        onTap: dismiss,
        child: Container(
          color: Colors.black87,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () {},
            child: InspectionPromptCard(
              title: "Truck $truckId needs inspection",
              message: "None recorded in $kInspectionWindowDays days.",
              glyphAlignment: const Alignment(0, -0.65),
              onSubmitIssue: (image, description) =>
                  ApiService().recordTruckIssue(
                image: image,
                truckId: truckId,
                driverId: widget.driverId,
                description: description,
              ),
              onIssueSubmitted: () {
                setState(() {
                  staleTrucks.remove(truckId);
                });
              },
              onNoIssues: () => _recordNoIssues(truckId),
              onDismiss: dismiss,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordNoIssues(String truckId) async {
    try {
      await ApiService().recordTruckInspection(
        truckId: truckId,
        driverId: widget.driverId,
      );

      if (!mounted) return;

      setState(() {
        staleTrucks.remove(truckId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection recorded successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record inspection: $e'),
        ),
      );
    }
  }

}
