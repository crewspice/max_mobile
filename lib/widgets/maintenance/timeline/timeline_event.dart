import 'package:flutter/material.dart';

enum TimelineEventType { pm, rental, issue, annual }

abstract class TimelineEvent {
  DateTime get start;
  DateTime get end;

  TimelineEventType get type;

  bool get isSpan => start != end;

  // The date(s) shown in the timeline's shared left-hand date column,
  // separate from build()'s card content - most events have just one, but a
  // rental spans two (start and end).
  List<DateTime?> get displayDates;

  Widget build(BuildContext context);
}