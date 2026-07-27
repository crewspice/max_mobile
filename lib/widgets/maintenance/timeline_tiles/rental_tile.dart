import 'package:flutter/material.dart';
import '../../../models/lift_rental_history_item.dart';

class RentalTile extends StatelessWidget {
  final LiftRentalHistoryItem rental;

  const RentalTile(
    this.rental,
    {super.key}
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          rental.customerName ?? "Rental",
        ),
        subtitle: Text(
          "${rental.startDate ?? ''} → ${rental.endDate ?? ''}",
        ),
      ),
    );
  }
}