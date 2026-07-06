import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_snapshot.dart';
import '../models/lift_pm_history_item.dart';
import '../models/lift_maintenance_history_item.dart';
import '../services/api_service.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../theme/app_colors.dart';

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

  Lift? _selectedLift;
  Future<LiftMaintenanceSnapshot>? _snapshotFuture;

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _showIssueForm = false;
  bool _showPmHistory = false;
  bool _showIssueHistory = false;
  final Map<int, bool> _noRepairNeededByAction = {};
  final Map<int, bool> _repairNotesExpanded = {};
  final Map<int, TextEditingController> _repairNotesControllers = {};
  late Future<List<LiftPmHistoryItem>> _pmHistoryFuture;
  late Future<List<LiftMaintenanceHistoryItem>> _issueHistoryFuture;
  int? _expandedHistoryIndex;
  String? _lastAutoSelectedSerial;

  @override
  void initState() {
    super.initState();
    _futureLifts = ApiService().fetchLifts();
  }

  @override
  void dispose() {
    _serialController.dispose();
    _notesController.dispose();
    for (final controller in _repairNotesControllers.values) {
    controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Lift>>(
      future: _futureLifts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final lifts = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 900 : 420, // 👈 KEY CHANGE
                ),
                child: Card(
                  color: AppColors.mainBackground,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedLift != null) ...[
                            const Center(
                              child: Text(
                                'Maintenance Snapshot',
                                style: TextStyle(
                                  color: AppColors.yellow,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSelectedLiftView(lifts),
                          ] else
                            Autocomplete<Lift>(
                              displayStringForOption: (l) => l.serialNumber ?? '',
                              optionsBuilder: (textEditingValue) {
                                final query = textEditingValue.text.toLowerCase();
                                if (query.isEmpty) {
                                  return const Iterable<Lift>.empty();
                                }
                                return lifts.where((l) =>
                                    (l.serialNumber ?? '')
                                        .toLowerCase()
                                        .contains(query));
                              },
                              onSelected: _selectLift,
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  textInputAction: TextInputAction.done,
                                    onChanged: (value) {
                                      final serial = value.trim().toLowerCase();

                                      print('Typed: "$serial"');

                                      final match = lifts.cast<Lift?>().firstWhere(
                                        (l) => (l?.serialNumber ?? '').trim().toLowerCase() == serial,
                                        orElse: () => null,
                                      );

                                      print('Match found: ${match?.serialNumber}');

                                      if (match != null &&
                                          (_selectedLift == null ||
                                              _selectedLift!.liftId != match.liftId)) {
                                        _selectLift(match);
                                      }
                                    },
                                  cursorColor: AppColors.yellow,

                                  style: const TextStyle(
                                    color: AppColors.yellow, // typed text
                                  ),

                                  decoration: InputDecoration(
                                    labelText: 'Lift serial number',
                                    labelStyle: const TextStyle(
                                      color: AppColors.yellow,
                                    ),

                                    hintStyle: TextStyle(
                                      color: AppColors.yellow.withOpacity(0.5),
                                    ),

                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.yellow.withOpacity(0.6),
                                      ),
                                    ),

                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.yellow,
                                        width: 2,
                                      ),
                                    ),

                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.yellow.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    color: AppColors.main, // background of dropdown
                                    elevation: 6,
                                    child: SizedBox(
                                      height: 220,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);

                                          return ListTile(
                                            tileColor: Colors.transparent,

                                            title: Text(
                                              option.serialNumber ?? 'No serial',
                                              style: const TextStyle(
                                                color: AppColors.yellow,
                                              ),
                                            ),

                                            subtitle: Text(
                                              option.model ?? '',
                                              style: TextStyle(
                                                color: AppColors.yellow.withOpacity(0.6),
                                              ),
                                            ),

                                            hoverColor: AppColors.yellow.withOpacity(0.1),
                                            splashColor: AppColors.yellow.withOpacity(0.2),

                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedLiftView(List<Lift> lifts) {
    if (_selectedLift == null || _snapshotFuture == null) return const SizedBox.shrink();

    return FutureBuilder<LiftMaintenanceSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Failed to load snapshot',
            style: TextStyle(color: AppColors.red),
          );
        }

        final data = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------
            // Top row: Autocomplete field + Record buttons
            // ----------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ----------------------------
                // Full-width Autocomplete
                // ----------------------------
                Autocomplete<Lift>(
                  displayStringForOption: (l) => l.serialNumber ?? '',
                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.toLowerCase();
                    if (query.isEmpty) return const Iterable<Lift>.empty();
                    return lifts.where((l) =>
                        (l.serialNumber ?? '').toLowerCase().contains(query));
                  },
                  onSelected: (lift) {
                    setState(() {
                      _selectedLift = lift;
                      _resetToggles();
                      _snapshotFuture =
                          ApiService().fetchLiftMaintenanceSnapshot(lift.liftId);
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.text = _selectedLift!.serialNumber ?? '';
                    return TextField(
                      style: const TextStyle(color: AppColors.yellow),
                      cursorColor: AppColors.yellow,
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        final serial = value.trim().toLowerCase();

                        final match = lifts.cast<Lift?>().firstWhere(
                          (l) => (l?.serialNumber ?? '').toLowerCase() == serial,
                          orElse: () => null,
                        );

                        if (match != null) {
                          FocusScope.of(context).unfocus();
                          _selectLift(match);
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.yellow),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.yellow),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.yellow, width: 2),
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Material(
                      elevation: 4,
                      color: AppColors.mainBackground,
                      child: SizedBox(
                        height: 220,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);

                            return ListTile(
                              title: Text(
                                option.serialNumber ?? 'No serial',
                                style: const TextStyle(color: AppColors.yellow),
                              ),
                              subtitle: Text(
                                option.model ?? '',
                                style: const TextStyle(color: AppColors.yellow),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ----------------------------
                // Buttons row
                // ----------------------------
                Row(
                  children: [
                    Expanded(
                      child: HoldToConfirmButton(
                        icon: const Icon(Icons.check),
                        label: 'Record PM',
                        baseColor: AppColors.main,
                        textColor: AppColors.yellow,
                        progressColor: AppColors.yellow,
                        onConfirmed: () async {
                          await _submitPm();
                          setState(() {
                            _showIssueForm = false;
                          });
                        },
                        holdDuration: const Duration(seconds: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Record Issue'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: _showIssueForm ? AppColors.main : AppColors.yellow,
                          backgroundColor:
                              _showIssueForm ? AppColors.yellow : AppColors.main,
                        ),
                        onPressed: () {
                          setState(() {
                            _showIssueForm = !_showIssueForm;
                            if (_showIssueForm) {
                              _showPmHistory = false;
                              _showIssueHistory = false;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ----------------------------
            // Status cards
            // ----------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Single-line status card ---
                _buildStatusCard(
                  title: data.upToDate == true ? 'Up to date' : 'Needs PM',
                  isGood: data.upToDate == true,
                  extraInfo: data.pmId != null
                      ? 'last: ${data.pmCompletedByNickname ?? 'Unknown'} on '
                        '${data.pmCompletedAt != null ? _formatDate(data.pmCompletedAt!) : 'Unknown'}'
                      : null,
                ),
                const SizedBox(height: 8),

                if (data.maintenanceActions.isNotEmpty)
                  ...data.maintenanceActions.map((action) {
                    final repairNotesController =
                        _repairNotesControllers.putIfAbsent(
                      action.actionId!,
                      () => TextEditingController(),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildRepairCard(
                        title: '${_formatDate(action.createdAt!)}',
                        isGood: false,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((action.notes ?? '').isNotEmpty)
                              Center(
                                child: Text(
                                  '"${action.notes}"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            if ((action.reportedBy ?? '').isNotEmpty)
                              Center(
                                child: Text(
                                  (action.notes ?? '').isNotEmpty
                                      ? '- ${action.reportedBy}'
                                      : 'Reported by: ${action.reportedBy}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.red,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 6),

                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              initiallyExpanded:
                                  _repairNotesExpanded[action.actionId] ?? false,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _repairNotesExpanded[action.actionId!] = expanded;
                                });
                              },
                              title: const Text(
                                'Add repair notes',
                                style: TextStyle(
                                  color: AppColors.red,
                                  fontSize: 13,
                                ),
                              ),
                              children: [
                                TextField(
                                  controller: repairNotesController,
                                  maxLines: 3,
                                  cursorColor: AppColors.red,
                                  style: const TextStyle(
                                    color: AppColors.red,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Optional repair notes...',
                                    hintStyle: TextStyle(
                                      color: AppColors.red,
                                    ),
                                    enabledBorder: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'No Repair Needed',
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 13,
                                  ),
                                ),

                                Checkbox(
                                  value:
                                      _noRepairNeededByAction[action.actionId] ?? false,
                                  activeColor: AppColors.red,
                                  checkColor: AppColors.mainBackground,
                                  onChanged: (value) {
                                    setState(() {
                                      _noRepairNeededByAction[action.actionId!] =
                                          value ?? false;
                                    });
                                  },
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: HoldToConfirmButton(
                                    icon: const Icon(Icons.check),
                                    label: 'Resolve',
                                    baseColor: AppColors.main,
                                    textColor: AppColors.red,
                                    progressColor: AppColors.red,
                                    holdDuration: const Duration(seconds: 2),
                                    onConfirmed: () async {
                                      await ApiService().resolveMaintenanceAction(
                                        actionId: action.actionId!,
                                        resolvedByInitial: widget.currentUserId,
                                        noRepairNeeded:
                                            _noRepairNeededByAction[action.actionId] ?? false,
                                        repairNotes: repairNotesController.text.trim(),
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        _noRepairNeededByAction.remove(action.actionId);
                                        _repairNotesExpanded.remove(action.actionId);
                                        _repairNotesControllers
                                            .remove(action.actionId)
                                            ?.dispose();

                                        _snapshotFuture = ApiService()
                                            .fetchLiftMaintenanceSnapshot(
                                                _selectedLift!.liftId);

                                        _issueHistoryFuture = ApiService()
                                            .fetchMaintenanceHistory(
                                                _selectedLift!.liftId);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: _showPmHistory ? AppColors.main : AppColors.yellow,
                    backgroundColor: _showPmHistory ? AppColors.yellow : AppColors.main,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPmHistory = !_showPmHistory;
                      if (_showPmHistory) {
                        _showIssueHistory = false;
                        _showIssueForm = false;
                        _pmHistoryFuture = 
                            ApiService().fetchPmHistory(_selectedLift!.liftId);
                      }
                    });
                  },
                  child: const Text('PM History'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: _showIssueHistory ? AppColors.main : AppColors.yellow,
                    backgroundColor: _showIssueHistory ? AppColors.yellow : AppColors.main,
                  ),
                  onPressed: () {
                    setState(() {
                      _showIssueHistory = !_showIssueHistory;

                      if (_showIssueHistory) {
                        _showPmHistory = false; // 👈 match logic
                        _showIssueForm = false;
                        _issueHistoryFuture =
                            ApiService().fetchMaintenanceHistory(_selectedLift!.liftId);
                      }
                    });
                  },
                  child: const Text('Issue History'),
                ),
              ],
            ),
            // ----------------------------
            // PM history display
            // ----------------------------
            if (_showPmHistory)
              FutureBuilder<List<LiftPmHistoryItem>>(
                future: _pmHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  final data = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 👈 2 tiles per row (adjust as needed)
                      childAspectRatio: 2.0, // 👈 controls tile shape
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final pm = data[index];
                      return Card(
                        color: AppColors.yellow, // 👈 dark purple
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pm.completedByNickname ?? pm.completedByName ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainBackground, // 👈 white text
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pm.completedAt != null
                                    ? '${pm.completedAt!.year.toString().padLeft(4, '0')}-'
                                      '${pm.completedAt!.month.toString().padLeft(2, '0')}-'
                                      '${pm.completedAt!.day.toString().padLeft(2, '0')}'
                                    : '',
                                style: const TextStyle(color: AppColors.mainBackground),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // ----------------------------
              // Issue / maintenance history display
              // ----------------------------
              if (_showIssueHistory)
                FutureBuilder<List<LiftMaintenanceHistoryItem>>(
                  future: _issueHistoryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    final data = snapshot.data!;

                    return StaggeredGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(data.length, (index) {
                        final issue = data[index];

                        final expanded = _expandedHistoryIndex == index;

                        return StaggeredGridTile.count(
                          crossAxisCellCount: expanded ? 2 : 1,
                          mainAxisCellCount: expanded ? 3 : 1,
                          child: GestureDetector(
                            onLongPress: () {
                              setState(() {
                                _expandedHistoryIndex =
                                    expanded ? null : index;
                              });
                            },
                            onTap: () {
                              if (expanded) {
                                setState(() {
                                  _expandedHistoryIndex = null;
                                });
                              }
                            },
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: Card(
                                color: AppColors.yellow,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Builder(
                                    builder: (context) {
                                      final performer =
                                          issue.performedByNickname ??
                                          issue.performedByName ??
                                          issue.performedByInitials;

                                      final cleanedNotes =
                                          (issue.actionTypeId == 60 &&
                                                  issue.notes != null)
                                              ? cleanBatteryNotes(issue.notes!)
                                              : null;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [

                                          // ---------- Title ----------
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  issue.actionTypeName ??
                                                      (issue.notes != null &&
                                                              issue.notes!.isNotEmpty
                                                          ? issue.notes!
                                                          : 'Unknown'),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.mainBackground,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),

                                              if (issue.quantity != null &&
                                                  issue.quantity! > 0 &&
                                                  issue.quantity! < 100)
                                                Text(
                                                  'x${issue.quantity}',
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .mainBackground,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),

                                          // ---------- Performer ----------
                                          if (performer != null &&
                                              performer.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'By: $performer',
                                              style: const TextStyle(
                                                color:
                                                    AppColors.mainBackground,
                                              ),
                                            ),
                                          ],

                                          // ---------- Part Action ----------
                                          if (issue.partAction != null &&
                                              issue.partAction!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              issue.partAction == 'Repair'
                                                  ? 'Repaired'
                                                  : issue.partAction ==
                                                          'Replace'
                                                      ? 'Replaced'
                                                      : issue.partAction!,
                                              style: const TextStyle(
                                                fontStyle:
                                                    FontStyle.italic,
                                                color:
                                                    AppColors.mainBackground,
                                              ),
                                            ),
                                          ],

                                          // ---------- Date ----------
                                          if (issue.performedAt != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${issue.performedAt!.month.toString().padLeft(2, '0')}-'
                                              '${issue.performedAt!.day.toString().padLeft(2, '0')}-'
                                              '${issue.performedAt!.year.toString().padLeft(4, '0')}',
                                              style: const TextStyle(
                                                color:
                                                    AppColors.mainBackground,
                                              ),
                                            ),
                                          ],

                                          // ---------- Expanded info ----------
                                          if (expanded) ...[
                                            const Divider(),

                                            if (issue.notes != null &&
                                                issue.notes!.isNotEmpty)
                                              Text(
                                                issue.actionTypeId == 60
                                                    ? (cleanedNotes ??
                                                        issue.notes!)
                                                    : issue.notes!,
                                                style: const TextStyle(
                                                  color: AppColors
                                                      .mainBackground,
                                                ),
                                              ),

                                            const Spacer(),

                                            Text(
                                              'Long press again or tap to collapse',
                                              style: TextStyle(
                                                color: AppColors
                                                    .mainBackground
                                                    .withOpacity(.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ]

                                          // ---------- Compact notes ----------
                                          else if (issue.notes != null &&
                                              issue.notes!.isNotEmpty) ...[
                                            if (issue.actionTypeId == 1) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '"${issue.notes}"',
                                                style: const TextStyle(
                                                  color: AppColors.yellow,
                                                ),
                                              ),
                                            ] else if (issue.actionTypeId ==
                                                    60 &&
                                                cleanedNotes != null &&
                                                cleanedNotes.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                cleanedNotes,
                                                style: const TextStyle(
                                                  color: AppColors.yellow,
                                                ),
                                              ),
                                            ]
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),

            // ----------------------------
            // PM form
            // ----------------------------
            if (_showIssueForm) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.yellow),
                cursorColor: AppColors.yellow,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(color: AppColors.yellow),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.yellow),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.yellow),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.yellow, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: HoldToConfirmButton(
                  icon: const Icon(Icons.check),
                  baseColor: AppColors.main,
                  textColor: AppColors.yellow,
                  progressColor: AppColors.yellow,
                  label: 'Submit',
                  onConfirmed: () async {
                    setState(() {
                      _showIssueForm = false;
                    });
                    await _submitIssue();
                  },
                  holdDuration: const Duration(seconds: 1),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusCard({
    required String title,
    required bool isGood,
    String? extraInfo,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isGood ? AppColors.green : AppColors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top row (icon + title)
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.warning,
                color: isGood ? AppColors.green : AppColors.red,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGood ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),

          // 🔹 Extra info BELOW (wraps naturally)
          if (extraInfo != null) ...[
            const SizedBox(height: 6),
            Text(
              extraInfo,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: isGood ? AppColors.green : AppColors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepairCard({
    required String title,
    required bool isGood,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: isGood ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isGood ? AppColors.green : AppColors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.warning,
                color: isGood ? AppColors.green : AppColors.red,
              ),

              const Spacer(),

              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGood ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Future<void> _submitPm() async {
    if (_selectedLift == null) return;

    try {
      await ApiService().submitPreventiveMaintenance(
        liftId: _selectedLift!.liftId,
        completedByInitial: widget.currentUserId,
      );

      if (!mounted) return;

      _notesController.clear();
      _serialController.clear();

      setState(() {
        _snapshotFuture = 
          ApiService().fetchLiftMaintenanceSnapshot(_selectedLift!.liftId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            'Preventative maintenance recorded',
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
            'Failed to submit PM: $e',
            style: const TextStyle(
              color: AppColors.red,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _submitIssue() async {
    if (_selectedLift == null) return;

    try {
      await ApiService().submitMaintenanceIssue(
        liftId: _selectedLift!.liftId,
        notes: _notesController.text,
        createdByInitial: widget.currentUserId,
      );

      if (!mounted) return;

      _notesController.clear();
      _serialController.clear();

      setState(() {
        _snapshotFuture = ApiService().fetchLiftMaintenanceSnapshot(_selectedLift!.liftId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            'Issue recorded successfully',
            style: TextStyle(color: AppColors.green),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mainBackground,
          content: Text(
            'Failed to submit issue: $e',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
      );
    }
  }

  void _selectLift(Lift lift) {
    setState(() {
      _selectedLift = lift;
      _resetToggles();
      _snapshotFuture =
          ApiService().fetchLiftMaintenanceSnapshot(lift.liftId);
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final suffix = _daySuffix(day);
    return '${_monthAbbr(date.month)} $day$suffix, \'${date.year.toString().substring(2)}';  }

  // Helper for month abbreviation
  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Returns the ordinal suffix for a day
  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String cleanBatteryNotes(String notes) {
    final cleaned = notes
        .replaceAll(RegExp(r'\b(rc|battery|batteries)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d+\b'), '') // remove standalone numbers
        .replaceAll(RegExp(r'\s+'), ' ') // clean extra spaces
        .trim();

    return cleaned.isNotEmpty ? 'Type: $cleaned' : '';
  }

  void _resetToggles() {
    _showIssueForm = false;
    _showPmHistory = false;
    _showIssueHistory = false;
    _pmHistoryFuture = Future.value([]);
    _issueHistoryFuture = Future.value([]);
  }
  
}


