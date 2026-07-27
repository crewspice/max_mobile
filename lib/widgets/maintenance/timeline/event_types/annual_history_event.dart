import 'package:flutter/material.dart';
import '../timeline_event.dart';

class AnnualHistoryEvent extends TimelineEvent {
  AnnualHistoryEvent(DateTime date)
      : super(
          date: date,
          type: TimelineEventType.annual,
        );

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}