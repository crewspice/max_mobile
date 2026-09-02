import 'package:flutter/material.dart';
import '../../../config/device_config.dart';
import '../../../models/lift_maintenance_history_item.dart';
import '../../../theme/app_colors.dart';
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
      textAlign: TextAlign.start,
      style: TextStyle(
        color: AppColors.yellow,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  // The avatar already identifies who - showing the name alongside it too
  // is redundant, so the name only appears when there's no avatar to fall
  // back on.
  Widget _personRow(String text, {String? initials}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: initials != null
          ? UserAvatar(
              initials: initials,
              radius: 10 * DeviceConfig.timelineNodeScale,
              color: AppColors.yellow,
              textColor: AppColors.main,
            )
          : _line(text),
    );
  }

  bool get _hasNotes =>
      issue.notes != null &&
      !issue.notes!.toLowerCase().startsWith('rc ') &&
      !issue.notes!.toLowerCase().startsWith('rr ');

  // Issues carried over from the old system have no reportedBy and no
  // related service despite being resolved - there's no structured
  // repair/reporter data for them, just a free-text note using the old
  // system's shorthand, so we scrub that shorthand instead of reading it
  // out verbatim.
  bool get _isLegacyIssue =>
      issue.resolved &&
      (issue.relatedServiceId ?? 0) == 0 &&
      issue.reportedBy == null;

  static const _legacyWordReplacements = {
    'l': 'left',
    'r': 'right',
    'lr': 'left & right',
  };

  String _matchCapitalization(String original, String replacement) {
    if (original.isEmpty) return replacement;
    final firstChar = original[0];
    if (firstChar != firstChar.toLowerCase()) {
      return replacement[0].toUpperCase() + replacement.substring(1);
    }
    return replacement;
  }

  String _scrubLegacyNotes(String notes) {
    final scrubbed = <String>[];

    for (final word in notes.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final lower = word.toLowerCase();

      if (lower == 'rc' || lower == 'rr') continue;

      final numeral = int.tryParse(word);
      if (numeral != null && numeral >= 0 && numeral <= 10) continue;

      final replacement = _legacyWordReplacements[lower];
      if (replacement != null) {
        scrubbed.add(_matchCapitalization(word, replacement));
        continue;
      }

      scrubbed.add(word);
    }

    return scrubbed.join(' ');
  }

  List<Widget> _legacyOrderedLines() {
    final lines = <Widget>[];

    if (issue.notes != null && issue.notes!.trim().isNotEmpty) {
      final scrubbed = _scrubLegacyNotes(issue.notes!);
      if (scrubbed.isNotEmpty) {
        lines.add(_line('"$scrubbed"', italic: true));
      }
    }

    return lines;
  }

  List<Widget> _serviceOrderedLines() {
    final lines = <Widget>[];

    // Same person reported and resolved it, and only one side left notes -
    // showing both a reported-by row and a resolved-by row (with a divider
    // between them) would just attribute the same person twice.
    final sameReporterAndPerformer = issue.performedByName != null &&
        issue.reportedByInitials != null &&
        issue.reportedByInitials == issue.performedByInitials;
    final repairNotesPresent = issue.repairNotes != null;
    final collapseToSingleNote =
        sameReporterAndPerformer && _hasNotes != repairNotesPresent;

    if (collapseToSingleNote) {
      final note = _hasNotes ? issue.notes! : issue.repairNotes!;
      lines.add(_line('"$note"', italic: true));

      if (issue.noRepairNeeded) {
        lines.add(_line('No repair needed'));
      }

      lines.add(
        _personRow(issue.performedByName!, initials: issue.performedByInitials),
      );

      return lines;
    }

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
          child: Divider(color: AppColors.yellow, height: 1),
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

    // Resolved issues always read notes -> reported by -> divider -> repair
    // notes -> performed by, regardless of whether they have a related
    // service - that ordering only decides it for unresolved issues.
    final lines = _isLegacyIssue
        ? _legacyOrderedLines()
        : issue.resolved || hasRelatedService
            ? _serviceOrderedLines()
            : _defaultOrderedLines();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OrnateCard(
        color: AppColors.mainLight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines,
                ),
              ),
            ),
            Positioned(
              top: -6,
              left: 2,
              child: Text(
                issue.resolved ? 'Resolved' : 'Unresolved',
                style: TextStyle(
                  color: issue.resolved ? Colors.white : AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (issue.partAction != null)
              Positioned(
                bottom: -6,
                left: 2,
                child: Text(
                  _pastParticiple(issue.partAction!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (issue.quantity != null && issue.quantity != 0)
              Positioned(
                bottom: -6,
                right: 2,
                child: Text(
                  'x${issue.quantity}',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
