import 'package:flutter/material.dart';
import '../../../models/lift_pm_history_item.dart';
import '../../../theme/app_colors.dart';
import '../../date_label.dart';
import '../../ornate_card.dart';
import '../../user_avatar.dart';

class PmTile extends StatelessWidget {
  final LiftPmHistoryItem pm;

  const PmTile(
    this.pm, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OrnateCard(
        color: AppColors.mainLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              Text(
                'PM',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              UserAvatar(
                initials: pm.completedByInitials,
                radius: 12,
                color: AppColors.green,
                textColor: AppColors.main,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pm.completedByName ?? 'Unknown technician',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DateLabel(
                date: pm.completedAt,
                color: AppColors.green,
                unknownLabel: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
