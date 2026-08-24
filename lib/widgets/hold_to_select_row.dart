import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Press-and-hold-to-confirm wrapper for a list row, in the same spirit as
/// HoldToConfirmButton elsewhere in the app: hold for [holdDuration] to fill
/// a progress overlay across the row and fire [onConfirmed] (e.g. selecting
/// or checking off whatever the row represents), release early to cancel.
///
/// Shared by the yard list sheet and the inventory check screen so the hold
/// animation isn't duplicated.
class HoldToSelectRow extends StatefulWidget {
  final Widget child;
  final VoidCallback onConfirmed;
  final Duration holdDuration;

  const HoldToSelectRow({
    super.key,
    required this.child,
    required this.onConfirmed,
    this.holdDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<HoldToSelectRow> createState() => _HoldToSelectRowState();
}

class _HoldToSelectRowState extends State<HoldToSelectRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onConfirmed();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final progress = _controller.value;
                  if (progress == 0) return const SizedBox.shrink();
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      color: AppColors.green.withOpacity(0.18 + progress * 0.3),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
