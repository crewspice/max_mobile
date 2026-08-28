import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/device_config.dart';
import 'circle_button_jitter.dart';

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
  int _offset = 0;
  bool _movingRight = true;

  double get _scale => DeviceConfig.circleScale();
  double get arrowWidth => 42 * _scale;
  double get diameter => 76 * _scale;
  double get gap => 24 * _scale;
  double get rowHeight => 84 * _scale;
  double get fontSize =>
      13 * _scale * DeviceConfig.circleTextScale();

  // "Rentals" is one of the longer labels and only just fits at the
  // regular size on the devices whose circles/text run bigger — shrink it
  // there specifically rather than shrinking every label.
  double _fontSizeFor(String label) {
    final needsShrink =
        label == 'Rentals' && (DeviceConfig.isIpad || DeviceConfig.device == 'moto_g');
    return needsShrink ? fontSize * 0.8 : fontSize;
  }

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
    if (widget.buttons.isEmpty) return const SizedBox.shrink();

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
            const maxVisible = 3;

            final fitsAll = widget.buttons.length <= maxVisible &&
                widget.buttons.length * (diameter + gap) - gap <=
                    constraints.maxWidth;

            final buttonsAreaWidth =
                constraints.maxWidth - (fitsAll ? 0 : arrowWidth * 2);

            final pageTarget =
                widget.buttons.length <= maxVisible ? widget.buttons.length : maxVisible;

            final visibleCount = fitsAll
                ? widget.buttons.length
                : ((buttonsAreaWidth + gap) / (diameter + gap))
                    .floor()
                    .clamp(1, pageTarget);

            final maxOffset =
                (widget.buttons.length - 1).clamp(0, widget.buttons.length);

            final offset = _offset.clamp(0, maxOffset);

            final hasLeft = !fitsAll && offset > 0;
            final hasRight = !fitsAll && offset + visibleCount < widget.buttons.length;

            final visible =
                widget.buttons.skip(offset).take(visibleCount).toList();

            return Row(
              children: [
                if (!fitsAll)
                  hasLeft
                      ? _arrow(Icons.chevron_left, () {
                          setState(() {
                            _movingRight = false;
                            _offset =
                                (offset - visibleCount).clamp(0, maxOffset);
                          });
                        })
                      : SizedBox(width: arrowWidth),

                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final isOld = child.key != ValueKey(offset);

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
                      child: SizedBox(
                        key: ValueKey(offset),
                        width: double.infinity,
                        height: rowHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < visible.length; i++) ...[
                              _button(visible[i]),
                              if (i < visible.length - 1)
                                SizedBox(width: gap),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (!fitsAll)
                  hasRight
                      ? _arrow(Icons.chevron_right, () {
                          setState(() {
                            _movingRight = true;
                            _offset =
                                (offset + visibleCount).clamp(0, maxOffset);
                          });
                        })
                      : SizedBox(width: arrowWidth),
              ],
            );
          },
        ),
      ],
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
                color: AppColors.yellow,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.yellow,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(ModeButton<T> button) {
    final active = widget.selected.contains(button.value);

    final index = widget.buttons.indexOf(button);
    final t = widget.buttons.length <= 1
        ? 0.0
        : index / (widget.buttons.length - 1);
    final glowColor = _spectrumColor(t);
    final jitter = circleButtonJitter(button.label, diameter);

    return Transform.translate(
      offset: Offset(jitter.dx, jitter.dy),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: jitter.diameter,
      height: jitter.diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.main,
        border: Border.all(
          color: active
              ? AppColors.yellow
              : AppColors.yellow.withOpacity(.35),
          width: active ? 2 : 1,
        ),
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
      child: Material(
        shape: const CircleBorder(),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onToggle(button.value),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Center(
              child: Text(
                button.label,
                maxLines: 2,
                softWrap: true,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: _fontSizeFor(button.label),
                ),
              ),
            ),
          ),
        ),
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
