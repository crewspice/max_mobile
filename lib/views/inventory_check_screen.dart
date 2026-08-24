import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/lift.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hold_to_select_row.dart';
import '../widgets/lift_selector_panel.dart';

// Local, mutable copy of a predicted yard entry. Kept separate from
// YardListItem because this screen needs to track per-row check state and
// the server-issued itemId (needed to undo a check-off).
class _ChecklistEntry {
  final int? liftId;
  final String? liftType;
  final String? serialNumber;
  final bool upToDate;
  final bool needsRepair;
  bool checked = false;
  int? itemId;

  _ChecklistEntry({
    this.liftId,
    this.liftType,
    this.serialNumber,
    required this.upToDate,
    this.needsRepair = false,
  });
}

// A lift found in the yard that wasn't on the predicted list.
class _UnexpectedEntry {
  final int? liftId;
  final String serialNumber;
  final int itemId;
  bool hasPhoto = false;

  _UnexpectedEntry({
    this.liftId,
    required this.serialNumber,
    required this.itemId,
  });
}

class _SectionHeader {
  final String label;
  const _SectionHeader(this.label);
}

class _TypeHeader {
  final String label;
  const _TypeHeader(this.label);
}

class _EmptyNote {
  final String label;
  const _EmptyNote(this.label);
}

/// Full-screen walk-the-yard flow: scan/confirm predicted lifts off a
/// checklist, flag anything unexpected, then finalize the session.
class InventoryCheckScreen extends StatefulWidget {
  final String currentUserId;

  const InventoryCheckScreen({super.key, required this.currentUserId});

  @override
  State<InventoryCheckScreen> createState() => _InventoryCheckScreenState();
}

class _InventoryCheckScreenState extends State<InventoryCheckScreen> {
  int? _sessionId;
  List<_ChecklistEntry> _predicted = [];
  final List<_UnexpectedEntry> _unexpected = [];
  List<Lift> _allLifts = [];

  bool _loading = true;
  String? _error;
  bool _finalizing = false;

