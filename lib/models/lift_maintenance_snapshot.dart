import 'lift_maintenance_history_item.dart';

class LiftMaintenanceSnapshot {
  final bool? upToDate;
  final bool? needsAnnual;

  // ✅ PM fields with prefix
  final int? pmId;
  final DateTime? pmCompletedAt;
  final String? pmCompletedByFullName;
  final String? pmCompletedByNickname;
  final String? pmCompletedByInitials;
  final String? pmNotes;

  // ✅ Active maintenance actions
  final List<LiftMaintenanceHistoryItem> maintenanceActions;

  LiftMaintenanceSnapshot({
    this.upToDate,
    this.needsAnnual,
    this.pmId,
    this.pmCompletedAt,
    this.pmCompletedByFullName,
    this.pmCompletedByNickname,
    this.pmCompletedByInitials,
    this.pmNotes,
    this.maintenanceActions = const [],
  });

  factory LiftMaintenanceSnapshot.fromJson(Map<String, dynamic> json) {
    return LiftMaintenanceSnapshot(
      upToDate: json['upToDate'],
      needsAnnual: json['needsAnnual'],

      // PM
      pmId: json['pmId'],
      pmCompletedAt: json['pmCompletedAt'] != null
          ? DateTime.parse(json['pmCompletedAt'])
          : null,
      pmCompletedByFullName: json['pmCompletedByFullName'],
      pmCompletedByNickname: json['pmCompletedByNickname'],
      pmCompletedByInitials: json['pmCompletedByInitials'],
      pmNotes: json['pmNotes'],

      // Maintenance Actions
      maintenanceActions:
      (json['maintenanceActions'] as List<dynamic>?)
          ?.map((e) => LiftMaintenanceHistoryItem.fromJson(e))
          .toList() ??
      [],
    );
  }
}