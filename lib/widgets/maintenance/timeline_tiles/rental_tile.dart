import 'package:flutter/material.dart';
import '../../../models/lift_rental_history_item.dart';
import '../../../theme/app_colors.dart';
import '../../ornate_card.dart';

class RentalTile extends StatelessWidget {
  final LiftRentalHistoryItem rental;

  const RentalTile(this.rental, {super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OrnateCard(
        color: AppColors.mainLight,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental.customerName ?? "Rental",
                          style: const TextStyle(
                            color: AppColors.yellow,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_formatDate(rental.startDate)}",
                          style: const TextStyle(
                            color: AppColors.yellow,
                          ),
                        ),
                        Text(
                          "to",
                          style: TextStyle(
                            color: AppColors.yellow.withOpacity(.7),
                          ),
                        ),
                        Text(
                          "${_formatDate(rental.endDate)}",
                          style: const TextStyle(
                            color: AppColors.yellow,
                          ),
                        ),
                        if (rental.status != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            rental.status!,
                            style: const TextStyle(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
