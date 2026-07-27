import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ActionItem {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final Widget? customChild;

  const ActionItem({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
    this.customChild,
  });
}

class ActionRibbon extends StatefulWidget {
  final List<ActionItem> actions;
  final double buttonWidth;
  final Color color;

  const ActionRibbon({
    super.key,
    required this.actions,
    this.buttonWidth = 125,
    required this.color,
  });

  @override
  State<ActionRibbon> createState() => _ActionRibbonState();
}

class _ActionRibbonState extends State<ActionRibbon> {
  int _offset = 0;
  bool _movingRight = true;

  static const double gap = 8;
  static const double arrowWidth = 42;
  static const int visibleButtons = 2;

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return const SizedBox.shrink();

    final visible = widget.actions.skip(_offset).take(visibleButtons).toList();
    final hasLeft = _offset > 0;
    final hasRight = _offset + visibleButtons < widget.actions.length;

    return Row(
      children: [
        hasLeft
            ? _arrow(Icons.chevron_left, () {
                setState(() {
                  _movingRight = false;
                  _offset = (_offset - visibleButtons).clamp(0, widget.actions.length);
                });
              })
            : const SizedBox(width: arrowWidth),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth =
                      (constraints.maxWidth - gap * (visibleButtons - 1)) / visibleButtons;

                  return ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final isOld = child.key != ValueKey(_offset);

                        final beginOffset = isOld
                            ? (_movingRight ? -1.0 : 1.0)
                            : (_movingRight ? 1.0 : -1.0);

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(beginOffset, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                      child: Row(
                        key: ValueKey(_offset),
                        mainAxisAlignment: visible.length == 1
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          for (int i = 0; i < visible.length; i++) ...[
                            SizedBox(
                              width: buttonWidth,
                              child: _button(visible[i]),
                            ),
                            if (i < visible.length - 1)
                              const SizedBox(width: gap),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        hasRight
            ? _arrow(Icons.chevron_right, () {
                setState(() {
                  _movingRight = true;
                  _offset = (_offset + visibleButtons)
                      .clamp(0, widget.actions.length - 1);
                });
              })
            : const SizedBox(width: arrowWidth),
      ],
    );
  }

  Widget _button(ActionItem action) {
    if (action.customChild != null) return action.customChild!;

    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.mainBackground,
        side: BorderSide(
          color: action.color,
          width: 1.3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (action.icon != null) ...[
            Icon(
              action.icon,
              size: 18,
              color: action.color,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              action.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: action.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: arrowWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mainBackground,
              border: Border.all(
                color: widget.color,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: widget.color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}