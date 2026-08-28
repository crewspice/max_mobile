import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Replaces a small leading icon with a large outlined glyph sitting behind
// the title text as a subtle watermark — dark enough (AppColors.main) to
// read as texture rather than a UI element, with the glyph's shape (not its
// size or position) doing the work of telling title types apart. The glyph
// is rendered via OverflowBox so its (large) size never enters into layout
// — this widget always takes up exactly the text's own footprint, and nothing
// around it shifts as the glyph size changes.
class WatermarkTitle extends StatelessWidget {
  final String text;
  final IconData glyph;
  final double glyphSize;
  // Where the (larger) glyph sits relative to the text's own footprint.
  // Alignment.center spreads the overflow evenly above and below; a
  // top-biased alignment like Alignment(0, -1) keeps the glyph's top edge
  // flush with the text's top, so all the extra size grows downward only —
  // useful when there's another line sitting close above the title.
  final Alignment glyphAlignment;

  const WatermarkTitle({
    super.key,
    required this.text,
    required this.glyph,
    this.glyphSize = 96,
    this.glyphAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              minWidth: 0,
              maxWidth: glyphSize,
              minHeight: 0,
              maxHeight: glyphSize,
              alignment: glyphAlignment,
              child: Icon(
                glyph,
                size: glyphSize,
                color: AppColors.main,
              ),
            ),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
