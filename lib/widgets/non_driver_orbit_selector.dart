import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/color_field.dart';
import 'user_avatar.dart';

class NonDriverOrbitSelector extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  final Future<void> Function(
    String userId,
    String userName,
    String truckId,
  ) onUserTap;

  const NonDriverOrbitSelector({
    super.key,
    required this.users,
    required this.onUserTap,
  });

  @override
  State<NonDriverOrbitSelector> createState() =>
      _NonDriverOrbitSelectorState();
}

class _NonDriverOrbitSelectorState
    extends State<NonDriverOrbitSelector>
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

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: orbit,
          builder: (_, __) {
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;

            final shortestSide =
                MediaQuery.of(context).size.shortestSide;

            final uiScale =
                (shortestSide / 420).clamp(0.85, 1.6);

            final radiusX = constraints.maxWidth * 0.08;
            final radiusY = constraints.maxHeight * 0.10;

            final count = widget.users.length;

            final nodes = <Widget>[];

            for (int i = 0; i < count; i++) {
              final user = widget.users[i];

              final angle =
                  (i * (2 * pi / count)) +
                  (orbit.value * 2 * pi);

              final x =
                  centerX + cos(angle) * radiusX;

              final y =
                  centerY + sin(angle) * radiusY;

              final color = ColorField.fromX(
                x,
                centerX,
                constraints.maxWidth,
              );

              nodes.add(
                Positioned(
                  left: x - 22,
                  top: y - 22,
                  child: GestureDetector(
                    onTap: () {
                      widget.onUserTap(
                        user['initial'],
                        user['nickname'],
                        user['truckId'].toString(),
                      );
                    },
                    child: UserAvatar(
                      initials: user['initial'],
                      radius: 22 * uiScale,
                      color: color,
                    ),
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