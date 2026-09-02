import 'package:cached_network_image/cached_network_image.dart';
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

  // Bump this (e.g. after an upload/reset) to force a fresh fetch instead of
  // the disk/memory-cached image this URL already resolved to — CachedNetworkImage
  // keys its cache on the URL, so a changed URL is what actually busts it.
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
    final text = (initials == null || initials!.isEmpty) ? "?" : initials!;
    final fontSize = switch (text.length) {
      1 => radius * 1.4,
      2 => radius * 0.95,
      _ => radius * 0.8,
    };
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Transform.translate(
        offset: const Offset(0, -1),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
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
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _fallback(),
          placeholder: (context, url) => _fallback(),
        ),
      ),
    );
  }
}
