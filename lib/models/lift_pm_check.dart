class Lift {
  final int liftId;
  final String? liftType;
  final String? serialNumber;
  final String? model;
  final String? description;

  Lift({
    required this.liftId,
    this.liftType,
    this.serialNumber,
    this.model,
    this.description,
  });

  factory Lift.fromJson(Map<String, dynamic> json) {
    return Lift(
      liftId: json['liftId'],
      liftType: json['liftType'],
      serialNumber: json['serialNumber'],
      model: json['model'],
      description: json['description'],
    );
  }
}
