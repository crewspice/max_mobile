import 'package:flutter/material.dart';
import '../../models/lift_maintenance_history_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../curved_stack_card.dart';
import '../date_label.dart';
import '../hold_to_confirm_button.dart';
import '../user_avatar.dart';
import '../watermark_title.dart';
import 'maintenance_dialogs.dart';

class RepairCard extends StatefulWidget {
  final LiftMaintenanceHistoryItem action;
  final String currentUserId;
  final VoidCallback onResolved;
  final StackPosition position;

  const RepairCard({
    super.key,
    required this.action,
    required this.currentUserId,
    required this.onResolved,
    this.position = StackPosition.only,
  });

  @override
  State<RepairCard> createState() => _RepairCardState();
}

class _RepairCardState extends State<RepairCard> {
  bool _noRepairNeeded = false;
  String? _repairNotes;

  @override
  void initState() {
    super.initState();
    _repairNotes = widget.action.repairNotes;
  }

  @override
  Widget build(BuildContext context) {
    return CurvedStackCard(
        color: AppColors.red,
        position: widget.position,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Stack(
              clipBehavior: Clip.none,
              children: [
                // Reserves the date's own layout space (so the title below
                // sits exactly where it always has) without painting it —
                // the visible date is the Positioned copy below, painted
                // after the title so it reads on top of the watermark glyph
                // wherever the two overlap.
                Column(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: DateLabel(
                        date: widget.action.createdAt,
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: WatermarkTitle(
                        text: widget.action.actionTypeName ?? 'Needs Repair',
                        glyph: Icons.warning_amber_outlined,
                        glyphSize: 220,
                        glyphAlignment: const Alignment(0, -0.35),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DateLabel(
                      date: widget.action.createdAt,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if ((widget.action.notes ?? '').isNotEmpty)
              Center(
                child: Text(
                  '"${widget.action.notes}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            if ((widget.action.reportedBy ?? '').isNotEmpty)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.action.reportedByInitials != null) ...[
                      UserAvatar(
                        initials: widget.action.reportedByInitials,
                        radius: 10,
                        color: AppColors.yellow,
                        textColor: AppColors.main,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.action.notes != null &&
                              widget.action.notes!.isNotEmpty
                          ? '- ${widget.action.reportedBy}'
                          : 'Reported by: ${widget.action.reportedBy}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            Center(
              child: FractionallySizedBox(
              widthFactor: 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        Expanded(
                            child: Text(
                              (_repairNotes ?? '').isNotEmpty
                                  ? _repairNotes!
                                  : 'No repair notes',
                                style: const TextStyle(
                                color: AppColors.yellow,
                                fontStyle: FontStyle.italic,
                                ),
                            ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 22,
                            height: 22,
                            child: GestureDetector(
                            onTap: () async {
                                final notes = await showRepairNotesDialog(
                                context,
                                initialValue: widget.action.repairNotes ?? '',
                                );

                                if (notes == null) return;

                                await ApiService().updateMaintenanceRepairNotes(
                                  widget.action.actionId!,
                                  notes,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _repairNotes = notes;
                                });
                            },
                            child: Image.asset(
                                'assets/notes.png',
                                width: 20,
                                height: 20,
                                color: AppColors.yellow,
                            ),
                            ),
                        ),
                        ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'No Repair Needed',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _noRepairNeeded,
                          activeColor: AppColors.yellow,
                          checkColor: AppColors.mainBackground,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) {
                            setState(() {
                              _noRepairNeeded = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: HoldToConfirmButton(
                  icon: const Icon(Icons.check),
                  label: 'Resolve',
                  baseColor: AppColors.main,
                  textColor: AppColors.yellow,
                  progressColor: AppColors.yellow,
                  holdDuration: const Duration(seconds: 2),
                  onConfirmed: () async {
                    await ApiService().resolveMaintenanceAction(
                      actionId: widget.action.actionId!,
                      resolvedByInitial: widget.currentUserId,
                      noRepairNeeded: _noRepairNeeded,
                      repairNotes: _repairNotes ?? '',
                    );

                    widget.onResolved();
                  },
                ),
              ),
            ),
          ],
        ),
    );
  }
}