import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/device_config.dart';
import '../../theme/app_colors.dart';
import '../hold_to_confirm_button.dart';
import '../ornate_card.dart';
import '../watermark_title.dart';

// Number of days without a recorded inspection before a truck is flagged.
// Shared by the rental-list rolling-week check and the truck-view prompt so
// both surfaces warn on the same schedule.
const int kInspectionWindowDays = 7;

// The truck-inspection prompt: an ornate-bordered card with a title row,
// a byline, and a pair of thin-outlined actions (Record Issue / No Issues),
// stacked on iPhone where they'd otherwise be cramped side by side. Reused
// wherever a driver is asked to clear an inspection - the mandatory
// rolling-week overlay on rental list, the mandatory card on the truck page,
// and the truck page's optional manual check-in.
//
// Tapping "Record Issue" doesn't launch a separate sheet on top of this one
// - the card itself swaps its body for the photo/description form, so the
// same ornate-bordered box just grows to fit whichever step the driver is
// on.
class InspectionPromptCard extends StatefulWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final Future<bool> Function(File image, String description) onSubmitIssue;
  final VoidCallback onNoIssues;
  final VoidCallback? onDismiss;
  // Fired after a successful issue submission, in addition to the card's
  // own snackbar/collapse - e.g. so a caller can drop the truck out of a
  // "stale" list. Optional: the truck view's mandatory prompt has no extra
  // bookkeeping to do here.
  final VoidCallback? onIssueSubmitted;
  // Callers tune these per placement (e.g. smaller on the truck page, which
  // has less room above the card, vs. the rental-list overlay) rather than
  // sharing one fixed look.
  final double glyphSize;
  final Alignment glyphAlignment;

  const InspectionPromptCard({
    super.key,
    required this.title,
    required this.message,
    required this.onSubmitIssue,
    required this.onNoIssues,
    this.color = AppColors.red,
    this.icon = Icons.warning,
    this.onDismiss,
    this.onIssueSubmitted,
    this.glyphSize = 190,
    this.glyphAlignment = const Alignment(0, -0.6),
  });

  @override
  State<InspectionPromptCard> createState() => _InspectionPromptCardState();
}

class _InspectionPromptCardState extends State<InspectionPromptCard> {
  bool _recordingIssue = false;
  bool _isSubmitting = false;
  XFile? _selectedImage;
  final TextEditingController _descriptionController =
      TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool camera = true}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo required")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.onSubmitIssue(
      File(_selectedImage!.path),
      _descriptionController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (success) {
        _recordingIssue = false;
        _selectedImage = null;
        _descriptionController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Issue submitted' : 'Submission failed'),
      ),
    );

    if (success) widget.onIssueSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return OrnateCard(
      color: color,
      backgroundColor: AppColors.mainBackground,
      padding: EdgeInsets.zero,
      child: Container(
        color: AppColors.mainBackground,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _recordingIssue
              ? _buildIssueForm(color)
              : _buildPrompt(color),
        ),
      ),
    );
  }

  List<Widget> _buildPrompt(Color color) {
    // Same outlined style on both buttons - explicit shape/padding rather
    // than each control's own defaults - so Record Issue (a plain
    // OutlinedButton) and No Issues (HoldToConfirmButton's outlined mode)
    // land on identical corners and insets.
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const buttonPadding =
        EdgeInsets.symmetric(horizontal: 10, vertical: 12);

    final recordIssueButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.mainBackground,
        side: BorderSide(color: color, width: 1.3),
        padding: buttonPadding,
        shape: buttonShape,
      ),
      onPressed: () => setState(() => _recordingIssue = true),
      icon: Icon(Icons.report_problem, color: color),
      label: Text("Record Issue", style: TextStyle(color: color)),
    );

    final noIssuesButton = HoldToConfirmButton(
      label: "No Issues",
      baseColor: color,
      textColor: color,
      progressColor: color,
      outlined: true,
      icon: Icon(Icons.check, color: color),
      onConfirmed: widget.onNoIssues,
    );

    final buttons = DeviceConfig.isIphone
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              recordIssueButton,
              const SizedBox(height: 10),
              noIssuesButton,
            ],
          )
        : Row(
            children: [
              Expanded(child: recordIssueButton),
              const SizedBox(width: 10),
              Expanded(child: noIssuesButton),
            ],
          );

    return [
      Center(
        child: WatermarkTitle(
          text: widget.title,
          glyph: widget.icon,
          glyphSize: widget.glyphSize,
          glyphAlignment: widget.glyphAlignment,
          textColor: color,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text(
          widget.message,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
      const SizedBox(height: 12),
      buttons,
      if (widget.onDismiss != null) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: widget.onDismiss,
            child: Text("Dismiss", style: TextStyle(color: color)),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildIssueForm(Color color) {
    final photoButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: AppColors.mainBackground,
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return [
      Row(
        children: [
          IconButton(
            onPressed:
                _isSubmitting ? null : () => setState(() => _recordingIssue = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.arrow_back, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Report Issue",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: photoButtonStyle,
              onPressed: () => _pickImage(),
              child: const Text("Take Photo"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: photoButtonStyle,
              onPressed: () => _pickImage(camera: false),
              icon: const Icon(Icons.upload),
              label: const Text("Upload"),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_selectedImage != null) ...[
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(File(_selectedImage!.path), height: 120),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _descriptionController,
        maxLines: 3,
        style: TextStyle(color: color),
        decoration: InputDecoration(
          labelText: "Describe the issue",
          labelStyle: TextStyle(color: color),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.mainBackground,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Submit Issue"),
        ),
      ),
    ];
  }
}
