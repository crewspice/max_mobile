class LiftMaintenanceHistory {
  final int? pmId;
  final DateTime? completedAt;
  final String? completedByUserName;
  final String? notes;

  final int? serviceId;
  final String? serviceType;
  final DateTime? serviceDate;
  final String? serviceStatus;
  final String? reason;

  LiftMaintenanceHistory({
    this.pmId,
    this.completedAt,
    this.completedByUserName,
    this.notes,
    this.serviceId,
    this.serviceType,
    this.serviceDate,
    this.serviceStatus,
    this.reason,
  });

  factory LiftMaintenanceHistory.fromJson(Map<String, dynamic> json) {
    return LiftMaintenanceHistory(
      pmId: json['pmId'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      completedByUserName: json['completedByUserName'],
      notes: json['notes'],
      serviceId: json['serviceId'],
      serviceType: json['serviceType'],
      serviceDate: json['serviceDate'] != null
          ? DateTime.parse(json['serviceDate'])
          : null,
      serviceStatus: json['serviceStatus'],
      reason: json['reason'],
    );
  }
}
