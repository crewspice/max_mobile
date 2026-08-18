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
    final radius = BorderRadius.circular(widget.outlined ? 12 : 28);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
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
              ),
              Positioned.fill(
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: widget.outlined ? 1.0 : 0.83,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
