class InventoryItem {
  final String liftType;
  final String serialNumber;
  final String? position; // 👈 ADD THIS

  InventoryItem({
    required this.liftType,
    required this.serialNumber,
    this.position,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      liftType: json['liftType'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      position: json['position'], // 👈 ADD THIS
    );
  }
}