import 'package:flutter/material.dart';
import '../../models/lift.dart';
import '../../models/lift_maintenance_snapshot.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../views/maintenance_ui_state.dart';
import '../hold_to_confirm_button.dart';
import 'mode_selector_row.dart';
import 'snapshot_panel.dart';
import 'issue_entry_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/device_config.dart';


class SelectedLiftWorkspace extends StatefulWidget {
  final Lift lift;
  final LiftMaintenanceSnapshot snapshot;
  final MaintenanceUiState ui;

  final Widget? unresolvedActions;
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
    this.unresolvedActions,
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
    const diameter = 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.main,
        border: Border.all(
          color: active ? glowColor : AppColors.yellow.withOpacity(.35),
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(.55),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
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
                fontSize: DeviceConfig.isIphone ? 11 : 13,
              ),
            ),
          ),
        ),
      ),
    );
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

                HoldToConfirmButton(
                  icon: !DeviceConfig.isIpad ? null : const Icon(Icons.check),
                  label: widget.snapshot.needsAnnual == true
                      ? 'Annual'
                      : 'PM',
                  textSize: DeviceConfig.isIphone ? 11 : 13,
                  baseColor: AppColors.main,
                  textColor: AppColors.yellow,
                  progressColor: AppColors.yellow,
                  holdDuration: const Duration(seconds: 2),
                  circular: true,
                  diameter: 76,
                  onConfirmed: _submitPm,
                ),

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

            if (widget.ui.selectedRecord == RecordMode.issue)
              IssueEntryCard(
                liftId: widget.lift.liftId,
                currentUserId: widget.currentUserId,
                mode: IssueEntryMode.issue,
                onComplete: () {
                  widget.ui.selectRecord(null);
                  widget.onRefresh();
                },
              ),

            if (widget.ui.selectedRecord == RecordMode.repair)
              IssueEntryCard(
                liftId: widget.lift.liftId,
                currentUserId: widget.currentUserId,
                mode: IssueEntryMode.repair,
                onComplete: () {
                  widget.ui.selectRecord(null);
                  widget.onRefresh();
                },
              ),

            const SizedBox(height: 16),

            SnapshotPanel(
                lift: widget.lift,
                snapshot: widget.snapshot,
            ),

            if (widget.unresolvedActions != null) ...[
                const SizedBox(height: 16),
                widget.unresolvedActions!,
            ],

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