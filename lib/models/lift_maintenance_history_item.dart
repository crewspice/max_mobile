class LiftMaintenanceHistoryItem {
  final int? actionId;
  final int? relatedServiceId;
  final DateTime? performedAt;
  final String? notes;
  final DateTime? createdAt;
  final bool resolved;
  final String? partAction;
  final int? quantity;
  final bool noRepairNeeded;
  final String? repairNotes;
  final int? actionTypeId;
  final String? actionTypeName;
  final String? performedByName;
  final String? performedByNickname;
  final String? performedByInitials;
  final String? reportedBy;

  LiftMaintenanceHistoryItem({
    required this.actionId,
    this.relatedServiceId,
    this.performedAt,
    this.notes,
    this.createdAt,
    this.resolved = false,
    this.partAction,
    this.quantity,
    this.noRepairNeeded = false,
    this.repairNotes,
    this.actionTypeId,
    this.actionTypeName,
    this.performedByName,
    this.performedByNickname,
    this.performedByInitials,
    this.reportedBy,
  });

  factory LiftMaintenanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return LiftMaintenanceHistoryItem(
      actionId: json['actionId'] as int?,
      relatedServiceId: json['relatedServiceId'] as int?,
      performedAt: json['performedAt'] != null
          ? DateTime.parse(json['performedAt'])
          : null,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      resolved: json['resolved'] == true || json['resolved'] == 1,
      partAction: json['partAction'] as String?,
      quantity: json['quantity'] as int?,
      noRepairNeeded: json['noRepairNeeded'] == true || json['noRepairNeeded'] == 1,
      repairNotes: json['repairNotes'] as String?,
      actionTypeId: json['actionTypeId'] as int?,
      actionTypeName: json['actionTypeName'] as String?,
      performedByName: json['performedByName'] as String?,
      performedByNickname: json['performedByNickname'] as String?,
      performedByInitials: json['performedByInitials'] as String?,
      reportedBy: json['reportedBy'] as String?,
    );
  }
}