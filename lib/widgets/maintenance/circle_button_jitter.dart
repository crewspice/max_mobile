import 'dart:math' as math;

// A little hand-placed irregularity for the record/history circle button
// rows: each button gets its own small, fixed (not re-randomized every
// rebuild) offset in size, vertical position, and horizontal position, so
// the row doesn't look machine-ruled. Keyed off the button's own label so
// the same button always lands on the same jitter.
({double diameter, double dx, double dy}) circleButtonJitter(
  String seedKey,
  double baseDiameter,
) {
  final random = math.Random(seedKey.hashCode);

  double jitter(double fraction) =>
      (random.nextDouble() - 0.5) * 2 * baseDiameter * fraction;

  return (
    diameter: baseDiameter + jitter(0.06),
    dx: jitter(0.045),
    dy: jitter(0.045),
  );
}
