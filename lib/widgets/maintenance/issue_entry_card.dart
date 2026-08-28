import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../curved_stack_card.dart';
import '../hold_to_confirm_button.dart';
import '../watermark_title.dart';

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
  final TextEditingController _notesController =
      TextEditingController();

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

  Widget _buildNotesInput(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.75,
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
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: GestureDetector(
              onTap: () async {
                final controller = TextEditingController(
                  text: _notesController.text,
                );

                final notes = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: color,
                      title: const Text(
                        "Edit Notes",
                        style: TextStyle(
                          color: AppColors.main,
                        ),
                      ),
                      content: SizedBox(
                        width: 300,
                        child: TextField(
                          controller: controller,
                          maxLines: 5,
                          autofocus: true,
                          style: const TextStyle(
                            color: AppColors.main,
                          ),
                          cursorColor: AppColors.main,
                          decoration: const InputDecoration(
                            hintText: "Enter notes...",
                            hintStyle: TextStyle(
                              color: AppColors.main,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.main,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.main,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: AppColors.main,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.main,
                            foregroundColor: color,
                          ),
                          onPressed: () {
                            Navigator.pop(
                              context,
                              controller.text.trim(),
                            );
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    );
                  },
                );

                if (notes == null) return;

                setState(() {
                  _notesController.text = notes;
                });
              },
              child: Image.asset(
                'assets/notes.png',
                width: 20,
                height: 20,
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
    final title = isRepair
        ? 'New Repair'
        : 'New Issue';

    final hasNotes = _notesController.text.trim().isNotEmpty;

    return CurvedStackCard(
      color: isRepair ? AppColors.green : AppColors.red,
      position: widget.position,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WatermarkTitle(
            text: title,
            glyph: isRepair
                ? Icons.build_outlined
                : Icons.report_problem_outlined,
            glyphSize: 130,
            glyphAlignment: const Alignment(0, -0.6),
          ),

          const SizedBox(height: 12),

          _buildNotesInput(AppColors.yellow),

          const SizedBox(height: 12),

          FractionallySizedBox(
            widthFactor: 0.8,
            child: HoldToConfirmButton(
              icon: hasNotes ? const Icon(Icons.check) : null,
              label: hasNotes ? 'Record' : 'Notes required',
              baseColor: AppColors.main,
              textColor: AppColors.yellow,
              progressColor: AppColors.yellow,
              holdDuration: const Duration(seconds: 2),
              enabled: hasNotes,
              onConfirmed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}