class YardShortageWarning {
  final String? liftType;
  final int upcomingCount;
  final int upToDateYardCount;

  YardShortageWarning({
    this.liftType,
    required this.upcomingCount,
    required this.upToDateYardCount,
  });

  factory YardShortageWarning.fromJson(Map<String, dynamic> json) {
    return YardShortageWarning(
      liftType: json['liftType'],
      upcomingCount: json['upcomingCount'] ?? 0,
      upToDateYardCount: json['upToDateYardCount'] ?? 0,
    );
  }
}
