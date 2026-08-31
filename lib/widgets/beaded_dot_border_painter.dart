import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Shared dot-scatter/wander machinery behind the "beaded animated circle"
// border look: a string of small dots traced along a path, irregular in
// size, spacing, and offset from the true outline, each slowly wandering
// so the border never sits perfectly still. Used by CurvedStackCard's
// curved content boxes and by anything else on a page that wants to echo
// that same visual language (e.g. the maintenance page's selected mode
// buttons) — subclasses only need to supply the path to trace.
class Wander {
  final double freq1;
  final double phase1;
  final double freq2;
  final double phase2;

  Wander(math.Random random, {required double minPeriodSeconds})
      : freq1 = (2 * math.pi) /
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

abstract class BeadedDotBorderPainter extends CustomPainter {
  final Color color;
  final Animation<double> time;

  BeadedDotBorderPainter({required this.color, required this.time})
      : super(repaint: time);

  static const double targetDotSpacing = 13;
  static const double minRadius = 1.6;
  static const double maxDotRadius = 2.72;
  static const double maxDeviation = 3.2;
  static const double spacingJitter = 0.7;

  // A second, denser layer of small filled dots in the card's own fill
  // color — half the first layer's radius range — scattered along the same
  // outline so it reads as flecks peeking out from behind the gradient
  // dots rather than a second distinct border.
  static const double minFillRadius = 0.0;
  static const double maxFillRadius = maxDotRadius * 0.5;

  // Scales the wander clock fed into Wander.at() — bumping this speeds up
  // every dot's drift uniformly without touching each Wander's own
  // frequency/phase draws.
  static const double wanderSpeedFactor = 1.4;

  // The path to trace with beaded dots, sized to the painter's canvas.
  Path pathForSize(Size size);

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
    final metrics = pathForSize(size).computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    if (totalLength <= 0) return;

    final t = time.value * wanderSpeedFactor;

    _paintDotLayer(
      canvas: canvas,
      metrics: metrics,
      totalLength: totalLength,
      t: t,
      seed: 11,
      minRadius: minRadius,
      maxRadius: maxDotRadius,
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
      minRadius: minFillRadius,
      maxRadius: maxFillRadius,
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
        (totalLength / targetDotSpacing).round().clamp(24, 160);
    final spacing = totalLength / dotCount;
    final random = math.Random(seed);

    var traveled = 0.0;
    for (var i = 0; i < dotCount; i++) {
      final baseJitter = (random.nextDouble() - 0.5) * spacing * spacingJitter;
      final baseDeviation = (random.nextDouble() - 0.5) * 2 * maxDeviation;
      final baseRadius =
          minRadius + random.nextDouble() * (maxRadius - minRadius);

      final circWander = Wander(random, minPeriodSeconds: 24);
      final devWander = Wander(random, minPeriodSeconds: 18);
      final radWander = Wander(random, minPeriodSeconds: 15);

      final circOffset = circWander.at(t) * spacing * 0.5;
      final devOffset = devWander.at(t) * maxDeviation * 0.9;
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
  bool shouldRepaint(covariant BeadedDotBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.time != time;
}
