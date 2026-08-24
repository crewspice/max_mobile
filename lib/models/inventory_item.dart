class InventoryItem {
  final String liftType;
  final String serialNumber;
  final String? position;
  final bool upToDate;
  final int? siteId;
  final String? siteName;
  final String? streetAddress;
  final String? city;
  final String? customerName;
  final String? actionType;
  final int? daysOnRent;
  final DateTime? lastPmDate;
  final String? lastPmPerformerInitials;
  final int? pendingRepairs;

  InventoryItem({
    required this.liftType,
    required this.serialNumber,
    this.position,
    required this.upToDate,
    this.siteId,
    this.siteName,
    this.streetAddress,
    this.city,
    this.customerName,
    this.actionType,
    this.daysOnRent,
    this.lastPmDate,
    this.lastPmPerformerInitials,
    this.pendingRepairs,
  });

  bool get isPickup => actionType == 'Pickup';

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      liftType: json['liftType'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      position: json['position'],
      upToDate: json['upToDate'] ?? false,
      siteId: json['siteId'] as int?,
      siteName: json['siteName'],
      streetAddress: json['streetAddress'],
      city: json['city'],
      customerName: json['customerName'],
      actionType: json['actionType'],
      daysOnRent: json['daysOnRent'] as int?,
      lastPmDate: json['lastPmDate'] != null
          ? DateTime.parse(json['lastPmDate'])
          : null,
      lastPmPerformerInitials: json['lastPmPerformerInitials'],
      pendingRepairs: json['pendingRepairs'] as int?,
    );
  }
}
