import 'package:flutter/material.dart';
import '../../config/device_config.dart';
import '../../theme/app_colors.dart';
import '../hold_to_confirm_button.dart';
import '../ornate_card.dart';

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
class InspectionPromptCard extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onRecordIssue;
  final VoidCallback onNoIssues;
  final VoidCallback? onDismiss;

  const InspectionPromptCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRecordIssue,
    required this.onNoIssues,
    this.color = AppColors.red,
    this.icon = Icons.warning,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final recordIssueButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.mainBackground,
        side: BorderSide(color: color, width: 1.3),
      ),
      onPressed: onRecordIssue,
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
      onConfirmed: onNoIssues,
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
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message, style: TextStyle(color: color)),
            const SizedBox(height: 12),
            buttons,
            if (onDismiss != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text("Dismiss", style: TextStyle(color: color)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
