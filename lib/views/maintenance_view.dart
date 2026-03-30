import 'package:flutter/material.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_snapshot.dart';
import '../models/lift_pm_history_item.dart';
import '../models/lift_maintenance_history_item.dart';
import '../services/api_service.dart';
import '../widgets/hold_to_confirm_button.dart';

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
  late Future<List<LiftPmHistoryItem>> _pmHistoryFuture;
  late Future<List<LiftMaintenanceHistoryItem>> _issueHistoryFuture;

  @override
  void initState() {
    super.initState();
    _futureLifts = ApiService().fetchLifts();
  }

  @override
  void dispose() {
    _serialController.dispose();
    _notesController.dispose();
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

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.purple[50],
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSelectedLiftView(lifts),
                      ] else
                        // Show the autocomplete for initial selection
                        Autocomplete<Lift>(
                          displayStringForOption: (l) => l.serialNumber ?? '',
                          optionsBuilder: (textEditingValue) {
                            final query = textEditingValue.text.toLowerCase();
                            if (query.isEmpty) return const Iterable<Lift>.empty();
                            return lifts.where((l) => (l.serialNumber ?? '')
                                .toLowerCase()
                                .contains(query));
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
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Lift serial number',
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                child: SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.serialNumber ?? 'No serial'),
                                        subtitle: Text(option.model ?? ''),
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
            style: TextStyle(color: Colors.red),
          );
        }

        final data = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------
            // Top row: Autocomplete field + Record buttons
            // ----------------------------
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Autocomplete<Lift>(
                    displayStringForOption: (l) => l.serialNumber ?? '',
                    optionsBuilder: (textEditingValue) {
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) return const Iterable<Lift>.empty();
                      return lifts.where((l) => (l.serialNumber ?? '')
                          .toLowerCase()
                          .contains(query));
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
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          final text = controller.text.toLowerCase();
                          final matches = lifts.where((l) =>
                              (l.serialNumber ?? '').toLowerCase().contains(text));
                          if (matches.isNotEmpty) {
                            final lift = matches.first;
                            setState(() {
                              _selectedLift = lift;
                              _resetToggles();
                              _snapshotFuture =
                                  ApiService().fetchLiftMaintenanceSnapshot(lift.liftId);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Material(
                        elevation: 4,
                        child: SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.serialNumber ?? 'No serial'),
                                subtitle: Text(option.model ?? ''),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: HoldToConfirmButton(
                    icon: const Icon(Icons.check),
                    label: 'Record PM',
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
                  flex: 2, // 👈 HERE
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.report_problem),
                    label: const Text('Record Issue'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: _showIssueForm ? Colors.white : null,
                      backgroundColor:
                          _showIssueForm ? const Color(0xFF3B2F5C) : null,
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

                // --- Multi-line repair card ---
                if (data.actionId != null)
                  _buildRepairCard(
                    title: 'Needs Repair',
                    isGood: false,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${data.actionTypeName ?? ''}'),
                        if (data.actionCreatedAt != null)
                          Text(
                            'Date: ${data.actionCreatedAt!.year.toString().padLeft(4, '0')}-'
                            '${data.actionCreatedAt!.month.toString().padLeft(2, '0')}-'
                            '${data.actionCreatedAt!.day.toString().padLeft(2, '0')}',
                          ),
                        if ((data.actionReportedBy ?? '').isNotEmpty)
                          Text('Reported by: ${data.actionReportedBy}'),
                        if ((data.actionNotes ?? '').isNotEmpty)
                          Text('Notes: ${data.actionNotes}'),
                        const SizedBox(height: 6),
                        HoldToConfirmButton(
                          icon: const Icon(Icons.check),
                          label: 'Resolve',
                          holdDuration: const Duration(seconds: 2),
                          onConfirmed: () async {
                            if (_selectedLift == null || data.actionId == null) return;

                            try {
                              await ApiService().resolveMaintenanceAction(
                                actionId: data.actionId!,
                                resolvedByInitial: widget.currentUserId,
                              );

                              if (!mounted) return;

                              // Refresh the snapshot and history
                              setState(() {
                                _snapshotFuture =
                                    ApiService().fetchLiftMaintenanceSnapshot(_selectedLift!.liftId);
                                _issueHistoryFuture =
                                    ApiService().fetchMaintenanceHistory(_selectedLift!.liftId);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Issue resolved successfully')),
                              );
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to resolve issue: $e')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: _showPmHistory ? Colors.white : null,
                    backgroundColor: _showPmHistory ? const Color(0xFF3B2F5C) : null,
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
                    foregroundColor: _showIssueHistory ? Colors.white : null,
                    backgroundColor: _showIssueHistory ? const Color(0xFF3B2F5C) : null,
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
                    return Text('Error: ${snapshot.error}');
                  }
                  final data = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 👈 2 tiles per row (adjust as needed)
                      childAspectRatio: 2.5, // 👈 controls tile shape
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final pm = data[index];
                      return Card(
                        color: const Color(0xFF3B2F5C), // 👈 dark purple
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pm.completedByNickname ?? pm.completedByName ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // 👈 white text
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pm.completedAt != null
                                    ? '${pm.completedAt!.year.toString().padLeft(4, '0')}-'
                                      '${pm.completedAt!.month.toString().padLeft(2, '0')}-'
                                      '${pm.completedAt!.day.toString().padLeft(2, '0')}'
                                    : '',
                                style: const TextStyle(color: Colors.white),
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
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final issue = data[index];
                      return Card(
                        color: const Color(0xFF3B2F5C),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Builder(
                            builder: (context) {
                              final performer = issue.performedByNickname ??
                                                issue.performedByName ??
                                                issue.performedByInitials;
                              final cleanedNotes = (issue.actionTypeId == 60 && issue.notes != null)
                                  ? cleanBatteryNotes(issue.notes!)
                                  : null; 
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // --- Title ---
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          issue.actionTypeName ??
                                              (issue.notes != null && issue.notes!.isNotEmpty
                                                  ? issue.notes!
                                                  : 'Unknown'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis, // prevents overflow issues
                                        ),
                                      ),

                                      if (issue.quantity != null && issue.quantity! > 0 && issue.quantity! < 100)
                                        Text(
                                          'x${issue.quantity}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),

                                  // --- Performer ---
                                  if (performer != null && performer.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'By: $performer',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],

                                  if (issue.partAction != null && issue.partAction!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      issue.partAction == 'Repair'
                                          ? 'Repaired'
                                          : issue.partAction == 'Replace'
                                              ? 'Replaced'
                                              : issue.partAction!, // fallback for anything else
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],

                                  // --- Date ---
                                  if (issue.performedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${issue.performedAt!.month.toString().padLeft(2, '0')}-'
                                      '${issue.performedAt!.day.toString().padLeft(2, '0')}-'
                                      '${issue.performedAt!.year.toString().padLeft(4, '0')}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],

                                  // --- Notes ---
                                  if (issue.notes != null && issue.notes!.isNotEmpty) ...[
                                    if (issue.actionTypeId == 1) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '"${issue.notes}"',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ] else if (issue.actionTypeId == 60 &&
                                        cleanedNotes != null &&
                                        cleanedNotes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        cleanedNotes,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ]
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
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
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: HoldToConfirmButton(
                  icon: const Icon(Icons.check),
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
        // color: isGood ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isGood ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGood ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          if (extraInfo != null)
            Expanded(
              child: Text(
                extraInfo,
                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
        border: Border.all(color: isGood ? Colors.green : Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.warning,
                color: isGood ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGood ? Colors.green : Colors.red,
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
        const SnackBar(
          content: Text('Preventative maintenance recorded'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit PM: $e'),
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
          content: Text('Issue recorded successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit issue: $e'),
        ),
      );
    }
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


