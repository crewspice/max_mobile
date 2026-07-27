import 'package:flutter/material.dart';

abstract class TimelineEvent {
  DateTime get start;
  DateTime get end;

  bool get isSpan => start != end;

  Widget build(BuildContext context);
}