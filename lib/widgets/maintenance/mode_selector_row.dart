import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeSelectorRow<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            '$label:',
            style: GoogleFonts.permanentMarker(
              color: AppColors.yellow,
              // fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            for (int i = 0; i < buttons.length; i++) ...[
              Expanded(
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: selected.contains(buttons[i].value)
                          ? [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.45),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                    onPressed: () {
                      onToggle(buttons[i].value);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selected.contains(buttons[i].value)
                              ? AppColors.yellow
                              : AppColors.main,
                      foregroundColor:
                          selected.contains(buttons[i].value)
                              ? AppColors.main
                              : AppColors.yellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(buttons[i].label),
                  ),
                ),
              ),
              if (i != buttons.length - 1)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class ModeButton<T> {
  final String label;
  final T value;

  const ModeButton(this.label, this.value);
}