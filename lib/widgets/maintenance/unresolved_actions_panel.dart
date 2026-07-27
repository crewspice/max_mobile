import 'package:flutter/material.dart';
import '../../models/lift_maintenance_snapshot.dart';
import 'repair_card.dart';

class UnresolvedActionsPanel extends StatelessWidget {
  final LiftMaintenanceSnapshot snapshot;
  final String currentUserId;
  final VoidCallback onChanged;

  const UnresolvedActionsPanel({
    super.key,
    required this.snapshot,
    required this.currentUserId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: snapshot.maintenanceActions
          .map(
            (action) => RepairCard(
              action: action,
              currentUserId: currentUserId,
              onResolved: onChanged,
            ),
          )
          .toList(),
    );
  }
}