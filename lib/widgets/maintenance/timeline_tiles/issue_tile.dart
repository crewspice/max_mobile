import 'package:flutter/material.dart';
import '../../../models/lift_maintenance_history_item.dart';

class IssueTile extends StatelessWidget {
  final LiftMaintenanceHistoryItem issue;

  const IssueTile(
    this.issue, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Issue: ${issue.actionTypeName ?? 'Unknown'}',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}