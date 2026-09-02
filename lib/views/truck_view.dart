import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory_item.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/maintenance/inspection_prompt_card.dart';
import '../config/device_config.dart';
import '../utils/lift_assets.dart';

class GridPos {
  final int row;
  final int col;

  const GridPos(this.row, this.col);
}

GridPos? parseGridPosition(String? pos) {
  if (pos == null) return null;

  final cleaned = pos.trim().toLowerCase();

  final match = RegExp(r'^([1-3])([abc])$').firstMatch(cleaned);
  if (match == null) return null;

  final row = int.parse(match.group(1)!);

  final col =
      switch (match.group(2)!) { 'a' => 1, 'b' => 2, 'c' => 3, _ => null };

  if (col == null) return null;

  return GridPos(row, col);
}

class TruckView extends StatefulWidget {
  final String? truckId;
  final String driverId;
  final ValueChanged<String> onOpenLiftMaintenance;

  const TruckView({
    super.key,
    required this.truckId,
    required this.driverId,
    required this.onOpenLiftMaintenance,
  });

  @override
  State<TruckView> createState() => _TruckViewState();
}

class _TruckViewState extends State<TruckView> {
  // Toggled by the icon on the truck-name line so a driver can log an
  // inspection even when one isn't currently overdue.
  bool _manualInspectionOpen = false;

