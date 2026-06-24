import 'dart:ui';
import '../theme/app_colors.dart';

class ColorField {
  static Color fromX(
    double x,
    double centerX,
    double width,
  ) {
    final normalized =
        ((x - centerX) / (width / 2))
            .clamp(-1.0, 1.0);

    // left → yellow → green → red (right)
    if (normalized < 0) {
      final t = normalized + 1; // 0..1
      return Color.lerp(
        AppColors.yellow,
        AppColors.green,
        t,
      )!;
    } else {
      return Color.lerp(
        AppColors.green,
        AppColors.red,
        normalized,
      )!;
    }
  }
}