import 'package:flutter/material.dart';
import '../../../models/lift_pm_history_item.dart';

class PmTile extends StatelessWidget {
  final LiftPmHistoryItem pm;

  const PmTile(
    this.pm, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'PM completed ${pm.completedAt ?? ''}',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}