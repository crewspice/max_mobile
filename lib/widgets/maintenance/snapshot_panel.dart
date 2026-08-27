import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../models/lift_maintenance_snapshot.dart';
import '../../theme/app_colors.dart';
import '../../views/pm_checklist_screen.dart';
import '../curved_stack_card.dart';
import '../user_avatar.dart';

class SnapshotPanel extends StatelessWidget {
  final Lift lift;
  final LiftMaintenanceSnapshot snapshot;
  final StackPosition position;

  const SnapshotPanel({
    super.key,
    required this.lift,
    required this.snapshot,
    this.position = StackPosition.only,
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

    return CurvedStackCard(
      color: color,
      position: position,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
                children: [
                    Icon(
                    good ? Icons.check_circle : Icons.warning,
                    color: AppColors.yellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                    title,
                    style: const TextStyle(
                        color: AppColors.yellow,
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PmChecklistScreen(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.checklist,
                        color: AppColors.yellow,
                        size: 22,
                      ),
                    ),
                ],
            ),
            if (snapshot.pmId != null) ...[
            const SizedBox(height: 6),
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    UserAvatar(
                        initials: snapshot.pmCompletedByInitials,
                        radius: 10,
                        color: AppColors.yellow,
                        textColor: AppColors.main,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                            '${needsAnnual ? 'Last PM:' : 'Last:'} '
                            '${snapshot.pmCompletedByNickname ?? 'Unknown'} on '
                            '${snapshot.pmCompletedAt != null ? _formatDate(snapshot.pmCompletedAt!) : 'Unknown'}',
                            style: const TextStyle(color: AppColors.yellow),
                        ),
                    ),
                ],
            ),
          ],
        ],
      ),
    );
  }
}