import 'package:flutter/material.dart';
import '../beaded_dot_border_painter.dart';

// Wraps a circular button with the same hand-scattered, slowly wandering
// beaded-dot border used on the curved content cards elsewhere on this page
// (see CurvedStackCard), so the selected state in the mode-selector rows
// echoes that visual language instead of a plain glow.
class BeadedCircleBorder extends StatefulWidget {
  final Color color;
  final Widget child;

  const BeadedCircleBorder({
    super.key,
    required this.color,
    required this.child,
  });

  @override
  State<BeadedCircleBorder> createState() => _BeadedCircleBorderState();
}

class _BeadedCircleBorderState extends State<BeadedCircleBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController.unbounded(
    vsync: this,
  )..repeat(min: 0, max: 100000, period: const Duration(seconds: 100000));

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CircleBeadedPainter(
        color: widget.color,
        time: _time,
      ),
      child: widget.child,
    );
  }
}

class _CircleBeadedPainter extends BeadedDotBorderPainter {
  _CircleBeadedPainter({required super.color, required super.time});

  @override
  Path pathForSize(Size size) => Path()..addOval(Offset.zero & size);
}
