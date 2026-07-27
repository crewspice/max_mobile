class LiftRentalHistoryItem {
  final int? rentalItemId;
  final int? rentalOrderId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? customerName;
  final String? siteName;
  final String? streetAddress;
  final String? city;
  final String? driverId;

  LiftRentalHistoryItem({
    required this.rentalItemId,
    this.rentalOrderId,
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
      rentalItemId: json['rentalItemId'] as int?,
      rentalOrderId: json['rentalOrderId'] as int?,
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