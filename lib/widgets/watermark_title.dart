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
  // Defaults match the original maintenance-card look (yellow text over a
  // dark glyph); callers on a different background - or that want the title
  // text itself in their own element color - override one or both.
  final Color textColor;
  final Color glyphColor;
  final double? fontSize;

  const WatermarkTitle({
    super.key,
    required this.text,
    required this.glyph,
    this.glyphSize = 96,
    this.glyphAlignment = Alignment.center,
    this.textColor = AppColors.yellow,
    this.glyphColor = AppColors.main,
    this.fontSize,
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
                color: glyphColor,
              ),
            ),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
