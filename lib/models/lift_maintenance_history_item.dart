class LiftMaintenanceHistoryItem {
  final int? actionId;
  final int? relatedServiceId;
  final DateTime? performedAt;
  final String? notes;
  final DateTime? createdAt;
  final bool resolved;
  final String? partAction;
  final int? quantity;
  final int? actionTypeId;
  final String? actionTypeName;
  final String? performedByName;
  final String? performedByNickname;
  final String? performedByInitials;

  LiftMaintenanceHistoryItem({
    required this.actionId,
    this.relatedServiceId,
    this.performedAt,
    this.notes,
    this.createdAt,
    this.resolved = false,
    this.partAction,
    this.quantity,
    this.actionTypeId,
    this.actionTypeName,
    this.performedByName,
    this.performedByNickname,
    this.performedByInitials,
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
      actionTypeId: json['actionTypeId'] as int?,
      actionTypeName: json['actionTypeName'] as String?,
      performedByName: json['performedByName'] as String?,
      performedByNickname: json['performedByNickname'] as String?,
      performedByInitials: json['performedByInitials'] as String?,
    );
  }
}