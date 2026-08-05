import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeSelectorRow<T> extends StatefulWidget {
  final String? label;
  final Set<T> selected;
  final ValueChanged<T> onToggle;
  final List<ModeButton<T>> buttons;

  const ModeSelectorRow({
    super.key,
    this.label,
    required this.selected,
    required this.onToggle,
    required this.buttons,
  });

  @override
  State<ModeSelectorRow<T>> createState() => _ModeSelectorRowState<T>();
}

class _ModeSelectorRowState<T> extends State<ModeSelectorRow<T>> {
  int offset = 0;

  Color _spectrumColor(double x) {
    x = x.clamp(0, 1);

    if (x <= .5) {
      return Color.lerp(
        AppColors.yellow,
        AppColors.green,
        x * 2,
      )!;
    }

    return Color.lerp(
      AppColors.green,
      AppColors.red,
      (x - .5) * 2,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            '${widget.label}:',
            style: GoogleFonts.permanentMarker(
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 6),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const arrowWidth = 42.0;
            const gap = 8.0;
            const buttonMinWidth = 95.0;

            final needsArrow =
                widget.buttons.length * buttonMinWidth >
                    constraints.maxWidth;

            final availableWidth = constraints.maxWidth -
                (needsArrow ? arrowWidth + gap : 0);

            final count = needsArrow
                ? (availableWidth / (buttonMinWidth + gap))
                    .floor()
                    .clamp(1, widget.buttons.length)
                : widget.buttons.length;

            final visible = widget.buttons
                .skip(offset)
                .take(count)
                .toList();

            final buttonWidth =
                (availableWidth - gap * (visible.length - 1)) /
                    visible.length;

            return Row(
              children: [
                SizedBox(
                  width: availableWidth,
                  height: 50,
                  child: Stack(
                    children: [
                      for (int i = 0; i < visible.length; i++)
                        Positioned(
                          left: i * (buttonWidth + gap),
                          width: buttonWidth,
                          height: 50,
                          child: _button(
                            visible[i],
                            (i * (buttonWidth + gap)) +
                                (buttonWidth / 2),
                            availableWidth,
                          ),
                        ),
                    ],
                  ),
                ),
                if (needsArrow) ...[
                  const SizedBox(width: gap),
                  SizedBox(
                    width: arrowWidth,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          offset += count;

                          if (offset >= widget.buttons.length) {
                            offset = 0;
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(
                          color: AppColors.yellow,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppColors.yellow,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _button(
    ModeButton<T> button,
    double centerX,
    double rowWidth,
  ) {
    final active = widget.selected.contains(button.value);
    final glowColor = _spectrumColor(centerX / rowWidth);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: active
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(.55),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: () => widget.onToggle(button.value),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.main,
          foregroundColor: AppColors.yellow,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          side: BorderSide(
            color: active
                ? AppColors.yellow
                : AppColors.yellow.withOpacity(.35),
            width: active ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          button.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class ModeButton<T> {
  final String label;
  final T value;

  const ModeButton(
    this.label,
    this.value,
  );
}