  // Bumped after every lift selection to force LiftSelectorPanel back to
  // its empty state (same idiom as re-keying a controlled input).
  int _selectorResetKey = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        ApiService().startInventoryCheckSession(widget.currentUserId),
        ApiService().fetchLifts(),
      ]);

      final session = results[0] as Map<String, dynamic>;
      final lifts = results[1] as List<Lift>;
      final predictedJson = (session['predicted'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _sessionId = session['sessionId'] as int;
        _predicted = predictedJson.map((e) {
          final m = e as Map<String, dynamic>;
          return _ChecklistEntry(
            liftId: m['liftId'] as int?,
            liftType: m['liftType'] as String?,
            serialNumber: m['serialNumber'] as String?,
            upToDate: m['upToDate'] as bool? ?? false,
            needsRepair: m['needsRepair'] as bool? ?? false,
          );
        }).toList();
        _allLifts = lifts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to start inventory check session.';
        _loading = false;
      });
    }
  }

  Future<void> _handleLiftSelected(Lift lift) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    final serial = lift.serialNumber ?? '';

    _ChecklistEntry? match;
    for (final entry in _predicted) {
      if (!entry.checked &&
          (entry.serialNumber ?? '').toLowerCase() == serial.toLowerCase()) {
        match = entry;
        break;
      }
    }

    try {
      final result = await ApiService().recordInventoryCheckItem(
        sessionId,
        serial,
        liftId: lift.liftId,
      );
      final itemId = result['itemId'] as int?;
      final itemType = result['itemType'] as String?;

      if (!mounted) return;

      if (match != null && itemType == 'PREDICTED_CHECKED') {
        setState(() {
          match!.checked = true;
          match.itemId = itemId;
        });
      } else {
        setState(() {
          _unexpected.add(_UnexpectedEntry(
            liftId: lift.liftId,
            serialNumber: serial,
            itemId: itemId ?? 0,
          ));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Not on the predicted list — recorded as unexpected',
            ),
            action: SnackBarAction(
              label: 'Add Photo',
              onPressed: () => _attachPhoto(sessionId, itemId ?? 0),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record item.')),
        );
      }
    }

    if (mounted) {
      setState(() => _selectorResetKey++);
    }
  }

  Future<void> _manualCheckOff(_ChecklistEntry entry) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      final result = await ApiService().recordInventoryCheckItem(
        sessionId,
        entry.serialNumber ?? '',
        liftId: entry.liftId,
      );
      if (!mounted) return;
      setState(() {
        entry.checked = true;
        entry.itemId = result['itemId'] as int?;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record check-off.')),
        );
      }
    }
  }

  Future<void> _undoEntry(_ChecklistEntry entry) async {
    final sessionId = _sessionId;
    final itemId = entry.itemId;
    if (sessionId == null || itemId == null) return;

    try {
      await ApiService().undoInventoryCheckItem(sessionId, itemId);
      if (!mounted) return;
      setState(() {
        entry.checked = false;
        entry.itemId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to undo check-off.')),
        );
      }
    }
  }

  Future<void> _attachPhoto(int sessionId, int itemId) async {
    if (itemId == 0) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    try {
      await ApiService().attachInventoryCheckItemPhoto(
        sessionId,
        itemId,
        File(picked.path),
      );
      if (!mounted) return;
      setState(() {
        for (final u in _unexpected) {
          if (u.itemId == itemId) {
            u.hasPhoto = true;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to attach photo.')),
        );
      }
    }
  }

  Future<void> _finishWalk() async {
    final sessionId = _sessionId;
    if (sessionId == null || _finalizing) return;

    setState(() => _finalizing = true);

    try {
      final result = await ApiService().finalizeInventoryCheckSession(
        sessionId,
      );
      if (!mounted) return;

      final checkedCount = result['checkedCount'] ?? 0;
      final unexpectedCount = result['unexpectedCount'] ?? 0;
      final missingCount = result['missingCount'] ?? 0;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.main,
          title: const Text(
            'Walk Complete',
            style: TextStyle(color: AppColors.yellow),
          ),
          content: Text(
            '$checkedCount confirmed, $unexpectedCount unexpected, '
            '$missingCount missing',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.green),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to finalize inventory check.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _finalizing = false);
      }
    }
  }

  List<Object> _buildRows() {
    final rows = <Object>[];

    final unchecked = _predicted.where((e) => !e.checked).toList();
    final checked = _predicted.where((e) => e.checked).toList();

    rows.add(_SectionHeader('Still Looking (${unchecked.length})'));
    if (unchecked.isEmpty) {
      rows.add(const _EmptyNote('All predicted lifts checked.'));
    } else {
      String? lastType;
      for (final entry in unchecked) {
        final type = entry.liftType ?? 'Unknown';
        if (type != lastType) {
          rows.add(_TypeHeader(type));
          lastType = type;
        }
        rows.add(entry);
      }
    }

    rows.add(_SectionHeader('Checked (${checked.length})'));
    if (checked.isEmpty) {
      rows.add(const _EmptyNote('Nothing checked yet.'));
    } else {
      rows.addAll(checked);
    }

    rows.add(_SectionHeader('Unexpected in Yard (${_unexpected.length})'));
    if (_unexpected.isEmpty) {
      rows.add(const _EmptyNote('No surprises yet.'));
    } else {
      rows.addAll(_unexpected);
    }

    return rows;
  }

  Widget _buildRow(Object row) {
    if (row is _SectionHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Text(
          row.label,
          style: const TextStyle(
            color: AppColors.yellow,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (row is _TypeHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          row.label,
          style: const TextStyle(
            color: AppColors.yellow,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (row is _EmptyNote) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          row.label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      );
    }

    if (row is _ChecklistEntry) {
      if (!row.checked) {
        final flagged = row.needsRepair || !row.upToDate;
        final statusLabel = row.needsRepair
            ? 'Needs Repair'
            : (row.upToDate ? 'Up to date' : 'Needs PM');

        return SizedBox(
          height: 52,
          child: HoldToSelectRow(
            onConfirmed: () => _manualCheckOff(row),
            child: MediaQuery.withNoTextScaling(
              child: ListTile(
                dense: true,
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: flagged ? AppColors.red : AppColors.green,
                ),
                title: Text(
                  row.serialNumber ?? '',
                  style: const TextStyle(color: AppColors.yellow),
                ),
                trailing: Text(
                  statusLabel,
                  style: TextStyle(
                    color: flagged ? AppColors.red : AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Card(
        color: AppColors.main,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          dense: true,
          onTap: () => _undoEntry(row),
          leading: const Icon(
            Icons.check_circle,
            color: AppColors.green,
            size: 18,
          ),
          title: Text(
            row.serialNumber ?? '',
            style: const TextStyle(
              color: AppColors.green,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
      );
    }

    final unexpected = row as _UnexpectedEntry;
    return Card(
      color: AppColors.main,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.red.withOpacity(0.6), width: 1),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.red,
          size: 18,
        ),
        title: Text(
          unexpected.serialNumber,
          style: const TextStyle(color: AppColors.red),
        ),
        trailing: unexpected.hasPhoto
            ? const Icon(Icons.camera_alt, color: AppColors.yellow, size: 16)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.yellow,
                AppColors.green,
                AppColors.red,
              ],
            ).createShader(bounds);
          },
          child: Text(
            "Inventory Check",
            style: GoogleFonts.permanentMarker(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.yellow),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final rows = _buildRows();
    final checkedCount = _predicted.where((e) => e.checked).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: LiftSelectorPanel(
            key: ValueKey(_selectorResetKey),
            lifts: _allLifts,
            initialText: '',
            onChanged: (_) {},
            onLiftSelected: _handleLiftSelected,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '$checkedCount / ${_predicted.length} checked',
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: rows.length,
            itemBuilder: (context, i) => _buildRow(rows[i]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.mainBackground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _finalizing ? null : _finishWalk,
                icon: const Icon(Icons.flag_circle_outlined),
                label: Text(
                  _finalizing ? 'Finishing...' : 'Finish Walk',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
