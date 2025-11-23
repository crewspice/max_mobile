class Stop {
  final int id;
  final int orderId;
  final String type; // "SERVICE" or "RENTAL"

  // Rental-specific
  final String? status;
  final String? deliveryDate;

  // Service-specific
  final String? serviceDate;
  final String? serviceType;
  final String? reason;
  final String? newLiftType;
  final String? newSiteName;
  final String? newStreetAddress;
  final String? newCity;

  // Shared
  final String? driverId;
  final String? name;
  final String? siteName;
  final String? streetAddress;
  final String? city;
  final String? liftType;
  final String? time;
  final String? orderedByContactName;
  final String? orderedByContactPhone;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? locationNotes;
  final String? preTripInstructions;
  final double? latitude;
  final double? longitude;
  final String? arrivalTime;
  final String? departedTime;
  final int? driverNumber;
  final String? truck;
  final bool hasPhoto;

  Stop({
    required this.id,
    required this.orderId,
    required this.type,
    this.driverId,
    this.name,
    this.status,
    this.deliveryDate,
    this.serviceDate,
    this.serviceType,
    this.reason,
    this.siteName,
    this.streetAddress,
    this.city,
    this.liftType,
    this.newSiteName,
    this.newStreetAddress,
    this.newCity,
    this.newLiftType,
    this.time,
    this.orderedByContactName,
    this.orderedByContactPhone,
    this.siteContactName,
    this.siteContactPhone,
    this.locationNotes,
    this.preTripInstructions,
    this.latitude,
    this.longitude,
    this.arrivalTime,
    this.departedTime,
    this.driverNumber,
    this.truck,
    this.hasPhoto = false, // default false
  });


  // ⭐ IMPORTANT: Immutable update pattern
  Stop copyWith({
    int? id,
    int? orderId,
    String? type,
    String? driverId,
    String? name,
    String? status,
    String? deliveryDate,
    String? serviceDate,
    String? serviceType,
    String? reason,
    String? siteName,
    String? streetAddress,
    String? city,
    String? liftType,
    String? newSiteName,
    String? newStreetAddress,
    String? newCity,
    String? newLiftType,
    String? time,
    String? orderedByContactName,
    String? orderedByContactPhone,
    String? siteContactName,
    String? siteContactPhone,
    String? locationNotes,
    String? preTripInstructions,
    double? latitude,
    double? longitude,
    String? arrivalTime,
    String? departedTime,
    int? driverNumber,
    String? truck,
    bool? hasPhoto,
  }) {
    return Stop(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      status: status ?? this.status,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      serviceDate: serviceDate ?? this.serviceDate,
      serviceType: serviceType ?? this.serviceType,
      reason: reason ?? this.reason,
      siteName: siteName ?? this.siteName,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      liftType: liftType ?? this.liftType,
      newSiteName: newSiteName ?? this.newSiteName,
      newStreetAddress: newStreetAddress ?? this.newStreetAddress,
      newCity: newCity ?? this.newCity,
      newLiftType: newLiftType ?? this.newLiftType,
      time: time ?? this.time,
      orderedByContactName:
          orderedByContactName ?? this.orderedByContactName,
      orderedByContactPhone:
          orderedByContactPhone ?? this.orderedByContactPhone,
      siteContactName: siteContactName ?? this.siteContactName,
      siteContactPhone: siteContactPhone ?? this.siteContactPhone,
      locationNotes: locationNotes ?? this.locationNotes,
      preTripInstructions:
          preTripInstructions ?? this.preTripInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departedTime: departedTime ?? this.departedTime,
      driverNumber: driverNumber ?? this.driverNumber,
      truck: truck ?? this.truck,
      hasPhoto: hasPhoto ?? this.hasPhoto,
    );
  }


  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      orderId: json['orderId'],
      type: json['type'],
      driverId: json['driverId'],
      name: json['name'],
      status: json['status'],
      deliveryDate: json['deliveryDate'],
      serviceDate: json['serviceDate'],
      serviceType: json['serviceType'],
      reason: json['reason'],
      siteName: json['siteName'],
      streetAddress: json['streetAddress'],
      city: json['city'],
      liftType: json['liftType'],
      newSiteName: json['newSiteName'],
      newStreetAddress: json['newStreetAddress'],
      newCity: json['newCity'],
      newLiftType: json['newLiftType'] ?? "Unknown",
      time: json['time'],
      orderedByContactName: json['orderedByContactName'],
      orderedByContactPhone: json['orderedByContactNumber'],
      siteContactName: json['siteContactName'],
      siteContactPhone: json['siteContactNumber'],
      locationNotes: json['locationNotes'],
      preTripInstructions: json['preTripInstructions'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      arrivalTime: json['arrivalTime'],
      departedTime: json['departedTime'],
      driverNumber: json['driverNumber'],
      truck: json['truck'],
      hasPhoto: json['hasPhoto'] ?? false, // NEW: parse JSON or default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "orderId": orderId,
      "type": type,
      "driverId": driverId,
      "name": name,
      "status": status,
      "deliveryDate": deliveryDate,
      "serviceDate": serviceDate,
      "serviceType": serviceType,
      "reason": reason,
      "siteName": siteName,
      "streetAddress": streetAddress,
      "city": city,
      "liftType": liftType,
      "newSiteName": newSiteName,
      "newStreetAddress": newStreetAddress,
      "newCity": newCity,
      "newLiftType": newLiftType,
      "time": time,
      "orderedByContactName": orderedByContactName,
      "orderedByContactPhone": orderedByContactPhone,
      "siteContactName": siteContactName,
      "siteContactPhone": siteContactPhone,
      "locationNotes": locationNotes,
      "preTripInstructions": preTripInstructions,
      "latitude": latitude,
      "longitude": longitude,
      "arrivalTime": arrivalTime,
      "departedTime": departedTime,
      "driverNumber": driverNumber,
      "truck": truck,
      "hasPhoto": hasPhoto, // NEW: include in JSON
    };
  }
}
