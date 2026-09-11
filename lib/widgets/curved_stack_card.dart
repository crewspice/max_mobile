import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/device_config.dart';
import 'beaded_dot_border_painter.dart';

// Where a card sits within a vertical stack of related cards (e.g. the
// annual/PM status card, any open issue cards, and the record repair/issue
// entry card together). Kept for callers that still track a card's place in
// the stack, but the shape itself no longer varies by position - every card
// is the same rounded rectangle regardless of its neighbors.
enum StackPosition { only, top, medial, bottom }

class CurvedStackCard extends StatefulWidget {
  // The border layer's largest dot radius — exposed so other widgets that
  // want to echo the card's beaded-circle visual language (e.g. DateLabel's
  // slash-replacement dots) can size themselves off the same value instead
  // of guessing a matching constant.
  static const double maxBorderDotRadius = BeadedDotBorderPainter.maxDotRadius;

  final Color color;
  final StackPosition position;
  final Widget child;
  final EdgeInsets? padding;
  // Corner radius override. Null uses the shared default.
  final double? cornerRadius;

  const CurvedStackCard({
    super.key,
    required this.color,
    required this.position,
    required this.child,
    this.padding,
    this.cornerRadius,
  });

  @override
  State<CurvedStackCard> createState() => _CurvedStackCardState();
}

class _CurvedStackCardState extends State<CurvedStackCard>
    with SingleTickerProviderStateMixin {
  // Ever-increasing "seconds elapsed" clock (not a bounded 0..1 repeat) so
  // the border dots' wander functions never hit a wrap-around jump — they
  // just drift for as long as the card is on screen. A single controller
  // driving CustomPaint's `repaint` listenable repaints only the border
  // layer each tick, without rebuilding the card's content.
  late final AnimationController _time = AnimationController.unbounded(
    vsync: this,
  )..repeat(min: 0, max: 100000, period: const Duration(seconds: 100000));

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  static const double _defaultCornerRadius = 32;
  // Tight and uniform - just enough clearance to keep content off the
  // border, not the old curve-bulge clearance a wavy outline needed.
  static const EdgeInsets _defaultPadding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 16);

  @override
  Widget build(BuildContext context) {
    final shape = _RoundedRectShape(
      radius: widget.cornerRadius ?? _defaultCornerRadius,
    );

    return CustomPaint(
      foregroundPainter: _StackBorderPainter(
        shape: shape,
        color: widget.color,
        time: _time,
      ),
      child: ClipPath(
        clipper: shape,
        child: Padding(
          padding: widget.padding ?? _defaultPadding,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RoundedRectShape extends CustomClipper<Path> {
  // The corner radius at (or below) _flatAspectRatio - the card's usual,
  // wide-and-short proportions. Held on the class so the aspect-ratio
  // scaling below has a single anchor point to grow from.
  final double radius;

  _RoundedRectShape({required this.radius});

  // Height:width ratio at which the corners sit at exactly `radius` and
  // no more. Below this the card is wide enough that `radius` alone reads
  // fine; above it the card is getting squarer, and a flat `radius` would
  // start to look barely-rounded next to how tall the card's become.
  static const double _flatAspectRatio = 0.5;

  // Once the card is taller than it is square, a full pill/circle stops
  // reading as "rounded" and starts reading as a stadium shape - ease the
  // radius back down toward this fraction of maxRadius rather than staying
  // pinned at a full pill for every taller-than-square card.
  static const double _postSquareFloor = 0.8;

  // >1 gives the falloff a soft start right at aspectRatio 1 (matching the
  // full-pill peak it's easing away from) before it picks up, instead of a
  // hard kink straight from "still growing" to "already easing off".
  static const double _postSquareCurve = 2.0;

  // How many aspect-ratio units past square (1.0) it takes to fully settle
  // at _postSquareFloor - beyond that the radius just holds at the floor.
  static const double _postSquareSpan = 1.0;

  double _effectiveRadius(Size size) {
    if (size.width <= 0) return radius;

    final maxRadius = math.min(size.width, size.height) / 2;

    // iPhone's narrower screen pushes ordinary-height boxes to a much
    // higher height:width ratio than the same box hits on iPad/moto_g, so
    // the ratio-driven growth below rounds them into a full pill and clips
    // into the top/bottom border lines. Skip the growth on iPhone and hold
    // at a flat (still rounded) radius regardless of aspect ratio.
    if (DeviceConfig.isIphone) return math.min(radius, maxRadius);

    final aspectRatio = size.height / size.width;

    if (aspectRatio <= _flatAspectRatio) return math.min(radius, maxRadius);

    // Restored to a plain linear ramp up to a full pill/circle exactly at
    // aspectRatio 1 (a square card) - the approach-and-hit-square feel this
    // originally had.
    if (aspectRatio <= 1.0) {
      final growth = (aspectRatio - _flatAspectRatio) / (1 - _flatAspectRatio);
      return (radius + (maxRadius - radius) * growth).clamp(0.0, maxRadius);
    }

    // Past square, attenuate instead of staying pinned at a full pill for
    // every taller card: ease back down toward _postSquareFloor as the
    // ratio keeps climbing.
    final over = ((aspectRatio - 1.0) / _postSquareSpan).clamp(0.0, 1.0);
    final falloff = math.pow(over, _postSquareCurve).toDouble();
    final fraction = 1.0 - (1.0 - _postSquareFloor) * falloff;

    return maxRadius * fraction;
  }

  Path buildPath(Size size) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(_effectiveRadius(size)),
        ),
      );
  }

  @override
  Path getClip(Size size) => buildPath(size);

  @override
  bool shouldReclip(covariant _RoundedRectShape oldClipper) =>
      oldClipper.radius != radius;
}

// Instead of a solid stroke, the outline is traced by a beaded string of
// small dots (see BeadedDotBorderPainter) — irregular in size, in how far
// they sit off the true outline, and in the spacing between them, each
// slowly wandering — so the border reads as hand-scattered rather than
// drafted, and never sits perfectly still.
class _StackBorderPainter extends BeadedDotBorderPainter {
  final _RoundedRectShape shape;

  _StackBorderPainter({
    required this.shape,
    required super.color,
    required super.time,
  });

  @override
  Path pathForSize(Size size) => shape.buildPath(size);

  @override
  bool shouldRepaint(covariant _StackBorderPainter oldDelegate) =>
      super.shouldRepaint(oldDelegate) ||
      oldDelegate.shape.radius != shape.radius;
}
