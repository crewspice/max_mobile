import 'package:flutter/material.dart';
import '../../../models/lift_maintenance_history_item.dart';
import '../../../theme/app_colors.dart';
import '../../date_label.dart';
import '../../ornate_card.dart';
import '../../user_avatar.dart';

class IssueTile extends StatelessWidget {
  final LiftMaintenanceHistoryItem issue;

  const IssueTile(
    this.issue, {
    super.key,
  });

  String _pastParticiple(String action) {
    switch (action.trim().toLowerCase()) {
      case 'repair':
        return 'Repaired';
      case 'replace':
        return 'Replaced';
      default:
        return action;
    }
  }

  Text _line(String text, {bool italic = false}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.green,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _personRow(String text, {String? initials}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (initials != null) ...[
            UserAvatar(
              initials: initials,
              radius: 10,
              color: AppColors.green,
              textColor: AppColors.main,
            ),
            const SizedBox(width: 6),
          ],
          _line(text),
        ],
      ),
    );
  }

  bool get _hasNotes =>
      issue.notes != null &&
      !issue.notes!.toLowerCase().startsWith('rc ') &&
      !issue.notes!.toLowerCase().startsWith('rr ');

  List<Widget> _serviceOrderedLines() {
    final lines = <Widget>[];

    if (_hasNotes) {
      lines.add(_line('"${issue.notes}"', italic: true));
    }

    if (issue.reportedBy != null) {
      lines.add(
        _personRow('- ${issue.reportedBy}', initials: issue.reportedByInitials),
      );
    }

    final hasLinesBelowSeparator = issue.repairNotes != null ||
        issue.noRepairNeeded ||
        issue.performedByName != null;

    if (hasLinesBelowSeparator) {
      lines.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(color: AppColors.green, height: 1),
        ),
      );
    }

    if (issue.repairNotes != null) {
      lines.add(_line(issue.repairNotes!, italic: true));
    }

    if (issue.noRepairNeeded) {
      lines.add(_line('No repair needed'));
    }

    if (issue.performedByName != null) {
      lines.add(
        _personRow(issue.performedByName!, initials: issue.performedByInitials),
      );
    }

    return lines;
  }

  List<Widget> _defaultOrderedLines() {
    final lines = <Widget>[];

    if (issue.actionTypeName != null) {
      lines.add(_line(issue.actionTypeName!));
    }

    if (issue.performedByName != null) {
      lines.add(
        _personRow(issue.performedByName!, initials: issue.performedByInitials),
      );
    }

    if (issue.reportedBy != null) {
      lines.add(
        _personRow(issue.reportedBy!, initials: issue.reportedByInitials),
      );
    }

    if (issue.partAction != null) {
      lines.add(_line(_pastParticiple(issue.partAction!)));
    }

    if (issue.quantity != null && issue.quantity != 0) {
      lines.add(_line('${issue.quantity}'));
    }

    if (issue.noRepairNeeded) {
      lines.add(_line('No repair needed'));
    }

    if (issue.repairNotes != null) {
      lines.add(_line(issue.repairNotes!, italic: true));
    }

    if (_hasNotes) {
      lines.add(_line(issue.notes!, italic: true));
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final hasRelatedService = (issue.relatedServiceId ?? 0) != 0;

    final lines =
        hasRelatedService ? _serviceOrderedLines() : _defaultOrderedLines();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OrnateCard(
        color: AppColors.mainLight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: lines,
              ),
            ),
            Positioned(
              top: -6,
              right: 2,
              child: DateLabel(
                date: issue.performedAt,
                color: AppColors.green,
                unknownLabel: '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
