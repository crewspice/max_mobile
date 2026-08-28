import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Where a card sits within a vertical stack of related cards (e.g. the
// annual/PM status card, any open issue cards, and the record repair/issue
// entry card together). Position determines how curved each edge is: an
// edge exposed to open space curves hard, while an edge that abuts a
// neighboring card in the stack curves gently instead — never dead flat.
enum StackPosition { only, top, medial, bottom }

class CurvedStackCard extends StatefulWidget {
  // The border layer's largest dot radius — exposed so other widgets that
  // want to echo the card's beaded-circle visual language (e.g. DateLabel's
  // slash-replacement dots) can size themselves off the same value instead
  // of guessing a matching constant.
  static const double maxBorderDotRadius = 3.4;

  final Color color;
  final StackPosition position;
  final Widget child;
  final EdgeInsets? padding;
  // How far the left/right edges pull in at their midpoint. Null uses the
  // shared default (_StackShape's own constant) — set per-card to bring a
  // particular box's sides in further without affecting the others.
  final double? sideInset;
  // How far each corner is cut inward. Null uses the shared default
  // (_StackShape's own constant) — set per-card to round a particular
  // box's corners more without affecting the others.
  final double? cornerInset;

  const CurvedStackCard({
    super.key,
    required this.color,
    required this.position,
    required this.child,
    this.padding,
    this.sideInset,
    this.cornerInset,
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

  bool get _topExposed =>
      widget.position == StackPosition.only ||
      widget.position == StackPosition.top;
  bool get _bottomExposed =>
      widget.position == StackPosition.only ||
      widget.position == StackPosition.bottom;

  // 0..1 curviness per edge. Sides are always curved; top/bottom lean hard
  // into the curve only where that edge actually faces open space — a
  // "boxy" joint edge still stays gently rounded rather than flat.
  double get _topCurviness => _topExposed ? 1.0 : 0.5;
  double get _bottomCurviness => _bottomExposed ? 1.0 : 0.5;
  static const double _sideCurviness = 0.62;

  // Exposed edges bow inward at the corners, which eats into the space a
  // flush-to-the-edge row of content would otherwise use — callers don't
  // need to compensate, the extra inset here pulls that content toward
  // the center for them.
  EdgeInsets get _resolvedPadding =>
      widget.padding ??
      EdgeInsets.fromLTRB(
        30,
        _topExposed ? 36 : 26,
        30,
        _bottomExposed ? 36 : 26,
      );

  @override
  Widget build(BuildContext context) {
    final shape = _StackShape(
      topCurviness: _topCurviness,
      bottomCurviness: _bottomCurviness,
      sideCurviness: _sideCurviness,
      sideInset: widget.sideInset,
      cornerInset: widget.cornerInset,
    );

    return FractionallySizedBox(
      widthFactor: 0.75,
      child: CustomPaint(
        foregroundPainter: _StackBorderPainter(
          shape: shape,
          color: widget.color,
          time: _time,
        ),
        child: ClipPath(
          clipper: shape,
          child: Padding(
            padding: _resolvedPadding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// A single continuously-curved outline with no actual corners anywhere: a
// closed spline through 8 anchor points (the 4 box corners, pulled inward
// by how curved the two edges meeting there are, plus the 4 edge
// midpoints, always flush with the box). Each anchor's tangent direction
// is averaged from its neighbors on both sides (Catmull-Rom style), so
// consecutive segments always meet smoothly instead of kinking — but
// unlike plain Catmull-Rom, each segment's handle length is scaled off
// its own chord, not a shared vector. Cards here are wide and short, so a
// shared handle length would size the short side segments off the long
// top/bottom ones and pinch them inward; scaling per-segment keeps every
// edge's bulge proportional to that edge alone.
// A lone card (full curviness on every edge) reads as a wide ellipse.
class _StackShape extends CustomClipper<Path> {
  final double topCurviness;
  final double bottomCurviness;
  final double sideCurviness;
  final double? sideInset;
  final double? cornerInset;

  _StackShape({
    required this.topCurviness,
    required this.bottomCurviness,
    required this.sideCurviness,
    this.sideInset,
    this.cornerInset,
  });

  // Overridable per-card via CurvedStackCard.cornerInset.
  static const double _defaultMaxCornerInset = 42;
  // Fraction of a segment's own chord length used as its handle length.
  static const double _handleFactor = 0.4;
  // How far the left/right edges themselves pull in at their midpoint —
  // independent of the corner insets above, so the top/bottom curves and
  // the cornering keep their shape while the sides alone gain a waist.
  // Overridable per-card via CurvedStackCard.sideInset.
  static const double _defaultSideInset = 16;

  Path buildPath(Size size) {
    final maxAllowedInset = math.min(size.width, size.height) * 0.48;
    final maxCornerInset = cornerInset ?? _defaultMaxCornerInset;

    double insetFor(double a, double b) =>
        math.min((a + b) / 2 * maxCornerInset, maxAllowedInset);

    final topInset = insetFor(topCurviness, sideCurviness);
    final bottomInset = insetFor(bottomCurviness, sideCurviness);
    final sideInset =
        math.min(this.sideInset ?? _defaultSideInset, maxAllowedInset * 0.5);

    final w = size.width;
    final h = size.height;

    final points = <Offset>[
      Offset(w / 2, 0), // top mid
      Offset(w - topInset, topInset), // top right corner
      Offset(w - sideInset, h / 2), // right mid
      Offset(w - bottomInset, h - bottomInset), // bottom right corner
      Offset(w / 2, h), // bottom mid
      Offset(bottomInset, h - bottomInset), // bottom left corner
      Offset(sideInset, h / 2), // left mid
      Offset(topInset, topInset), // top left corner
    ];

    final n = points.length;
    Offset at(int i) => points[(i % n + n) % n];

    Offset tangentAt(int i) {
      final d = at(i + 1) - at(i - 1);
      final len = d.distance;
      return len == 0 ? Offset.zero : d / len;
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (var i = 0; i < n; i++) {
      final p1 = at(i);
      final p2 = at(i + 1);
      final handleLength = (p2 - p1).distance * _handleFactor;

      final c1 = p1 + tangentAt(i) * handleLength;
      final c2 = p2 - tangentAt(i + 1) * handleLength;

      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    path.close();
    return path;
  }

  @override
  Path getClip(Size size) => buildPath(size);

  @override
  bool shouldReclip(covariant _StackShape oldClipper) =>
      oldClipper.topCurviness != topCurviness ||
      oldClipper.bottomCurviness != bottomCurviness ||
      oldClipper.sideCurviness != sideCurviness ||
      oldClipper.sideInset != sideInset ||
      oldClipper.cornerInset != cornerInset;
}

// A tiny sum-of-two-sines "wander" generator: bounded (never drifts away
// for good, unlike a true random walk) but with mismatched per-instance
// frequency and phase so many of these running side by side never look
// synchronized or obviously looping.
class _Wander {
  final double freq1;
  final double phase1;
  final double freq2;
  final double phase2;

  _Wander(math.Random random, {required double minPeriodSeconds}) :
        freq1 = (2 * math.pi) /
            (minPeriodSeconds + random.nextDouble() * minPeriodSeconds),
        phase1 = random.nextDouble() * 2 * math.pi,
        freq2 = (2 * math.pi) /
            (minPeriodSeconds * 1.7 +
                random.nextDouble() * minPeriodSeconds * 1.7),
        phase2 = random.nextDouble() * 2 * math.pi;

  double at(double time) =>
      0.65 * math.sin(time * freq1 + phase1) +
      0.35 * math.sin(time * freq2 + phase2);
}

// Instead of a solid stroke, the outline is traced by a beaded string of
// small dots radially shaded from the card's background at their center out
// to the element color at their rim — irregular in size, in how far they
// sit off the true outline, and in the spacing between them — so the border
// reads as hand-scattered rather than drafted. Each dot also slowly,
// smoothly wanders — drifting along the outline, off it, and in its own
// size — so the border never sits perfectly still. ~80 dots for a typical
// card; scales with the outline's actual perimeter for very different sizes.
class _StackBorderPainter extends CustomPainter {
  final _StackShape shape;
  final Color color;
  final Animation<double> time;

  _StackBorderPainter({
    required this.shape,
    required this.color,
    required this.time,
  }) : super(repaint: time);

  static const double _targetDotSpacing = 13;
  static const double _minRadius = 1.6;
  static const double _maxRadius = CurvedStackCard.maxBorderDotRadius;
  static const double _maxDeviation = 3.2;
  static const double _spacingJitter = 0.7;

  // A second, denser layer of small filled dots in the card's own fill
  // color — half the first layer's radius range — scattered along the same
  // outline so it reads as flecks peeking out from behind the gradient
  // dots rather than a second distinct border.
  static const double _minFillRadius = 0.0;
  static const double _maxFillRadius = _maxRadius * 0.5;

  // Scales the wander clock fed into _Wander.at() — bumping this speeds up
  // every dot's drift uniformly without touching each _Wander's own
  // frequency/phase draws.
  static const double _wanderSpeedFactor = 1.4;

  Tangent? _tangentAtDistance(List<PathMetric> metrics, double distance) {
    var remaining = distance;
    for (final metric in metrics) {
      if (remaining <= metric.length) {
        return metric.getTangentForOffset(remaining);
      }
      remaining -= metric.length;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = shape.buildPath(size).computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    if (totalLength <= 0) return;

    final t = time.value * _wanderSpeedFactor;

    _paintDotLayer(
      canvas: canvas,
      metrics: metrics,
      totalLength: totalLength,
      t: t,
      seed: 11,
      minRadius: _minRadius,
      maxRadius: _maxRadius,
      // Radial fill instead of a flat stroke: each dot reads as a little
      // bead lit from its own center, fading from the card's background
      // color out to the element color at its rim.
      paintFor: (center, radius) => Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [AppColors.mainBackground, color],
        ).createShader(
          Rect.fromCircle(center: center, radius: math.max(radius, 0.01)),
        ),
    );

    _paintDotLayer(
      canvas: canvas,
      metrics: metrics,
      totalLength: totalLength,
      t: t,
      seed: 29,
      minRadius: _minFillRadius,
      maxRadius: _maxFillRadius,
      // Center-out radial fade to white, reaching full white by the
      // halfway point and staying white the rest of the way to the rim.
      paintFor: (center, radius) => Paint()
        ..style = PaintingStyle.fill
        ..shader = const RadialGradient(
          colors: [AppColors.main, Colors.white],
          stops: [0.0, 0.5],
        ).createShader(
          Rect.fromCircle(center: center, radius: math.max(radius, 0.01)),
        ),
    );
  }

  // Fixed seed: each dot's own base position and its wander functions'
  // frequency/phase are stable draws every frame, rather than re-scattering
  // the whole border every tick — only `t` (real elapsed time) moves, so
  // each dot travels its own smooth, slow path. A distinct seed per layer
  // keeps the two sets of dots from tracing identical paths.
  void _paintDotLayer({
    required Canvas canvas,
    required List<PathMetric> metrics,
    required double totalLength,
    required double t,
    required int seed,
    required double minRadius,
    required double maxRadius,
    required Paint Function(Offset center, double radius) paintFor,
  }) {
    final dotCount =
        (totalLength / _targetDotSpacing).round().clamp(24, 160);
    final spacing = totalLength / dotCount;
    final random = math.Random(seed);

    var traveled = 0.0;
    for (var i = 0; i < dotCount; i++) {
      final baseJitter = (random.nextDouble() - 0.5) * spacing * _spacingJitter;
      final baseDeviation = (random.nextDouble() - 0.5) * 2 * _maxDeviation;
      final baseRadius =
          minRadius + random.nextDouble() * (maxRadius - minRadius);

      final circWander = _Wander(random, minPeriodSeconds: 24);
      final devWander = _Wander(random, minPeriodSeconds: 18);
      final radWander = _Wander(random, minPeriodSeconds: 15);

      final circOffset = circWander.at(t) * spacing * 0.5;
      final devOffset = devWander.at(t) * _maxDeviation * 0.9;
      final radOffset = radWander.at(t) * (maxRadius - minRadius) * 0.5;

      final jitteredDistance = (traveled + baseJitter + circOffset)
          .clamp(0.0, totalLength - 0.001);

      final tangent = _tangentAtDistance(metrics, jitteredDistance);
      if (tangent != null) {
        final dir = tangent.vector;
        final dirLen = dir.distance;
        final unit = dirLen == 0 ? const Offset(1, 0) : dir / dirLen;
        final normal = Offset(-unit.dy, unit.dx);

        final deviation = baseDeviation + devOffset;
        final radius = (baseRadius + radOffset).clamp(0.0, double.infinity);
        final center = tangent.position + normal * deviation;

        canvas.drawCircle(center, radius, paintFor(center, radius));
      }

      traveled += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _StackBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.shape.topCurviness != shape.topCurviness ||
      oldDelegate.shape.bottomCurviness != shape.bottomCurviness ||
      oldDelegate.shape.sideCurviness != shape.sideCurviness ||
      oldDelegate.shape.sideInset != shape.sideInset ||
      oldDelegate.shape.cornerInset != shape.cornerInset ||
      oldDelegate.time != time;
}
