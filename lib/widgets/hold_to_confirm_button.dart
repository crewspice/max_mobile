import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;
  final Icon? icon;
  final Duration holdDuration;
  final Color baseColor;
  final Color progressColor;
  final Color textColor;
  final bool outlined;
  final double textSize;
  final bool enabled;
  final bool circular;
  final double diameter;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.label,
    this.icon,
    required this.baseColor,
    required this.progressColor,
    required this.textColor,
    this.holdDuration = const Duration(seconds: 2),
    this.outlined = false,
    this.textSize = 14,
    this.enabled = true,
    this.circular = false,
    this.diameter = 76,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onConfirmed();
        _controller.reset();
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.circular
        ? BorderRadius.circular(widget.diameter / 2)
        : BorderRadius.circular(widget.outlined ? 12 : 28);

    Widget button;

    if (widget.circular) {
      button = SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.baseColor,
            foregroundColor: widget.textColor,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          onPressed: () {},
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: widget.textColor),
                    child: widget.icon!,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  widget.label,
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: widget.textSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      button = SizedBox(
        width: double.infinity,
        child: widget.outlined
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.mainBackground,
                  foregroundColor: widget.textColor,
                  side: BorderSide(
                    color: widget.baseColor,
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
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      IconTheme(
                        data: IconThemeData(color: widget.textColor),
                        child: widget.icon!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade, // or ellipsis
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.textSize,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.baseColor,
                ),
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      IconTheme(
                        data: IconThemeData(color: widget.textColor),
                        child: widget.icon!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.textSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    }

    final progressOverlay = Positioned.fill(
      child: Center(
        child: FractionallySizedBox(
          heightFactor: widget.circular ? 1.0 : (widget.outlined ? 1.0 : 0.83),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;

              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.outlined
                        ? widget.baseColor.withOpacity(
                            0.18 + progress * 0.22,
                          )
                        : widget.progressColor.withOpacity(
                            0.3 + progress * 0.4,
                          ),
                    borderRadius: radius,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Widget content = ClipRRect(
      borderRadius: radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          button,
          progressOverlay,
        ],
      ),
    );

    if (widget.circular) {
      content = SizedBox(
        width: widget.diameter,
        height: widget.diameter,
        child: content,
      );
    }

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: content,
      ),
    );
  }
}
