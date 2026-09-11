import 'package:flutter/material.dart';
import '../../../config/device_config.dart';
import '../../../models/lift_rental_history_item.dart';
import '../../../theme/app_colors.dart';
import '../../ornate_card.dart';

class RentalTile extends StatelessWidget {
  final LiftRentalHistoryItem rental;

  const RentalTile(this.rental, {super.key});

  @override
  Widget build(BuildContext context) {
    final scale = DeviceConfig.timelineContentScale;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10 * scale),
      // Without this, the card stretches to fill whatever width the
      // timeline's flexible content slot hands it instead of hugging its
      // own text.
      child: IntrinsicWidth(
        child: OrnateCard(
          color: AppColors.mainLight,
          child: Padding(
            padding: EdgeInsets.all(8 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rental.customerName ?? "Rental",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17 * scale,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  [
                    rental.siteName,
                    rental.streetAddress,
                    rental.city,
                  ].where((e) => e != null && e!.isNotEmpty).join("\n"),
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 14 * scale,
                  ),
                ),
                if (rental.endDate == null || rental.status != null) ...[
                  SizedBox(height: 8 * scale),
                  Text(
                    rental.status ??
                        (rental.endDate == null ? "Still on Rent" : ""),
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
