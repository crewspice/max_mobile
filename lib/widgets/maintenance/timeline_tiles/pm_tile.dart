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
    final scale = DeviceConfig.timelineContentScale;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20 * scale),
      child: UserAvatar(
        initials: pm.completedByInitials,
        radius: 12 * scale,
        color: AppColors.yellow,
        textColor: AppColors.main,
      ),
    );
  }
}
