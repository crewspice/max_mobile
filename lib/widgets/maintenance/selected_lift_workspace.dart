import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../models/lift_maintenance_snapshot.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../views/maintenance_ui_state.dart';
import '../curved_stack_card.dart';
import '../hold_to_confirm_button.dart';
import 'beaded_circle_border.dart';
import 'circle_button_jitter.dart';
import 'mode_selector_row.dart';
import 'repair_card.dart';
import 'snapshot_panel.dart';
import 'issue_entry_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/device_config.dart';


class SelectedLiftWorkspace extends StatefulWidget {
  final Lift lift;
  final LiftMaintenanceSnapshot snapshot;
  final MaintenanceUiState ui;

  final Widget? history;

  final String currentUserId;
  final VoidCallback onRefresh;

  const SelectedLiftWorkspace({
    super.key,
    required this.lift,
    required this.snapshot,
    required this.ui,
    required this.currentUserId,
    required this.onRefresh,
    this.history,
  });

  @override
  State<SelectedLiftWorkspace> createState() =>
      _SelectedLiftWorkspaceState();
}

class _SelectedLiftWorkspaceState extends State<SelectedLiftWorkspace> {

  Widget _recordButton({
    required String label,
    required bool active,
    required Color glowColor,
    required VoidCallback onPressed,
  }) {
    final baseDiameter = 76.0 * DeviceConfig.circleScale();
    final fontSize =
        13.0 * DeviceConfig.circleScale() * DeviceConfig.circleTextScale();
    final jitter = circleButtonJitter(label, baseDiameter);

    // The circle's own look never changes with selection - only the beaded
    // animated border wrapped around it below does, matching the mode
    // selector rows' selected style. The plain border only shows when not
    // active, since the beaded border already frames the circle on its own.
    final circle = Container(
      width: jitter.diameter,
      height: jitter.diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mainBackground,
        border: active
            ? null
            : Border.all(
                color: AppColors.yellow.withOpacity(.35),
                width: 1,
              ),
      ),
      child: Material(
        shape: const CircleBorder(),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );

    return Transform.translate(
      offset: Offset(jitter.dx, jitter.dy),
      child: active
          ? BeadedCircleBorder(color: glowColor, child: circle)
          : circle,
    );
  }

  Widget _pmButton() {
    final label = widget.snapshot.needsAnnual == true ? 'Annual' : 'PM';
    final baseDiameter = 76.0 * DeviceConfig.circleScale();
    final jitter = circleButtonJitter(label, baseDiameter);

    return Transform.translate(
      offset: Offset(jitter.dx, jitter.dy),
      child: Container(
        width: jitter.diameter,
        height: jitter.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.yellow.withOpacity(.35),
            width: 1,
          ),
        ),
        child: HoldToConfirmButton(
          label: label,
          textSize: 13 *
              DeviceConfig.circleScale() *
              DeviceConfig.circleTextScale(),
          baseColor: AppColors.mainBackground,
          textColor: AppColors.yellow,
          progressColor: AppColors.yellow,
          holdDuration: const Duration(seconds: 2),
          circular: true,
          diameter: jitter.diameter,
          onConfirmed: _submitPm,
        ),
      ),
    );
  }

  // The annual/PM status card, any open issue/repair cards, and the record
  // entry card (when open) read as a single stack: shape only depends on
  // each card's position within it, so this builds them together with the
  // right StackPosition rather than each card guessing its own place.
  //
  // While actively recording a repair/issue, the entry card stands alone -
  // the PM status card and any unresolved-action cards step aside so the
  // entry form has the stack's full attention.
  List<Widget> _buildStatusStack() {
    final entryMode = widget.ui.selectedRecord == RecordMode.issue
        ? IssueEntryMode.issue
        : widget.ui.selectedRecord == RecordMode.repair
            ? IssueEntryMode.repair
            : null;

    if (entryMode != null) {
      return [
        IssueEntryCard(
          liftId: widget.lift.liftId,
          currentUserId: widget.currentUserId,
          mode: entryMode,
          position: StackPosition.only,
          onComplete: () {
            widget.ui.selectRecord(null);
            widget.onRefresh();
          },
        ),
      ];
    }

    final total = 1 + widget.snapshot.maintenanceActions.length;

    StackPosition positionFor(int index) {
      if (total <= 1) return StackPosition.only;
      if (index == 0) return StackPosition.top;
      if (index == total - 1) return StackPosition.bottom;
      return StackPosition.medial;
    }

    var index = 0;
    final cards = <Widget>[
      SnapshotPanel(
        lift: widget.lift,
        snapshot: widget.snapshot,
        position: positionFor(index++),
      ),
    ];

    for (final action in widget.snapshot.maintenanceActions) {
      cards.add(RepairCard(
        action: action,
        currentUserId: widget.currentUserId,
        position: positionFor(index++),
        onResolved: widget.onRefresh,
      ));
    }

    return [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(height: 18),
        cards[i],
      ],
    ];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitPm() async {
    try {
      await ApiService().submitPreventiveMaintenance(
        liftId: widget.lift.liftId,
        completedByInitial: widget.currentUserId,
        isAnnualInspection: widget.snapshot.needsAnnual == true,
      );

      if (!mounted) return;

      widget.onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            widget.snapshot.needsAnnual == true
                ? 'Annual inspection recorded'
                : 'Preventative maintenance recorded',
            style: const TextStyle(
              color: AppColors.green,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            'Failed: $e',
            style: const TextStyle(
              color: AppColors.red,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.ui,
        builder: (context, _) {
          print('REBUILD SELECTED RECORD: ${widget.ui.selectedRecord}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

            Text(
                'Record:',
                style: GoogleFonts.permanentMarker(
                color: AppColors.yellow,
                // fontWeight: FontWeight.bold,
                ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                _pmButton(),

                _recordButton(
                  label: 'Repair',
                  active: widget.ui.selectedRecord == RecordMode.repair,
                  glowColor: AppColors.green,
                  onPressed: () {
                    widget.ui.selectRecord(RecordMode.repair);
                  },
                ),

                _recordButton(
                  label: 'Issue',
                  active: widget.ui.selectedRecord == RecordMode.issue,
                  glowColor: AppColors.red,
                  onPressed: () {
                    widget.ui.selectRecord(RecordMode.issue);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            ..._buildStatusStack(),

            const SizedBox(height: 16),

            ModeSelectorRow<HistoryFilter>(
              label: 'History',
              selected: widget.ui.selectedHistory,
              onToggle: widget.ui.toggleHistoryFilter,
              buttons: const [
                ModeButton('PMs', HistoryFilter.pms),
                ModeButton('Rentals', HistoryFilter.rentals),
                ModeButton('Issues', HistoryFilter.issues),
                ModeButton('Annuals', HistoryFilter.annuals),
              ],
            ),

            if (widget.history != null) ...[
              const SizedBox(height: 16),
              widget.history!,
            ],
          ],
        );
      },
    );
  }
}