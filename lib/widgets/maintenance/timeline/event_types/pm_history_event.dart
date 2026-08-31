import 'package:flutter/material.dart';
import '../../../../models/lift_pm_history_item.dart';
import '../../timeline_tiles/pm_tile.dart';
import '../timeline_event.dart';

class PmHistoryEvent extends TimelineEvent {

  final LiftPmHistoryItem pm;

  PmHistoryEvent(this.pm);

  @override
  DateTime get start => pm.completedAt ?? DateTime.now();

  @override
  DateTime get end => start;

  @override
  TimelineEventType get type => TimelineEventType.pm;

  @override
  List<DateTime?> get displayDates => [pm.completedAt];

  @override
  Widget build(BuildContext context) {
    return PmTile(pm);
  }
}