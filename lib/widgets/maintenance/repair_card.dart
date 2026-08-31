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
  // How much of the status stack's width this card's own border occupies -
  // exposed so SnapshotPanel's checklist button and IssueEntryCard's notes
  // row can size themselves to x-align with this card's notes line instead
  // of guessing a matching fraction.
  static const double cardWidthFactor = 0.68;
  // How much of this card's own (already narrowed) width the notes/resolve
  // controls occupy - combined with cardWidthFactor above, this is the
  // fraction of the full stack width other cards should match to x-align
  // with the notes line.
  static const double notesRowWidthFactor = 0.75;
  // The gap between this card's own beaded border and its content -
  // exposed so IssueEntryCard can match it exactly instead of guessing a
  // matching value.
  static const EdgeInsets borderPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 8);

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
    // Content here (title, notes, a date row, the resolve controls) doesn't
    // span very wide either, so this stays narrower than the full stack
    // width instead of stretching to match its siblings. Referenced
    // elsewhere (SnapshotPanel's checklist button, IssueEntryCard's notes
    // row) so those x-align with this card's own notes line - update those
    // if this fraction changes.
    return Align(
      child: FractionallySizedBox(
        widthFactor: RepairCard.cardWidthFactor,
        child: CurvedStackCard(
          color: AppColors.red,
          position: widget.position,
          padding: RepairCard.borderPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: WatermarkTitle(
                  text: 'Needs Repair',
                  glyph: Icons.warning_amber_outlined,
                  glyphSize: 190,
                  glyphAlignment: const Alignment(0, -0.8),
                ),
              ),
              const SizedBox(height: 8),
              if ((widget.action.notes ?? '').isNotEmpty)
                Center(
                  child: FractionallySizedBox(
                    widthFactor: RepairCard.notesRowWidthFactor,
                    child: Text(
                      '"${widget.action.notes}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.action.reportedByInitials != null) ...[
                      UserAvatar(
                        initials: widget.action.reportedByInitials,
                        radius: 10,
                        color: AppColors.yellow,
                        textColor: AppColors.main,
                      ),
                      const SizedBox(width: 6),
                    ] else if ((widget.action.reportedBy ?? '').isNotEmpty) ...[
                      Text(
                        '- ${widget.action.reportedBy}',
                        style: const TextStyle(color: AppColors.yellow),
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Text(
                      'on',
                      style: TextStyle(color: AppColors.yellow),
                    ),
                    const SizedBox(width: 4),
                    DateLabel(
                      date: widget.action.createdAt,
                      color: AppColors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: FractionallySizedBox(
                  widthFactor: RepairCard.notesRowWidthFactor,
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
                                    initialValue:
                                        widget.action.repairNotes ?? '',
                                  );

                                  if (notes == null) return;

                                  await ApiService()
                                      .updateMaintenanceRepairNotes(
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
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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
        ),
      ),
    );
  }
}