  static const _spectrumGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.yellow, AppColors.green, AppColors.red],
  );

  Widget _gradientDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: _spectrumGradient),
        child: SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  Future<void> _recordNoIssues(
    BuildContext context, {
    bool closeManual = false,
  }) async {
    try {
      await ApiService().recordTruckInspection(
        truckId: widget.truckId!,
        driverId: widget.driverId,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection recorded successfully.'),
        ),
      );

      setState(() {
        if (closeManual) _manualInspectionOpen = false;
      });
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record inspection: $e'),
        ),
      );
    }
  }

  Widget _detailRow(
    String label,
    String value, {
    double scale = 1.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailLabel(label, scale: scale),
          SizedBox(width: DeviceConfig.isIphone ? 8 : 0),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRowWidget(
    String label,
    Widget value, {
    double scale = 1.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailLabel(label, scale: scale),
          SizedBox(width: DeviceConfig.isIphone ? 8 : 0),
          Expanded(child: value),
        ],
      ),
    );
  }

  // On iPhone the label sizes to its text so the value sits close behind it;
  // other devices keep the fixed column so unrelated rows stay aligned.
  Widget _detailLabel(String label, {double scale = 1.0}) {
    final text = Text(
      label,
      style: TextStyle(
        color: AppColors.yellow,
        fontWeight: FontWeight.bold,
        fontSize: 14 * scale,
      ),
    );
    return DeviceConfig.isIphone
        ? text
        : SizedBox(width: 120 * scale, child: text);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Ports the "months, weeks, & days" formatting used by the desktop app's
  // PopupCard/PopupDisc (business-day based, 5-day weeks / 4-week months).
  String _formatDaysOnRent(int businessDays) {
    final months = businessDays ~/ 20;
    final remainder = businessDays % 20;
    final weeks = remainder ~/ 5;
    final days = remainder % 5;

    final sb = StringBuffer();
    if (months > 0) {
      sb.write('$months ${months == 1 ? "month" : "months"}');
    }
    if (weeks > 0) {
      if (sb.isNotEmpty) sb.write(', ');
      sb.write('$weeks ${weeks == 1 ? "week" : "weeks"}');
    }
    if (days > 0) {
      if (sb.isNotEmpty) sb.write(', & ');
      sb.write('$days ${days == 1 ? "day" : "days"}');
    }
    return sb.isEmpty ? "0 days" : sb.toString();
  }

  void _showLiftDetails(
    BuildContext context,
    InventoryItem initialItem,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        var currentItem = initialItem;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final scale = DeviceConfig.isIpad ? 1.5 : 1.0;
            final address = [currentItem.streetAddress, currentItem.city]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ');
            final hasJobSite = currentItem.customerName != null &&
                currentItem.customerName!.isNotEmpty;
            final pmColor =
                currentItem.upToDate ? AppColors.green : AppColors.red;
            // A serial number of "0" means this row is a placeholder for an
            // unspecified/not-yet-assigned lift, not a real unit — PM status,
            // repair history, and maintenance actions don't apply to it.
            final isUnspecified = currentItem.serialNumber == "0";

            Future<void> handleRefresh() async {
              try {
                final inventory =
                    await ApiService().fetchInventoryByDriver(widget.driverId);
                final updated = inventory.firstWhere(
                  (i) => i.serialNumber == currentItem.serialNumber,
                  orElse: () => currentItem,
                );
                setDialogState(() {
                  currentItem = updated;
                });
              } catch (_) {
                // Keep showing the last known data on failure.
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              // The Expanded content column otherwise stretches to whatever
              // width Dialog's insetPadding leaves it, i.e. nearly the full
              // screen - iPad has no need for that, so cap it to a width
              // sized for this popup's own content instead.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: DeviceConfig.isIpad
                      ? MediaQuery.of(context).size.width * 0.6
                      : double.infinity,
                ),
                child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3,
                      decoration:
                          const BoxDecoration(gradient: _spectrumGradient),
                    ),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 3, color: AppColors.yellow),
                          Expanded(
                            child: Container(
                              color: AppColors.mainBackground,
                              constraints: const BoxConstraints(maxHeight: 480),
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                              child: RefreshIndicator(
                                color: AppColors.main,
                                backgroundColor: AppColors.yellow,
                                onRefresh: handleRefresh,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.precision_manufacturing,
                                            color: AppColors.yellow,
                                            size: 24 * scale,
                                          ),
                                          SizedBox(width: 10 * scale),
                                          Expanded(
                                            child: Text(
                                              isUnspecified
                                                  ? currentItem.liftType
                                                  : "${currentItem.liftType} • ${currentItem.serialNumber}",
                                              style: TextStyle(
                                                color: AppColors.yellow,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16 * scale,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isUnspecified) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              currentItem.upToDate
                                                  ? Icons.check_circle
                                                  : Icons.warning,
                                              color: pmColor,
                                              size: 18 * scale,
                                            ),
                                            SizedBox(width: 6 * scale),
                                            Text(
                                              currentItem.upToDate
                                                  ? "Up to date"
                                                  : "Needs PM",
                                              style: TextStyle(
                                                color: pmColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14 * scale,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      _gradientDivider(),
                                      Text(
                                        currentItem.isPickup
                                            ? "Coming from:"
                                            : "Delivering to:",
                                        style: TextStyle(
                                          color: AppColors.yellow,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 * scale,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (hasJobSite) ...[
                                        Text(
                                          currentItem.customerName!,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14 * scale),
                                        ),
                                        if (address.isNotEmpty)
                                          Text(
                                            address,
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14 * scale),
                                          ),
                                        if (currentItem.isPickup &&
                                            currentItem.daysOnRent != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            "${_formatDaysOnRent(currentItem.daysOnRent!)} on rent",
                                            style: TextStyle(
                                              color: AppColors.yellow,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13 * scale,
                                            ),
                                          ),
                                        ],
                                      ] else
                                        Text(
                                          "No job site recorded",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14 * scale),
                                        ),
                                      if (!isUnspecified) ...[
                                        _gradientDivider(),
                                        _detailRowWidget(
                                          "Last PM",
                                          Row(
                                            children: [
                                              Text(
                                                currentItem.lastPmDate != null
                                                    ? _formatDate(currentItem
                                                        .lastPmDate!)
                                                    : "None recorded",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14 * scale),
                                              ),
                                              if (currentItem
                                                      .lastPmPerformerInitials !=
                                                  null) ...[
                                                SizedBox(width: 8 * scale),
                                                UserAvatar(
                                                  initials: currentItem
                                                      .lastPmPerformerInitials,
                                                  radius: 12 * scale,
                                                  color: AppColors.yellow,
                                                ),
                                              ],
                                            ],
                                          ),
                                          scale: scale,
                                        ),
                                        _detailRow(
                                          "Pending Repairs",
                                          (currentItem.pendingRepairs ?? 0)
                                              .toString(),
                                          scale: scale,
                                        ),
                                      ],
                                      Row(
                                        mainAxisAlignment: isUnspecified
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (!isUnspecified)
                                            IconButton(
                                              icon: Icon(
                                                Icons.build,
                                                color: AppColors.green,
                                                size: 24 * scale,
                                              ),
                                              tooltip: 'Open in Maintenance',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                widget.onOpenLiftMaintenance(
                                                  currentItem.serialNumber,
                                                );
                                              },
                                            ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              "Close",
                                              style: TextStyle(
                                                color: AppColors.yellow,
                                                fontSize: 14 * scale,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(width: 3, color: AppColors.red),
                        ],
                      ),
                    ),
                    Container(
                      height: 3,
                      decoration:
                          const BoxDecoration(gradient: _spectrumGradient),
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget gradientText(String text) {
    return ShaderMask(
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
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white, // required for ShaderMask
          letterSpacing: 2,
        ),
      ),
    );
  }

  // The `position` field (e.g. "2b") only loosely says which row/column a
  // lift is nominally in — sometimes a row has lifts in b+c only, sometimes
  // just a, etc. Rather than pinning each lift to its literal lettered slot,
  // group by row and center however many lifts actually landed there: 1 lift
  // sits dead-center, 2 sit symmetrically spaced around center, 3 falls back
  // to the original a/b/c spacing.
  List<Widget> _buildLiftMarkers(
    BuildContext context,
    List<InventoryItem> inventory,
    double gridLeft,
    double gridTop,
    double cellW,
    double cellH,
  ) {
    final Map<int, List<InventoryItem>> byRow = {};
    for (final item in inventory) {
      final row = parseGridPosition(item.position)?.row ?? 1;
      byRow.putIfAbsent(row, () => []).add(item);
    }

    final rowCenterX = gridLeft + (cellW * 3) / 2;
    final markers = <Widget>[];

    for (final row in byRow.keys.toList()..sort()) {
      final rowItems = byRow[row]!
        ..sort((a, b) {
          final colA = parseGridPosition(a.position)?.col ?? 1;
          final colB = parseGridPosition(b.position)?.col ?? 1;
          return colA.compareTo(colB);
        });

      final centerY = gridTop + ((row - 1) * cellH) + (cellH / 2);
      final n = rowItems.length;
      final colSpacing =
          cellW + (n == 2 && DeviceConfig.isIphone ? 5.0 : 0.0);

      for (var i = 0; i < n; i++) {
        final centerX = rowCenterX + (i - (n - 1) / 2) * colSpacing;
        markers.add(
          _buildLiftMarker(context, rowItems[i], centerX, centerY),
        );
      }
    }

    return markers;
  }

  Widget _buildLiftMarker(
    BuildContext context,
    InventoryItem item,
    double centerX,
    double centerY,
  ) {
    final Color markerColor;

    if (item.serialNumber == "0") {
      markerColor = AppColors.yellow;
    } else if (item.upToDate) {
      markerColor = AppColors.green;
    } else {
      markerColor = AppColors.red;
    }

    final imageHeight = DeviceConfig.device == "ipad" ? 90.0 : 60.0;

    return Positioned(
      left: centerX - 30,
      top: centerY - (imageHeight / 2),
      child: GestureDetector(
        onTap: () => _showLiftDetails(context, item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              liftAssetPath(item.liftType),
              height: imageHeight,
              fit: BoxFit.contain,
              color: markerColor,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 4),
            Text(
              item.serialNumber,
              style: TextStyle(
                fontSize: 10,
                color: markerColor,
                shadows: const [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.truckId == null) {
      return const Center(
        child: Text(
          'No truck assigned',
          style: TextStyle(
            color: AppColors.yellow,
          ),
        ),
      );
    }

    return FutureBuilder<List<InventoryItem>>(
      future: ApiService().fetchInventoryByDriver(widget.driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: gradientText("No Truck"),
          );
        }

        final inventory = snapshot.data ?? [];

        return FutureBuilder<List<String>>(
          future: ApiService().needsInspectionRollingWeek([widget.truckId!]),
          builder: (context, inspectionSnapshot) {
            final needsInspection =
                inspectionSnapshot.data?.contains(widget.truckId) ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Truck ${widget.truckId}",
                              style: GoogleFonts.permanentMarker(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.yellow,
                              ),
                            ),
                          ),
                          if (!needsInspection)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _manualInspectionOpen =
                                      !_manualInspectionOpen;
                                });
                              },
                              tooltip: 'Log an inspection',
                              icon: Icon(
                                _manualInspectionOpen
                                    ? Icons.expand_less
                                    : Icons.fact_check_outlined,
                                color: AppColors.yellow,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (needsInspection)
                        InspectionPromptCard(
                          title: "Truck ${widget.truckId} needs inspection",
                          message:
                              "None recorded in $kInspectionWindowDays days.",
                          glyphSize: 165,
                          onSubmitIssue: (image, description) =>
                              ApiService().recordTruckIssue(
                            image: image,
                            truckId: widget.truckId!,
                            driverId: widget.driverId,
                            description: description,
                          ),
                          onNoIssues: () => _recordNoIssues(context),
                        )
                      else if (_manualInspectionOpen)
                        InspectionPromptCard(
                          title: "Log an inspection",
                          message:
                              "Optional - last one was within $kInspectionWindowDays days.",
                          color: AppColors.yellow,
                          icon: Icons.fact_check_outlined,
                          glyphSize: 165,
                          onSubmitIssue: (image, description) =>
                              ApiService().recordTruckIssue(
                            image: image,
                            truckId: widget.truckId!,
                            driverId: widget.driverId,
                            description: description,
                          ),
                          onNoIssues: () =>
                              _recordNoIssues(context, closeManual: true),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        "Inventory",
                        style: GoogleFonts.permanentMarker(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: inventory.isEmpty
                      ? Center(
                          child: gradientText("No Inventory"),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final gridWidth =
                                  constraints.maxWidth / 2.6; // middle third
                              final gridLeft =
                                  (constraints.maxWidth - gridWidth) / 2 + 10;

                              final gridHeight = constraints.maxHeight * 0.68;
                              final gridTop = constraints.maxHeight * 0.30;
                              final cellW = gridWidth / 3;
                              final cellH = gridHeight / 3;

                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/overhead-truck.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  ..._buildLiftMarkers(
                                    context,
                                    inventory,
                                    gridLeft,
                                    gridTop,
                                    cellW,
                                    cellH,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
