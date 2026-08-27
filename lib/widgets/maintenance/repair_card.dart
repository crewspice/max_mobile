import 'package:flutter/material.dart';
import '../../models/lift_maintenance_history_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../curved_stack_card.dart';
import '../hold_to_confirm_button.dart';
import '../user_avatar.dart';
import 'maintenance_dialogs.dart';
import '../../config/device_config.dart';

class RepairCard extends StatefulWidget {
  final LiftMaintenanceHistoryItem action;
  final String currentUserId;
  final VoidCallback onResolved;
  final StackPosition position;

  const RepairCard({
    super.key,
    required this.action,
    required this.currentUserId,
    required this.onResolved,
    this.position = StackPosition.only,
  });

  @override
  State<RepairCard> createState() => _RepairCardState();
}

class _RepairCardState extends State<RepairCard> {
  bool _noRepairNeeded = false;
  String? _repairNotes;

  @override
  void initState() {
    super.initState();
    _repairNotes = widget.action.repairNotes;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CurvedStackCard(
        color: AppColors.red,
        position: widget.position,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: AppColors.yellow,
                ),

                const SizedBox(width: 6),

                Text(
                  widget.action.actionTypeName ?? 'Needs Repair',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Text(
                  _formatDate(widget.action.createdAt),
                  style: const TextStyle(
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if ((widget.action.notes ?? '').isNotEmpty)
              Center(
                child: Text(
                  '"${widget.action.notes}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            if ((widget.action.reportedBy ?? '').isNotEmpty)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.action.reportedByInitials != null) ...[
                      UserAvatar(
                        initials: widget.action.reportedByInitials,
                        radius: 10,
                        color: AppColors.yellow,
                        textColor: AppColors.main,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.action.notes != null &&
                              widget.action.notes!.isNotEmpty
                          ? '- ${widget.action.reportedBy}'
                          : 'Reported by: ${widget.action.reportedBy}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Expanded(
                        child: Center(
                        child: Text(
                          (_repairNotes ?? '').isNotEmpty
                              ? _repairNotes!
                              : 'No repair notes',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                            color: AppColors.yellow,
                            fontStyle: FontStyle.italic,
                            ),
                        ),
                        ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                        onTap: () async {
                            final notes = await showRepairNotesDialog(
                            context,
                            initialValue: widget.action.repairNotes ?? '',
                            );

                            if (notes == null) return;

                            await ApiService().updateMaintenanceRepairNotes(
                              widget.action.actionId!,
                              notes,
                            );

                            if (!mounted) return;

                            setState(() {
                              _repairNotes = notes;
                            });
                        },
                        child: Image.asset(
                            'assets/notes.png',
                            width: 20,
                            height: 20,
                            color: AppColors.yellow,
                        ),
                        ),
                    ),
                    ],
                ),
            ),
            DeviceConfig.isIphone
                ? Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No Repair Needed',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 13,
                          ),
                        ),
                        Checkbox(
                          value: _noRepairNeeded,
                          activeColor: AppColors.yellow,
                          checkColor: AppColors.mainBackground,
                          onChanged: (value) {
                            setState(() {
                              _noRepairNeeded = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: HoldToConfirmButton(
                        icon: const Icon(Icons.check),
                        label: 'Resolve',
                        baseColor: AppColors.main,
                        textColor: AppColors.yellow,
                        progressColor: AppColors.yellow,
                        holdDuration: const Duration(seconds: 2),
                        onConfirmed: () async {
                          await ApiService().resolveMaintenanceAction(
                            actionId: widget.action.actionId!,
                            resolvedByInitial: widget.currentUserId,
                            noRepairNeeded: _noRepairNeeded,
                            repairNotes: _repairNotes ?? '',
                          );

                          widget.onResolved();
                        },
                      ),
                    ),
                  ],
                  )
                : Row(
                    children: [
                      const Text(
                        'No Repair Needed',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontSize: 13,
                        ),
                      ),
                      Checkbox(
                        value: _noRepairNeeded,
                        activeColor: AppColors.yellow,
                        checkColor: AppColors.mainBackground,
                        onChanged: (value) {
                          setState(() {
                            _noRepairNeeded = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HoldToConfirmButton(
                          icon: const Icon(Icons.check),
                          label: 'Resolve',
                          baseColor: AppColors.main,
                          textColor: AppColors.yellow,
                          progressColor: AppColors.yellow,
                          holdDuration: const Duration(seconds: 2),
                          onConfirmed: () async {
                            await ApiService().resolveMaintenanceAction(
                              actionId: widget.action.actionId!,
                              resolvedByInitial: widget.currentUserId,
                              noRepairNeeded: _noRepairNeeded,
                              repairNotes: _repairNotes ?? '',
                            );

                            widget.onResolved();
                          },
                        ),
                      ),
                    ],
                  ),
          ],
        ),
    );
  }
}