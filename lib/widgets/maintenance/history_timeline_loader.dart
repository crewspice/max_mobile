import 'package:flutter/material.dart';
import '../../models/lift_pm_history_item.dart';
import '../../models/lift_maintenance_history_item.dart';
import '../../models/lift_rental_history_item.dart';
import '../../services/api_service.dart';
import '../../views/maintenance_ui_state.dart';
import 'timeline/timeline_builder.dart';
import 'maintenance_timeline.dart';

class HistoryTimelineLoader extends StatefulWidget {
  final int liftId;
  final MaintenanceUiState ui;

  const HistoryTimelineLoader({
    super.key,
    required this.liftId,
    required this.ui,
  });

  @override
  State<HistoryTimelineLoader> createState() => _HistoryTimelineLoaderState();
}

class _HistoryTimelineLoaderState extends State<HistoryTimelineLoader> {
  Future<List<dynamic>>? _historyFuture;

  @override
  void didUpdateWidget(covariant HistoryTimelineLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liftId != widget.liftId) {
      _historyFuture = null;
    }
  }

  void _ensureLoaded() {
    _historyFuture ??= Future.wait([
      ApiService().fetchPmHistory(widget.liftId),
      ApiService().fetchMaintenanceHistory(widget.liftId),
      ApiService().fetchRentalHistory(widget.liftId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ui,
      builder: (context, _) {
        if (widget.ui.selectedHistory.isEmpty) {
          return const SizedBox.shrink();
        }

        _ensureLoaded();

        return FutureBuilder(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final pms = snapshot.data![0] as List<LiftPmHistoryItem>;
            final issues = snapshot.data![1] as List<LiftMaintenanceHistoryItem>;
            final rentals = snapshot.data![2] as List<LiftRentalHistoryItem>;

            final events = buildTimeline(
              pms: pms,
              issues: issues,
              rentals: rentals,
              filters: widget.ui.selectedHistory,
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
