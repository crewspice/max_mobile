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

  final void Function(String userId) onAssignmentTap;

  const DriverOrbitSelector({
    super.key,
    required this.users,
    required this.onUserTap,
    required this.onAssignmentTap,
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
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  @override
  void dispose() {
    orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbit,
      builder: (_, __) {
        final screen = MediaQuery.of(context).size;

        final shortestSide =
            min(screen.width, screen.height);

        final double uiScale =
            (shortestSide / 420).clamp(0.85, 1.75);

        /// ✅ TRUE CENTER (fixes all drift)
        final centerX = screen.width * 0.5;
        final centerY = screen.height * 0.5;

        /// 🔥 TALL VERTICAL OVAL
        final double radiusX =
            (screen.width * 0.34) * uiScale;

        final double radiusY =
            (screen.height * 0.26) * uiScale;

        final nodes = <Widget>[];

        for (int i = 0;
            i < widget.users.length;
            i++) {
          final user = widget.users[i];

          final angle =
              (2 * pi * i / widget.users.length) +
                  orbit.value * 2 * pi;

          final x = centerX + cos(angle) * radiusX;
          final y = centerY + sin(angle) * radiusY;

          final depth = (sin(angle) + 1) / 2;
          final scale = 0.78 + depth * 0.32;

          nodes.add(
            Positioned.fill(
              child: Align(
                alignment: Alignment(
                  (x - centerX) / centerX,
                  (y - centerY) / centerY,
                ),

                child: Transform.scale(
                  scale: scale,
                  child: _DriverNode(
                    user: user,
                    uiScale: uiScale,
                    onTap: () {
                      widget.onUserTap(
                        user['initial'],
                        user['nickname'],
                        user['truckId'].toString(),
                      );
                    },
                    onAssignmentTap: () {
                      widget.onAssignmentTap(
                        user['initial'],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: nodes);
      },
    );
  }
}

class _DriverNode extends StatelessWidget {
  final Map<String, dynamic> user;
  final double uiScale;

  final VoidCallback onTap;
  final VoidCallback onAssignmentTap;

  const _DriverNode({
    required this.user,
    required this.uiScale,
    required this.onTap,
    required this.onAssignmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRoute =
        user['hasRoute'].toString() == 'true';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: (102 * uiScale).toDouble(),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.main.withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasRoute
                  ? AppColors.green
                  : AppColors.yellow,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: hasRoute
                    ? AppColors.green.withOpacity(0.15)
                    : AppColors.yellow.withOpacity(0.08),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: (18 * uiScale).toDouble(),
                    backgroundColor: hasRoute
                        ? AppColors.green
                        : AppColors.mainBackground,
                    child: Text(
                      user['initial'],
                      style: TextStyle(
                        fontSize: 18 * uiScale,
                        fontWeight: FontWeight.bold,
                        color: hasRoute
                            ? AppColors.main
                            : AppColors.yellow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: hasRoute
                        ? onAssignmentTap
                        : null,
                    child: Opacity(
                      opacity:
                          hasRoute ? 1 : 0.25,
                      child: Image.asset(
                        'assets/assignment.png',
                        width:
                            (36 * uiScale).toDouble(),
                        height:
                            (36 * uiScale).toDouble(),
                        color: hasRoute
                            ? AppColors.green
                            : AppColors.yellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                user['nickname'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19 * uiScale,
                  fontWeight: FontWeight.w600,
                  color: hasRoute
                      ? AppColors.green
                      : AppColors.yellow,
                ),
              ),
              const SizedBox(height: 2),
              if (user['truckId'] != null && user['truckId'].toString().isNotEmpty)
                Text(
                    "Truck ${user['truckId']}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                    fontSize: 14 * uiScale,
                    color: hasRoute
                        ? AppColors.green
                        : AppColors.yellow,
                    letterSpacing: 0.2,
                    ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}