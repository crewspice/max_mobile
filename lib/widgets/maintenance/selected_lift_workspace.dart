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
                children: [

                Expanded(
                    child: HoldToConfirmButton(
                    icon: const Icon(Icons.check),
                    label: widget.snapshot.needsAnnual == true
                        ? 'Annual'
                        : 'PM',
                    baseColor: AppColors.main,
                    textColor: AppColors.yellow,
                    progressColor: AppColors.yellow,
                    holdDuration: const Duration(seconds: 2),
                    onConfirmed: _submitPm,
                    ),
                ),

                const SizedBox(width: 8),

                Expanded(
                    child: ElevatedButton(
                    onPressed: () {
                        widget.ui.selectRecord(RecordMode.repair);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.ui.selectedRecord == RecordMode.repair
                                ? AppColors.yellow
                                : AppColors.main,
                        foregroundColor:
                            widget.ui.selectedRecord == RecordMode.repair
                                ? AppColors.main
                                : AppColors.yellow,
                    ),
                    child: const Text('Repair'),
                    ),
                ),

                const SizedBox(width: 8),

                Expanded(
                    child: ElevatedButton(
                    onPressed: () {
                        widget.ui.selectRecord(RecordMode.issue);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.ui.selectedRecord == RecordMode.issue
                                ? AppColors.yellow
                                : AppColors.main,
                        foregroundColor:
                            widget.ui.selectedRecord == RecordMode.issue
                                ? AppColors.main
                                : AppColors.yellow,
                    ),
                    child: const Text('Issue'),
                    ),
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