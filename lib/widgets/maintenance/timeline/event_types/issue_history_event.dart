import 'package:flutter/material.dart';
import '../../../../models/lift_maintenance_history_item.dart';
import '../../timeline_tiles/issue_tile.dart';
import '../timeline_event.dart';

class IssueHistoryEvent extends TimelineEvent {

  final LiftMaintenanceHistoryItem issue;

  IssueHistoryEvent(this.issue);

  @override
  DateTime get start =>
      issue.performedAt ?? issue.createdAt ?? DateTime.now();

  @override
  DateTime get end => start;

  @override
  Widget build(BuildContext context) {
    return IssueTile(issue);
  }
}