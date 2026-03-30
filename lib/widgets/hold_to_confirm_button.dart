import 'package:flutter/material.dart';

class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;
  final Icon icon;
  final Duration holdDuration;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.label,
    required this.icon,
    this.holdDuration = const Duration(seconds: 2), // hardcode?
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

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: widget.icon,
                label: Text(widget.label),
                onPressed: () {},
              ),
            ),
            Positioned.fill(
              child: Center(
                child: FractionallySizedBox(
                  heightFactor: 0.83, // 👈 THIS controls height (80%)
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final progress = _controller.value;

                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3 + progress * 0.4),
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
    );
  }
}