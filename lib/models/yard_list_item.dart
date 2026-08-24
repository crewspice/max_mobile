class YardListItem {
  final int? liftId;
  final String? liftType;
  final String? serialNumber;
  final bool upToDate;
  final bool needsRepair;

  YardListItem({
    this.liftId,
    this.liftType,
    this.serialNumber,
    required this.upToDate,
    this.needsRepair = false,
  });

  factory YardListItem.fromJson(Map<String, dynamic> json) {
    return YardListItem(
      liftId: json['liftId'],
      liftType: json['liftType'],
      serialNumber: json['serialNumber'],
      upToDate: json['upToDate'] ?? false,
      needsRepair: json['needsRepair'] ?? false,
    );
  }
}
