import 'package:flutter/material.dart';
import '../../config/device_config.dart';
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
    final scale = DeviceConfig.maintenanceBoxScale;

    final needsAnnual = snapshot.needsAnnual == true;
    final needsPm = snapshot.upToDate != true;

    final good = !needsAnnual && !needsPm;
    final color = good ? AppColors.green : AppColors.red;

    final title = needsAnnual
        ? 'Needs Annual'
        : needsPm
            ? 'Needs PM'
            : 'Up to date';

    final checklistButton = InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PmChecklistScreen(),
          ),
        );
      },
      child: Icon(
        Icons.checklist,
        color: AppColors.yellow,
        size: 26 * scale,
      ),
    );

    final titleWatermark = WatermarkTitle(
      text: title,
      glyph:
          good ? Icons.check_circle_outline : Icons.warning_amber_outlined,
      glyphSize: 80 * scale,
      glyphAlignment: const Alignment(-1.3, -0.4),
      fontSize: 16 * scale,
    );

    // iPhone: the checklist button rides inline as the tail end of the
    // title line itself, so the card just hugs that combined content -
    // no need for the cross-card x-alignment dance below (moto_g/iPad
    // keep that exactly as-is; this branch never touches them).
    if (DeviceConfig.isIphone) {
      return Center(
        child: IntrinsicWidth(
          child: CurvedStackCard(
            color: color,
            position: position,
            padding: EdgeInsets.symmetric(
              horizontal: 18 * scale,
              vertical: 16 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    titleWatermark,
                    SizedBox(width: 8 * scale),
                    checklistButton,
                  ],
                ),
                if (snapshot.pmId != null) ...[
                  SizedBox(height: 6 * scale),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      UserAvatar(
                        initials: snapshot.pmCompletedByInitials,
                        radius: 10 * scale,
                        color: AppColors.yellow,
                        textColor: AppColors.main,
                      ),
                      SizedBox(width: 6 * scale),
                      Text(
                        'on',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontSize: 14 * scale,
                        ),
                      ),
                      SizedBox(width: 4 * scale),
                      DateLabel(
                        date: snapshot.pmCompletedAt,
                        color: color,
                        fontSize: 14 * scale,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

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
        final buttonClearance = 44.0 * scale;

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
                    padding: EdgeInsets.symmetric(
                      horizontal: 18 * scale,
                      vertical: 16 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WatermarkTitle(
                          text: title,
                          glyph: good
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          glyphSize: 80 * scale,
                          glyphAlignment: const Alignment(-1.3, -0.4),
                          fontSize: 16 * scale,
                        ),
                        if (snapshot.pmId != null) ...[
                          SizedBox(height: 6 * scale),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              UserAvatar(
                                initials: snapshot.pmCompletedByInitials,
                                radius: 10 * scale,
                                color: AppColors.yellow,
                                textColor: AppColors.main,
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                'on',
                                style: TextStyle(
                                  color: AppColors.yellow,
                                  fontSize: 14 * scale,
                                ),
                              ),
                              SizedBox(width: 4 * scale),
                              DateLabel(
                                date: snapshot.pmCompletedAt,
                                color: color,
                                fontSize: 14 * scale,
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
                    child: Icon(
                      Icons.checklist,
                      color: AppColors.yellow,
                      size: 26 * scale,
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
