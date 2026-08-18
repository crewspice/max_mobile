import 'package:flutter/material.dart';
import '../../../models/lift_maintenance_history_item.dart';
import '../../../theme/app_colors.dart';
import '../../ornate_card.dart';
import '../../user_avatar.dart';

class IssueTile extends StatelessWidget {
  final LiftMaintenanceHistoryItem issue;

  const IssueTile(
    this.issue, {
    super.key,
  });

  String _date(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Text _line(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];

    if (issue.actionTypeName != null) {
      lines.add(_line('Issue: ${issue.actionTypeName}'));
    }

    if (issue.performedByName != null) {
      lines.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                initials: issue.performedByInitials,
                radius: 10,
                color: AppColors.green,
                textColor: AppColors.main,
              ),
              const SizedBox(width: 6),
              _line('Performed by: ${issue.performedByName}'),
            ],
          ),
        ),
      );
    }

    if (issue.reportedBy != null) {
      lines.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (issue.reportedByInitials != null) ...[
                UserAvatar(
                  initials: issue.reportedByInitials,
                  radius: 10,
                  color: AppColors.green,
                  textColor: AppColors.main,
                ),
                const SizedBox(width: 6),
              ],
              _line('Reported by: ${issue.reportedBy}'),
            ],
          ),
        ),
      );
    }

    if (issue.performedAt != null) {
      lines.add(_line('Date: ${_date(issue.performedAt)}'));
    }

    if (issue.partAction != null) {
      lines.add(_line('Action: ${issue.partAction}'));
    }

    if (issue.quantity != null) {
      lines.add(_line('Quantity: ${issue.quantity}'));
    }

    if (issue.noRepairNeeded) {
      lines.add(_line('No repair needed'));
    }

    if (issue.repairNotes != null) {
      lines.add(_line('Repair notes: ${issue.repairNotes}'));
    }

    if (issue.notes != null) {
      lines.add(_line('Notes: ${issue.notes}'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OrnateCard(
        color: AppColors.mainLight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
      ),
    );
  }
}
