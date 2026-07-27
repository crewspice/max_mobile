class InventoryItem {
  final String liftType;
  final String serialNumber;
  final String? position;
  final bool upToDate;

  InventoryItem({
    required this.liftType,
    required this.serialNumber,
    this.position,
    required this.upToDate,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      liftType: json['liftType'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      position: json['position'],
      upToDate: json['upToDate'] ?? false,
    );
  }
}