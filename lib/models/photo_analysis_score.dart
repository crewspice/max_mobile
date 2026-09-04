class PhotoAnalysisScore {
  final int? photoId;
  final int? rentalId;
  final String? status;
  final bool? isHelpfulSiteResource;
  final int? confidence;
  final String? reason;

  PhotoAnalysisScore({
    this.photoId,
    this.rentalId,
    this.status,
    this.isHelpfulSiteResource,
    this.confidence,
    this.reason,
  });

  factory PhotoAnalysisScore.fromJson(Map<String, dynamic> json) {
    return PhotoAnalysisScore(
      photoId: json['photoId'],
      rentalId: json['rentalId'],
      status: json['status'],
      isHelpfulSiteResource: json['isHelpfulSiteResource'],
      confidence: json['confidence'],
      reason: json['reason'],
    );
  }
}
