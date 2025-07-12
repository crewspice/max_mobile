class Rental {
  final int rentalId;
  final String? name;
  final String? deliveryDate;  // Now a String
  final bool? isActive;
  final String? serialNumber;
  final String? liftType;
  final String? driver;
  final String? status;
  final String? siteName;
  final String? streetAddress;
  final String? city;
  final String? customer;
  final String? orderedByContactName; // New field
  final String? siteContactName; // New field
  final String? orderedByContactNumber; // New field
  final String? siteContactNumber; // New field

  Rental({
    required this.rentalId,
    this.name,
    this.deliveryDate,
    this.isActive,
    this.serialNumber,
    this.liftType,
    this.driver,
    this.status,
    this.siteName,
    this.streetAddress,
    this.city,
    this.customer,
    this.orderedByContactName, // New field
    this.siteContactName, // New field
    this.orderedByContactNumber, // New field
    this.siteContactNumber, // New field
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      rentalId: json['id'] as int,
      name: json['name'] as String?,
      deliveryDate: json['deliveryDate'] as String?,
      isActive: json['isActive'] as bool?,
      serialNumber: json['serialNumber'] as String?,
      liftType: json['liftType'] as String?,
      driver: json['driver'] as String?,
      status: json['status'] as String?,
      siteName: json['siteName'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      customer: json['customerName'] as String?,  // Update this field to match the backend key
      orderedByContactName: json['orderedByContactName'] as String?,
      siteContactName: json['siteContactName'] as String?,
      orderedByContactNumber: json['orderedByContactNumber'] as String?,
      siteContactNumber: json['siteContactNumber'] as String?,
    );
  }
}
