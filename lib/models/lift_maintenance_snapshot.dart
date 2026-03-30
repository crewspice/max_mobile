class LiftMaintenanceSnapshot {
  final bool? upToDate;

  // ✅ PM fields with prefix
  final int? pmId;
  final DateTime? pmCompletedAt;
  final String? pmCompletedByFullName;
  final String? pmCompletedByNickname;
  final String? pmNotes;

  // ✅ Active maintenance action fields
  final int? actionId;
  final String? actionTypeName;
  final int? actionTypeId;
  final DateTime? actionCreatedAt;
  final String? actionReportedBy;
  final String? actionNotes;

  LiftMaintenanceSnapshot({
    this.upToDate,
    this.pmId,
    this.pmCompletedAt,
    this.pmCompletedByFullName,
    this.pmCompletedByNickname,
    this.pmNotes,
    this.actionId,
    this.actionTypeName,
    this.actionTypeId,
    this.actionCreatedAt,
    this.actionReportedBy,
    this.actionNotes,
  });

  factory LiftMaintenanceSnapshot.fromJson(Map<String, dynamic> json) {
    return LiftMaintenanceSnapshot(
      upToDate: json['upToDate'],

      // PM
      pmId: json['pmId'],
      pmCompletedAt: json['pmCompletedAt'] != null
          ? DateTime.parse(json['pmCompletedAt'])
          : null,
      pmCompletedByFullName: json['pmCompletedByFullName'],
      pmCompletedByNickname: json['pmCompletedByNickname'],
      pmNotes: json['pmNotes'],

      // Maintenance Action
      actionId: json['actionId'],
      actionTypeName: json['actionTypeName'],
      actionTypeId: json['actionTypeId'],
      actionCreatedAt: json['actionCreatedAt'] != null
          ? DateTime.parse(json['actionCreatedAt'])
          : null,
      actionReportedBy: json['actionReportedBy'],
      actionNotes: json['actionNotes'],
    );
  }
}