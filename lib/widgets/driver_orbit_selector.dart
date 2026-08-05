import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DriverOrbitSelector extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  final Future<void> Function(
    String userId,
    String userName,
    String truckId,
  ) onUserTap;

  const DriverOrbitSelector({
    super.key,
    required this.users,
    required this.onUserTap,
  });

  @override
  State<DriverOrbitSelector> createState() =>
      _DriverOrbitSelectorState();
}

class _DriverOrbitSelectorState
    extends State<DriverOrbitSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController orbit;

  @override
  void initState() {
    super.initState();

    orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 65),
    )..repeat();
  }

  @override
  void dispose() {
    orbit.dispose();
    super.dispose();
  }

  Color _colorFromNormalized(double t) {
    final clamped = t.clamp(-1.0, 1.0);

    if (clamped < 0) {
      return Color.lerp(
        AppColors.yellow,
        AppColors.green,
        clamped + 1,
      )!;
    }

    return Color.lerp(
      AppColors.green,
      AppColors.red,
      clamped,
    )!;
  }

  double _compressSpectrum(
    double x,
    double centerX,
    double width,
    double compression, // 0.0–1.0
  ) {
    final raw = ((x - centerX) / (width / 2)).clamp(-1.0, 1.0);

    // compression < 1 shrinks range toward center
    return raw * compression;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: orbit,
          builder: (_, __) {
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;

            final xNudge = -constraints.maxWidth * 0.04;

            final shortestSide =
                MediaQuery.of(context).size.shortestSide;

            final uiScale =
                (shortestSide / 420).clamp(0.85, 1.6);

            final radiusX = constraints.maxWidth * 0.31;
            final radiusY = constraints.maxHeight * 0.28;

            final nodeSizeBase = 110 * uiScale;

            final drivers =
                widget.users.where((u) => u['driver'] == 1).toList();

            final nonDrivers =
                widget.users.where((u) => u['driver'] != 1).toList();

            final nodes = <Widget>[];

            // =========================
            // DRIVERS (outer orbit)
            // =========================
            for (int i = 0; i < drivers.length; i++) {
              final user = drivers[i];

              final angle =
                  (i * (2 * pi / drivers.length)) +
                  orbit.value * 2 * pi +
                  pi / 2;

              final x = centerX + cos(angle) * radiusX + xNudge;
              final y = centerY + sin(angle) * radiusY;

              final scale = 0.9;

              final t = _compressSpectrum(
                x,
                centerX,
                radiusX,
                0.54, // 👈 drivers only use ~2/3 spectrum
              );

              final color = _colorFromNormalized(t);

              nodes.add(
                Positioned(
                  left: x - 30,
                  top: y - 30,
                  child: Transform.scale(
                    scale: scale,
                    child: _DriverNode(
                      user: user,
                      uiScale: uiScale,
                      accentColor: color,
                      onTap: () {
                        widget.onUserTap(
                          user['initial'],
                          user['nickname'],
                          user['truckId'].toString(),
                        );
                      },
                    ),
                  ),
                ),
              );
            }

            // =========================
            // NON-DRIVERS (inner tight orbit)
            // =========================
            for (int i = 0; i < nonDrivers.length; i++) {
              final user = nonDrivers[i];

              final angle =
                  (i * (2 * pi / nonDrivers.length)) +
                  orbit.value * 2 * pi +
                  pi / 2;

              final x =
                  centerX + cos(angle) * radiusX * 0.45;

              final y =
                  centerY + sin(angle) * radiusY * 0.45;

              final t = _compressSpectrum(
                x,
                centerX,
                radiusX,
                0.5, // 👈 drivers only use ~2/3 spectrum
              );

              final color = _colorFromNormalized(t);

              nodes.add(
                Positioned(
                  left: x - 22,
                  top: y - 22,
                  child: _DriverNode(
                    user: user,
                    uiScale: uiScale,
                    accentColor: color,
                    onTap: () {
                      widget.onUserTap(
                        user['initial'],
                        user['nickname'],
                        user['truckId'].toString(),
                      );
                    },
                  ),
                ),
              );
            }

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(children: nodes),
            );
          },
        );
      },
    );
  }
}

class _DriverNode extends StatelessWidget {
  final Map<String, dynamic> user;
  final double uiScale;

  final Color accentColor;

  final VoidCallback onTap;

  const _DriverNode({
    required this.user,
    required this.uiScale,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDriver = user['driver'] == 1;
    final hasRoute = user['hasRoute'].toString() == 'true';

    if (!isDriver) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: CircleAvatar(
            radius: 22 * uiScale,
            backgroundColor: accentColor,
            child: Text(
              user['initial'],
              style: TextStyle(
                fontSize: 18 * uiScale,
                fontWeight: FontWeight.bold,
                color: AppColors.main,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 90 * uiScale,
            maxWidth: 180 * uiScale,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.main.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: accentColor.withOpacity(0.12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18 * uiScale,
                      backgroundColor: accentColor,
                      child: Text(
                        user['initial'],
                        style: TextStyle(
                          fontSize: 18 * uiScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.main,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Opacity(
                      opacity: hasRoute ? 1 : 0.25,
                      child: Image.asset(
                        'assets/assignment.png',
                        width: 34 * uiScale,
                        height: 34 * uiScale,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  user['nickname'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18 * uiScale,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                if (user['truckId'] != null &&
                    user['truckId'].toString().isNotEmpty)
                  Text(
                    "Truck ${user['truckId']}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13 * uiScale,
                      color: accentColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}