import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../models/lift_maintenance_snapshot.dart';
import '../../theme/app_colors.dart';
import '../../views/pm_checklist_screen.dart';
import '../curved_stack_card.dart';
import '../date_label.dart';
import '../user_avatar.dart';
import '../watermark_title.dart';

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
      sideInset: 50,
      cornerInset: 58,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WatermarkTitle(
                  text: title,
                  glyph: good
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  glyphAlignment: const Alignment(0, -0.2),
              ),
              if (snapshot.pmId != null) ...[
              const SizedBox(height: 6),
              Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                      UserAvatar(
                          initials: snapshot.pmCompletedByInitials,
                          radius: 10,
                          color: AppColors.yellow,
                          textColor: AppColors.main,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                          'on',
                          style: TextStyle(color: AppColors.yellow),
                      ),
                      const SizedBox(width: 4),
                      DateLabel(
                          date: snapshot.pmCompletedAt,
                          color: color,
                      ),
                  ],
              ),
            ],
            ],
          ),
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: 0.75,
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}