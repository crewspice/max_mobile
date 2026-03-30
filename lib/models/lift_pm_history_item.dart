class LiftPmHistoryItem {
  final int? pmId;
  final DateTime? completedAt;
  final String? notes;
  final String? completedByName;
  final String? completedByNickname;
  final String? completedByInitials;

  LiftPmHistoryItem({
    required this.pmId,
    this.completedAt,
    this.notes,
    this.completedByName,
    this.completedByNickname,
    this.completedByInitials,
  });

  factory LiftPmHistoryItem.fromJson(Map<String, dynamic> json) {
    return LiftPmHistoryItem(
      pmId: json['pmId'] as int?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'] as String?,
      completedByName: json['completedByName'] as String?,
      completedByNickname: json['completedByNickname'] as String?,
      completedByInitials: json['completedByInitials'] as String?,
    );
  }
}