import 'package:flutter/material.dart';
import '../../../models/lift_maintenance_history_item.dart';
import '../../../theme/app_colors.dart';

class IssueTile extends StatelessWidget {
  final LiftMaintenanceHistoryItem issue;

  const IssueTile(
    this.issue, {
    super.key,
  });

  String _date(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];

    if (issue.actionTypeName != null) {
      lines.add('Issue: ${issue.actionTypeName}');
    }

    if (issue.performedByName != null) {
      lines.add('Performed by: ${issue.performedByName}');
    }

    if (issue.reportedBy != null) {
      lines.add('Reported by: ${issue.reportedBy}');
    }

    if (issue.performedAt != null) {
      lines.add('Date: ${_date(issue.performedAt)}');
    }

    if (issue.partAction != null) {
      lines.add('Action: ${issue.partAction}');
    }

    if (issue.quantity != null) {
      lines.add('Quantity: ${issue.quantity}');
    }

    if (issue.noRepairNeeded) {
      lines.add('No repair needed');
    }

    if (issue.repairNotes != null) {
      lines.add('Repair notes: ${issue.repairNotes}');
    }

    if (issue.notes != null) {
      lines.add('Notes: ${issue.notes}');
    }

    return Card(
      color: AppColors.main,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map(
            (line) => Text(
              line,
              style: const TextStyle(
                color: AppColors.green,
              ),
            ),
          ).toList(),
        ),
      ),
    );
  }
}