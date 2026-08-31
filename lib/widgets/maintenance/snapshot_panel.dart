import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../models/lift_maintenance_snapshot.dart';
import '../../theme/app_colors.dart';
import '../../views/pm_checklist_screen.dart';
import '../curved_stack_card.dart';
import '../date_label.dart';
import '../user_avatar.dart';
import '../watermark_title.dart';
import 'repair_card.dart';

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

    // This card's content (a short title, small avatar row, and date) never
    // spans very wide, so it hugs that content's own width rather than
    // stretching to match its siblings - but it's still forced to at least
    // buttonBoxWidth (plus room for the button itself) so the border
    // actually grows to enclose the checklist button below instead of
    // leaving it to float outside a too-narrow card.
    //
    // The checklist button is positioned separately, against this Stack's
    // full (unshrunk) width rather than the card's own - its fraction
    // replicates RepairCard's own notes button inset so the two buttons
    // land at the same x.
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonBoxWidthFactor =
            RepairCard.cardWidthFactor * RepairCard.notesRowWidthFactor;
        final buttonBoxWidth = constraints.maxWidth * buttonBoxWidthFactor;
        const buttonClearance = 44.0;

        return Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: buttonBoxWidth + buttonClearance,
                ),
                child: IntrinsicWidth(
                  child: CurvedStackCard(
                    color: color,
                    position: position,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WatermarkTitle(
                          text: title,
                          glyph: good
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          glyphSize: 80,
                          glyphAlignment: const Alignment(-1.3, -0.4),
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
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: buttonBoxWidthFactor,
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
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
