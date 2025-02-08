class Rental {
  final int rentalId;
  final String? name;
  final DateTime? rentalDate;
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
  final String? orderedByContactPhoneNumber; // New field
  final String? siteContactPhoneNumber; // New field

  Rental({
    required this.rentalId,
    this.name,
    this.rentalDate,
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
    this.orderedByContactPhoneNumber, // New field
    this.siteContactPhoneNumber, // New field
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      rentalId: json['id'] as int,
      name: json['name'] as String?,
      rentalDate: json['itemDeliveryDate'] != null 
          ? DateTime.parse(json['itemDeliveryDate']) 
          : null,
      isActive: json['invoiceComposed'] as bool?,
      serialNumber: json['serialNumber'] as String?,
      liftType: json['liftType'] as String?,
      driver: json['driverId'] as String?,
      status: json['status'] as String?,
      siteName: json['siteName'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      customer: json['customerName'] as String?,
      orderedByContactName: json['orderedByContactName'] as String?, // Parse new field
      siteContactName: json['siteContactName'] as String?, // Parse new field
      orderedByContactPhoneNumber: json['orderedByContactPhoneNumber'] as String?, // Parse new field
      siteContactPhoneNumber: json['siteContactPhoneNumber'] as String?, // Parse new field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rentalId': rentalId,
      'name': name ?? '',
      'itemDeliveryDate': rentalDate?.toIso8601String() ?? '',
      'invoiceComposed': isActive ?? false,
      'serialNumber': serialNumber ?? '',
      'liftType': liftType ?? '',
      'driverId': driver ?? '',
      'status': status ?? '',
      'siteName': siteName ?? '',
      'streetAddress': streetAddress ?? '',
      'city': city ?? '',
      'customer': customer ?? '',
      'orderedByContactName': orderedByContactName ?? '', // Convert new field to JSON
      'siteContactName': siteContactName ?? '', // Convert new field to JSON
      'orderedByContactPhoneNumber': orderedByContactPhoneNumber ?? '', // Convert new field to JSON
      'siteContactPhoneNumber': siteContactPhoneNumber ?? '', // Convert new field to JSON
    };
  }
}
