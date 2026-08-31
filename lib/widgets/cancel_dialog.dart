import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'hold_to_confirm_button.dart';
import 'ornate_card.dart';
import 'watermark_title.dart';

// The stop-cancellation prompt: an ornate-bordered card styled to match
// InspectionPromptCard, shared by RentalCard and ServiceCard. The title's
// second word ("Delivery" / "Pickup" / "Service") is supplied by the caller
// so the copy matches whichever stop type is being cancelled.
Future<void> showCancelDialog({
  required BuildContext context,
  required Color color,
  required String stopType,
  required Future<bool> Function(bool onArrival) onCancel,
  required Future<void> Function() onSuccess,
}) {
  int selected = 0;

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          final closeButton = OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.mainBackground,
              side: BorderSide(color: color, width: 1.3),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Close", style: TextStyle(color: color)),
          );

          final submitButton = HoldToConfirmButton(
            icon: const Icon(Icons.cancel_schedule_send_outlined),
            label: "Submit",
            baseColor: color,
            progressColor: color,
            textColor: color,
            outlined: true,
            holdDuration: const Duration(seconds: 2),
            onConfirmed: () async {
              final bool onArrival = selected == 1;

              Navigator.pop(dialogContext);

              final success = await onCancel(onArrival);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? (onArrival
                            ? "Cancelled after arrival"
                            : "Cancelled before arrival")
                        : "Cancellation failed",
                  ),
                ),
              );

              if (success) {
                await onSuccess();
              }
            },
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: OrnateCard(
              color: color,
              backgroundColor: AppColors.mainBackground,
              padding: EdgeInsets.zero,
              child: Container(
                color: AppColors.mainBackground,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: WatermarkTitle(
                        text: "Cancel $stopType",
                        glyph: Icons.block,
                        glyphSize: 220,
                        glyphAlignment: const Alignment(0, -0.8),
                        textColor: color,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Text("Was it", style: TextStyle(color: color)),
                        ToggleButtons(
                          isSelected: [selected == 0, selected == 1],
                          onPressed: (index) {
                            setState(() {
                              selected = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          borderColor: color,
                          selectedBorderColor: color,
                          fillColor: color,
                          selectedColor: AppColors.mainBackground,
                          color: color,
                          constraints: const BoxConstraints(
                            minWidth: 64,
                            minHeight: 30,
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("before"),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("after"),
                            ),
                          ],
                        ),
                        Text("arrival?", style: TextStyle(color: color)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    submitButton,
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: closeButton,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
