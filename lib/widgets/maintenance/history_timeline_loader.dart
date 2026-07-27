import 'package:flutter/material.dart';
import '../../models/lift_pm_history_item.dart';
import '../../models/lift_maintenance_history_item.dart';
import '../../models/lift_rental_history_item.dart';
import '../../services/api_service.dart';
import '../../views/maintenance_ui_state.dart';
import 'timeline/timeline_builder.dart';
import 'maintenance_timeline.dart';

class HistoryTimelineLoader extends StatelessWidget {
  final int liftId;
  final MaintenanceUiState ui;

  const HistoryTimelineLoader({
    super.key,
    required this.liftId,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {

    return ListenableBuilder(
      listenable: ui,
      builder: (context, _) {

        return FutureBuilder(
          future: Future.wait([
            ApiService().fetchPmHistory(liftId),
            ApiService().fetchMaintenanceHistory(liftId),
            ApiService().fetchRentalHistory(liftId),
          ]),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final pms =
                snapshot.data![0] as List<LiftPmHistoryItem>;

            final issues =
                snapshot.data![1] as List<LiftMaintenanceHistoryItem>;

            final rentals =
                snapshot.data![2] as List<LiftRentalHistoryItem>;


            final events = buildTimeline(
              pms: pms,
              issues: issues,
              rentals: rentals,
              filters: ui.selectedHistory,
            );


            print(
              "FILTERS: ${ui.selectedHistory} EVENTS: ${events.length}",
            );


            return MaintenanceTimeline(
              events: events,
            );
          },
        );
      },
    );
  }
}