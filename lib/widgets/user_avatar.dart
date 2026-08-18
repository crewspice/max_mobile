import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Circular user avatar. Shows the uploaded profile picture when one exists,
/// otherwise falls back to a colored circle with the user's initials — the
/// same look every avatar spot in the app already had before profile
/// pictures existed.
class UserAvatar extends StatelessWidget {
  final String? initials;
  final double radius;
  final Color color;
  final Color textColor;

  // Bump this (e.g. after an upload/reset) to force a fresh network fetch
  // instead of whatever image this same widget instance already resolved —
  // a changed URL is what actually busts Flutter's image cache, clearing
  // imageCache alone doesn't affect an already-mounted Image.network.
  final Object? cacheBust;

  const UserAvatar({
    super.key,
    required this.initials,
    required this.radius,
    required this.color,
    this.textColor = AppColors.main,
    this.cacheBust,
  });

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        (initials == null || initials!.isEmpty) ? "?" : initials!,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (initials == null || initials!.isEmpty) {
      return _fallback();
    }

    var url = ApiService().profilePictureUrl(initials!);
    if (cacheBust != null) {
      url = '$url?v=$cacheBust';
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _fallback();
          },
        ),
      ),
    );
  }
}
