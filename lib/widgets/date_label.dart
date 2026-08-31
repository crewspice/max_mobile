import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Renders a date as m/d/yy with the "/" separators swapped for small
// gradient dots — center-out from the card's background to the element
// color, the same radial treatment as the border layer's beads — so the
// separators read as part of the card's beaded-circle visual language
// instead of plain punctuation. The digits themselves are also styled in
// the element color rather than a generic text color.
class DateLabel extends StatelessWidget {
  final DateTime? date;
  final Color color;
  final double fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final String unknownLabel;

  const DateLabel({
    super.key,
    required this.date,
    required this.color,
    this.fontSize = 14,
    this.fontWeight,
    this.fontStyle,
    this.unknownLabel = 'Unknown',
  });

  // Scales with fontSize (6.0 at the default 14) so a larger date label
  // grows its separator dots to match instead of leaving them undersized.
  static const double _dotDiameterRatio = 6.0 / 14.0;

  double get _dotDiameter => fontSize * _dotDiameterRatio;

  @override
  Widget build(BuildContext context) {
    final d = date;
    final style = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );

    if (d == null) {
      return Text(unknownLabel, style: style);
    }

    final parts = [
      '${d.month}',
      '${d.day}',
      (d.year % 100).toString().padLeft(2, '0'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(parts[0], style: style),
        _dot(),
        Text(parts[1], style: style),
        _dot(),
        Text(parts[2], style: style),
      ],
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: _dotDiameter,
        height: _dotDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [AppColors.mainBackground, Colors.white],
            stops: [0.0, 0.5],
          ),
        ),
      ),
    );
  }
}
