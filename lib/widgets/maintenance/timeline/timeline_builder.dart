import '../../../models/lift_pm_history_item.dart';
import '../../../models/lift_maintenance_history_item.dart';
import '../../../models/lift_rental_history_item.dart';
import '../../../views/maintenance_ui_state.dart';

import 'event_types/pm_history_event.dart';
import 'event_types/issue_history_event.dart';
import 'event_types/rental_history_event.dart';

import 'timeline_event.dart';

List<TimelineEvent> buildTimeline({
  required List<LiftPmHistoryItem> pms,
  required List<LiftMaintenanceHistoryItem> issues,
  required List<LiftRentalHistoryItem> rentals,
  required Set<HistoryFilter> filters,
}) {
  final events = <TimelineEvent>[];

  if(filters.contains(HistoryFilter.pms)) {
    events.addAll(
      pms.map(PmHistoryEvent.new),
    );
  }

  if(filters.contains(HistoryFilter.issues)) {
    events.addAll(
      issues.map(IssueHistoryEvent.new),
    );
  }

  if(filters.contains(HistoryFilter.rentals)) {
    events.addAll(
      rentals.map(RentalHistoryEvent.new),
    );
  }

  events.sort(
    (a,b) => b.start.compareTo(a.start),
  );

  return events;
}