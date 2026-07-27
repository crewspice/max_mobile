import 'package:flutter/material.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_snapshot.dart';
import '../models/lift_pm_history_item.dart';
import '../models/lift_maintenance_history_item.dart';
import '../models/lift_rental_history_item.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/lift_selector_panel.dart';
import '../widgets/maintenance/selected_lift_workspace.dart';
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

  final MaintenanceUiState ui = MaintenanceUiState();

  Lift? _selectedLift;
  Future<LiftMaintenanceSnapshot>? _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _futureLifts = ApiService().fetchLifts();
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
      _snapshotFuture =
          ApiService().fetchLiftMaintenanceSnapshot(lift.liftId);
    });
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

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 900 : 420,
                ),
                child: Card(
                  color: AppColors.mainBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // const Center(
                          //   child: Text(
                          //     "Maintenance Snapshot",
                          //     style: TextStyle(
                          //       color: AppColors.yellow,
                          //       fontSize: 18,
                          //       fontWeight: FontWeight.bold,
                          //     ),
                          //   ),
                          // ),

                          // const SizedBox(height: 16),

                          LiftSelectorPanel(
                            lifts: lifts,
                            initialText: _selectedLift?.serialNumber ?? '',
                            onChanged: (_) {},
                            onLiftSelected: _selectLift,
                          ),

                          if (_selectedLift != null) ...[
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
                                        _snapshotFuture =
                                            ApiService().fetchLiftMaintenanceSnapshot(_selectedLift!.liftId);
                                        });
                                    },
                                    unresolvedActions: UnresolvedActionsPanel(
                                        snapshot: data,
                                        currentUserId: widget.currentUserId,
                                        onChanged: () {
                                            setState(() {
                                                _snapshotFuture =
                                                    ApiService().fetchLiftMaintenanceSnapshot(
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
                        ],
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