import 'package:flutter/material.dart';
import '../../../../models/lift_rental_history_item.dart';
import '../../timeline_tiles/rental_tile.dart';
import '../timeline_event.dart';

class RentalHistoryEvent extends TimelineEvent {

  final LiftRentalHistoryItem rental;

  RentalHistoryEvent(this.rental);

  @override
  DateTime get start =>
      rental.startDate ?? DateTime.now();

  @override
  DateTime get end =>
      rental.endDate ?? start;

  @override
  Widget build(BuildContext context) {
    return RentalTile(rental);
  }
}