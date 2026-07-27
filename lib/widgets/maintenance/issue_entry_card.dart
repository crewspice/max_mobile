import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../hold_to_confirm_button.dart';
import '../ornate_card.dart';

enum IssueEntryMode { issue, repair }

class IssueEntryCard extends StatefulWidget {
  final int liftId;
  final String currentUserId;
  final IssueEntryMode mode;
  final VoidCallback onComplete;

  const IssueEntryCard({
    super.key,
    required this.liftId,
    required this.currentUserId,
    required this.mode,
    required this.onComplete,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Text(
                _notesController.text.isNotEmpty
                    ? _notesController.text
                    : 'No notes yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isRepair
        ? 'Record Repair'
        : 'Record Issue';

    final button = isRepair
        ? 'Save Repair'
        : 'Submit Issue';

    return OrnateCard(
      color: AppColors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildNotesInput(AppColors.red),

          const SizedBox(height: 12),

          HoldToConfirmButton(
            icon: const Icon(Icons.check),
            label: button,
            baseColor: AppColors.main,
            textColor: AppColors.red,
            progressColor: AppColors.red,
            holdDuration: const Duration(seconds: 2),
            onConfirmed: _submit,
          ),
        ],
      ),
    );
  }
}