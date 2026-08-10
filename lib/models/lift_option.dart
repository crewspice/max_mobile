class LiftOption {
  final int rentalId;
  final String liftType;
  final String serialNumber;
  final String siteName;

  LiftOption({
    required this.rentalId,
    required this.liftType,
    required this.serialNumber,
    required this.siteName,
  });

  factory LiftOption.fromJson(Map<String, dynamic> json) {
    return LiftOption(
      rentalId: json['rentalId'],
      liftType: json['liftType'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      siteName: json['siteName'] ?? '',
    );
  }
}
