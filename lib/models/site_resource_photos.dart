class SiteResourcePhoto {
  final int rentalId;
  final String imageUrl;
  final int confidence;
  final String reason;

  SiteResourcePhoto({
    required this.rentalId,
    required this.imageUrl,
    required this.confidence,
    required this.reason,
  });

  factory SiteResourcePhoto.fromJson(Map<String, dynamic> json) {
    return SiteResourcePhoto(
      rentalId: json['rentalId'],
      imageUrl: json['imageUrl'] ?? '',
      confidence: json['confidence'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class SiteResourcePhotos {
  final bool hasHelpfulPhotos;
  final List<SiteResourcePhoto> photos;

  SiteResourcePhotos({
    required this.hasHelpfulPhotos,
    required this.photos,
  });

  factory SiteResourcePhotos.fromJson(Map<String, dynamic> json) {
    return SiteResourcePhotos(
      hasHelpfulPhotos: json['hasHelpfulPhotos'] ?? false,
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((p) => SiteResourcePhoto.fromJson(p))
          .toList(),
    );
  }
}
