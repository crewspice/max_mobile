import 'package:flutter/material.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_history.dart';
import '../services/api_service.dart';

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
  Future<LiftMaintenanceHistory>? _historyFuture;

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preventative Maintenance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ----------------------------
                      // Serial number autocomplete
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
                            _historyFuture =
                                ApiService().fetchLiftMaintenanceHistory(lift.liftId);
                          });
                        },

                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {

                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.done,

                            // ✅ THIS is the only new part
                            onSubmitted: (_) {
                              final text = controller.text.toLowerCase();

                              final matches = lifts.where((l) =>
                                  (l.serialNumber ?? '').toLowerCase().contains(text));

                              if (matches.isNotEmpty) {
                                final lift = matches.first;

                                setState(() {
                                  _selectedLift = lift;
                                  _historyFuture =
                                    ApiService().fetchLiftMaintenanceHistory(lift.liftId);
                                });
                              }
                            },

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


                      const SizedBox(height: 16),

                      if (_selectedLift != null) ...[
                        _buildSelectedLiftInfo(),

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
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Submit PM Check'),
                            onPressed: _submitPm,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildPmHistory(),
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
  }

  Widget _buildSelectedLiftInfo() {
    final lift = _selectedLift!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected lift',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${lift.serialNumber ?? 'No serial'}'
          '${lift.model != null ? ' • ${lift.model}' : ''}',
        ),
      ],
    );
  }

  Widget _buildPmHistory() {
    if (_historyFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<LiftMaintenanceHistory>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Failed to load history',
            style: TextStyle(color: Colors.red),
          );
        }

        final history = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest PM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            if (history.pmId == null)
              const Text('No PM recorded yet')
            else ...[
              Text('By: ${history.completedByUserName ?? 'Unknown'}'),
              if (history.completedAt != null)
                Text('Date: ${history.completedAt!.toLocal()}'),
              if ((history.notes ?? '').isNotEmpty)
                Text('Notes: ${history.notes}'),
            ],

            const SizedBox(height: 16),

            const Text(
              'Service since last PM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            if (history.serviceId == null)
              const Text('No service activity since last PM')
            else ...[
              Text('Type: ${history.serviceType ?? ''}'),
              Text('Status: ${history.serviceStatus ?? ''}'),
              if (history.serviceDate != null)
                Text('Date: ${history.serviceDate!.toLocal()}'),
              if ((history.reason ?? '').isNotEmpty)
                Text('Reason: ${history.reason}'),
            ],
          ],
        );
      },
    );
  }


  Future<void> _submitPm() async {
    if (_selectedLift == null) return;

    try {
      await ApiService().submitPreventiveMaintenance(
        liftId: _selectedLift!.liftId,
        notes: _notesController.text,
        completedByInitial: widget.currentUserId,
      );

      if (!mounted) return;

      _notesController.clear();
      _serialController.clear();

      setState(() {
        _historyFuture = 
          ApiService().fetchLiftMaintenanceHistory(_selectedLift!.liftId);
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
}
