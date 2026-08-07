class LiftOption {
  final int rentalItemId;
  final String liftType;
  final String serialNumber;
  final String siteName;

  LiftOption({
    required this.rentalItemId,
    required this.liftType,
    required this.serialNumber,
    required this.siteName,
  });

  factory LiftOption.fromJson(Map<String, dynamic> json) {
    return LiftOption(
      rentalItemId: json['rentalItemId'],
      liftType: json['liftType'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      siteName: json['siteName'] ?? '',
    );
  }
}
