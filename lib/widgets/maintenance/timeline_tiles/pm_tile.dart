import 'package:flutter/material.dart';
import '../../../config/device_config.dart';
import '../../../models/lift_pm_history_item.dart';
import '../../../theme/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: UserAvatar(
        initials: pm.completedByInitials,
        radius: 12 * DeviceConfig.timelineNodeScale,
        color: AppColors.yellow,
        textColor: AppColors.main,
      ),
    );
  }
}
