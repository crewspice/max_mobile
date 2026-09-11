import 'package:flutter/material.dart';
import '../../config/device_config.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../curved_stack_card.dart';
import '../hold_to_confirm_button.dart';
import '../watermark_title.dart';
import 'maintenance_dialogs.dart';
import 'repair_card.dart';

enum IssueEntryMode { issue, repair }

class IssueEntryCard extends StatefulWidget {
  final int liftId;
  final String currentUserId;
  final IssueEntryMode mode;
  final VoidCallback onComplete;
  final StackPosition position;

  const IssueEntryCard({
    super.key,
    required this.liftId,
    required this.currentUserId,
    required this.mode,
    required this.onComplete,
    this.position = StackPosition.only,
  });

  @override
  State<IssueEntryCard> createState() => _IssueEntryCardState();
}

class _IssueEntryCardState extends State<IssueEntryCard> {
  final TextEditingController _notesController = TextEditingController();

  bool get isRepair => widget.mode == IssueEntryMode.repair;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_notesController.text.trim().isEmpty) return;

    try {
      await ApiService().submitMaintenanceAction(
        liftId: widget.liftId,
        notes: _notesController.text.trim(),
        createdByInitial: widget.currentUserId,
        isRepair: isRepair,
      );

      if (!mounted) return;

      _notesController.clear();

      widget.onComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            isRepair
                ? 'Repair recorded successfully'
                : 'Issue recorded successfully',
            style: const TextStyle(
              color: AppColors.green,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            'Failed: $e',
            style: const TextStyle(
              color: AppColors.red,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNotesInput(Color color, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: Center(
        child: FractionallySizedBox(
          // Now that this card is narrowed to RepairCard.cardWidthFactor
          // like RepairCard's own, matching RepairCard's own inner fraction
          // here keeps the two notes rows x-aligned.
          widthFactor: RepairCard.notesRowWidthFactor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _notesController.text.isNotEmpty
                      ? _notesController.text
                      : 'No notes yet',
                  style: TextStyle(
                    color: color,
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              SizedBox(
                width: 22 * scale,
                height: 22 * scale,
                child: GestureDetector(
                  onTap: () async {
                    final notes = await showNotesDialog(
                      context,
                      title: "Edit Notes",
                      initialValue: _notesController.text,
                      hintText: "Enter notes...",
                      color: color,
                    );

                    if (notes == null) return;

                    setState(() {
                      _notesController.text = notes;
                    });
                  },
                  child: Image.asset(
                    'assets/notes.png',
                    width: 20 * scale,
                    height: 20 * scale,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = DeviceConfig.maintenanceBoxScale;
    final title = isRepair ? 'New Repair' : 'New Issue';

    final hasNotes = _notesController.text.trim().isNotEmpty;

    // Narrowed to match RepairCard's own card width, rather than stretching
    // full-width like a plain form would.
    return Align(
      child: FractionallySizedBox(
        widthFactor: RepairCard.cardWidthFactor,
        child: CurvedStackCard(
          color: isRepair ? AppColors.green : AppColors.red,
          position: widget.position,
          padding: RepairCard.borderPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WatermarkTitle(
                text: title,
                glyph: isRepair
                    ? Icons.build_outlined
                    : Icons.report_problem_outlined,
                glyphSize: 130 * scale,
                glyphAlignment: const Alignment(0, -1.0),
                fontSize: 16 * scale,
              ),
              SizedBox(height: 12 * scale),
              _buildNotesInput(AppColors.yellow, scale),
              SizedBox(height: 12 * scale),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: HoldToConfirmButton(
                  icon: hasNotes ? Icon(Icons.check, size: 20 * scale) : null,
                  // iPhone's narrower button has no room for "Notes
                  // required" without crowding - it just stays labeled
                  // "Record" (still disabled until notes are entered) and
                  // relies on onDisabledTap below to explain why instead.
                  label: hasNotes || DeviceConfig.isIphone
                      ? 'Record'
                      : 'Notes required',
                  baseColor: AppColors.main,
                  textColor: AppColors.yellow,
                  progressColor: AppColors.yellow,
                  textSize: 14 * scale,
                  holdDuration: const Duration(seconds: 2),
                  enabled: hasNotes,
                  onDisabledTap: DeviceConfig.isIphone
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.mainBackground,
                              content: Text(
                                'Notes are required before recording',
                                style: TextStyle(color: AppColors.red),
                              ),
                            ),
                          );
                        }
                      : null,
                  onConfirmed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
