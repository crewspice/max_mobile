class LiftRentalHistoryItem {
  final int? rentalId;
  final int? siteId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? customerName;
  final String? siteName;
  final String? streetAddress;
  final String? city;
  final String? driverId;

  LiftRentalHistoryItem({
    required this.rentalId,
    this.siteId,
    this.startDate,
    this.endDate,
    this.status,
    this.customerName,
    this.siteName,
    this.streetAddress,
    this.city,
    this.driverId,
  });

  factory LiftRentalHistoryItem.fromJson(Map<String, dynamic> json) {
    return LiftRentalHistoryItem(
      rentalId: json['rentalId'] as int?,
      siteId: json['siteId'] as int?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      status: json['status'] as String?,
      customerName: json['customerName'] as String?,
      siteName: json['siteName'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      driverId: json['driverId'] as String?,
    );
  }
}