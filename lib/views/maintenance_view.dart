import 'package:flutter/material.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_snapshot.dart';
import '../models/lift_pm_history_item.dart';
import '../models/lift_maintenance_history_item.dart';
import '../models/lift_rental_history_item.dart';
import '../models/yard_shortage_warning.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/lift_selector_panel.dart';
import '../widgets/maintenance/selected_lift_workspace.dart';
import '../widgets/maintenance/yard_list_button.dart';
import '../widgets/maintenance/unresolved_actions_panel.dart';
import 'maintenance_ui_state.dart';
import '../widgets/maintenance/timeline/timeline_builder.dart';
import '../widgets/maintenance/maintenance_timeline.dart';
import '../widgets/maintenance/history_timeline_loader.dart';

class MaintenanceView extends StatefulWidget {
  final String currentUserId;

  const MaintenanceView({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView> {
  late Future<List<Lift>> _futureLifts;
  late Future<List<YardShortageWarning>> _futureYardWarnings;

  final MaintenanceUiState ui = MaintenanceUiState();

  Lift? _selectedLift;
  Future<LiftMaintenanceSnapshot>? _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _futureLifts = ApiService().fetchLifts();
    _futureYardWarnings = ApiService().fetchYardShortageWarnings();
  }

  @override
  void dispose() {
    ui.dispose();
    super.dispose();
  }

  void _selectLift(Lift lift) {
    setState(() {
      _selectedLift = lift;
      ui.resetForNewLift();
      _snapshotFuture = ApiService().fetchLiftMaintenanceSnapshot(lift.liftId);
    });
  }

  void _onSerialChanged(String serial) {
    if (serial.isEmpty && _selectedLift != null) {
      setState(() {
        _selectedLift = null;
        _snapshotFuture = null;
        ui.resetForNewLift();
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_selectedLift == null) return;
    final freshFuture =
        ApiService().fetchLiftMaintenanceSnapshot(_selectedLift!.liftId);
    setState(() {
      _snapshotFuture = freshFuture;
    });
    await freshFuture;
  }

  @override
  Widget build(BuildContext context) {
    print("Maintenance page build");
    return FutureBuilder<List<Lift>>(
      future: _futureLifts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.yellow,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(
                color: AppColors.red,
              ),
            ),
          );
        }

        final lifts = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final maxWidth = isTablet ? 900.0 : 420.0;

            if (_selectedLift == null) {
              // Initial state: selector (plus any shortage warnings) is
              // centered in the available height; yard list stays pinned
              // to the very bottom of the page.
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.mainBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LiftSelectorPanel(
                                      lifts: lifts,
                                      initialText: '',
                                      onChanged: _onSerialChanged,
                                      onLiftSelected: _selectLift,
                                    ),
                                    FutureBuilder<List<YardShortageWarning>>(
                                      future: _futureYardWarnings,
                                      builder: (context, snapshot) {
                                        final warnings = snapshot.data ?? [];
                                        if (warnings.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: Column(
                                            children: [
                                              for (final w in warnings)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 2),
                                                  child: Text(
                                                    '${w.liftType}: ${w.upcomingCount} upcoming, '
                                                    '${w.upToDateYardCount} up to date in yard',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: AppColors.red,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            YardListButton(
                              onLiftSelected: _selectLift,
                              currentUserId: widget.currentUserId,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Card(
                  color: AppColors.mainBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RefreshIndicator(
                      color: AppColors.main,
                      backgroundColor: AppColors.yellow,
                      onRefresh: _handleRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LiftSelectorPanel(
                              lifts: lifts,
                              initialText: _selectedLift?.serialNumber ?? '',
                              onChanged: _onSerialChanged,
                              onLiftSelected: _selectLift,
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<LiftMaintenanceSnapshot>(
                              future: _snapshotFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.yellow,
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return const Text(
                                    "Failed loading snapshot",
                                    style: TextStyle(
                                      color: AppColors.red,
                                    ),
                                  );
                                }

                                final data = snapshot.data!;

                                return SelectedLiftWorkspace(
                                  lift: _selectedLift!,
                                  snapshot: data,
                                  ui: ui,
                                  currentUserId: widget.currentUserId,
                                  onRefresh: () {
                                    setState(() {
                                      _snapshotFuture = ApiService()
                                          .fetchLiftMaintenanceSnapshot(
                                              _selectedLift!.liftId);
                                    });
                                  },
                                  unresolvedActions: UnresolvedActionsPanel(
                                    snapshot: data,
                                    currentUserId: widget.currentUserId,
                                    onChanged: () {
                                      setState(() {
                                        _snapshotFuture = ApiService()
                                            .fetchLiftMaintenanceSnapshot(
                                          _selectedLift!.liftId,
                                        );
                                      });
                                    },
                                  ),
                                  history: HistoryTimelineLoader(
                                    liftId: _selectedLift!.liftId,
                                    ui: ui,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
