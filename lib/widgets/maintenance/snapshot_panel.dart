import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../models/lift_maintenance_snapshot.dart';
import '../../theme/app_colors.dart';
import '../ornate_card.dart';

class SnapshotPanel extends StatelessWidget {
  final Lift lift;
  final LiftMaintenanceSnapshot snapshot;

  const SnapshotPanel({
    super.key,
    required this.lift,
    required this.snapshot,
  });

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final needsAnnual = snapshot.needsAnnual == true;
    final needsPm = snapshot.upToDate != true;

    final good = !needsAnnual && !needsPm;
    final color = good ? AppColors.green : AppColors.red;

    final title = needsAnnual
        ? 'Needs Annual'
        : needsPm
            ? 'Needs PM'
            : 'Up to date';

    return OrnateCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
                children: [
                    Icon(
                    good ? Icons.check_circle : Icons.warning,
                    color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                    title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                ],
            ),
            if (snapshot.pmId != null) ...[
            const SizedBox(height: 6),
            Text(
                '${needsAnnual ? 'Last PM:' : 'Last:'} '
                '${snapshot.pmCompletedByNickname ?? 'Unknown'} on '
                '${snapshot.pmCompletedAt != null ? _formatDate(snapshot.pmCompletedAt!) : 'Unknown'}',
                style: TextStyle(color: color),
            ),
          ],
        ],
      ),
    );
  }
}