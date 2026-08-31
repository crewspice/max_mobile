import 'package:flutter/material.dart';
import '../../../models/lift_rental_history_item.dart';
import '../../../theme/app_colors.dart';
import '../../ornate_card.dart';

class RentalTile extends StatelessWidget {
  final LiftRentalHistoryItem rental;

  const RentalTile(this.rental, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      // Without this, the card stretches to fill whatever width the
      // timeline's flexible content slot hands it instead of hugging its
      // own text.
      child: IntrinsicWidth(
        child: OrnateCard(
          color: AppColors.mainLight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rental.customerName ?? "Rental",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    rental.siteName,
                    rental.streetAddress,
                    rental.city,
                  ].where((e) => e != null && e!.isNotEmpty).join("\n"),
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.yellow,
                  ),
                ),
                if (rental.endDate == null || rental.status != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    rental.status ??
                        (rental.endDate == null ? "Still on Rent" : ""),
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontWeight: FontWeight.bold,
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
