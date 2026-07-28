import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/inventory_item.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../theme/app_colors.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ornate_card.dart';

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

  final col = switch (match.group(2)!) {
    'a' => 1,
    'b' => 2,
    'c' => 3,
    _ => null
  };

  if (col == null) return null;

  return GridPos(row, col);
}

class TruckView extends StatefulWidget {
  final String? truckId;
  final String driverId;

  const TruckView({
    super.key,
    required this.truckId,
    required this.driverId,
  });

  @override
  State<TruckView> createState() => _TruckViewState();
}

class _TruckViewState extends State<TruckView> {

  // 📸 Image picker
  Future<XFile?> _pickImage({bool camera = true}) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
  }

  // 🚨 ISSUE FLOW
  void _openIssueFlow(BuildContext context) {
    final descriptionController = TextEditingController();
    XFile? selectedImage;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              color: AppColors.main,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Report Issue",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 📸 PHOTO BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: AppColors.mainBackground,
                            ),
                            onPressed: () async {
                              final file = await _pickImage();

                              if (file != null) {
                                final bytes = await file.readAsBytes();
                                final decoded = img.decodeImage(bytes);

                                debugPrint("Path: ${file.path}");

                                if (decoded != null) {
                                  debugPrint(
                                    "Decoded pixels: ${decoded.width} x ${decoded.height}",
                                  );
                                }

                                setState(() => selectedImage = file);
                              }
                            },
                            child: const Text("Take Photo"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: AppColors.mainBackground,
                            ),
                            onPressed: () async {
                              final file =
                                  await _pickImage(camera: false);
                              if (file != null) {
                                setState(() => selectedImage = file);
                              }
                            },
                            icon: const Icon(Icons.upload),
                            label: const Text("Upload"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (selectedImage != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.yellow,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          File(selectedImage!.path),
                          height: 120,
                        ),
                      ),
                    const SizedBox(height: 12),

                    // 📝 DESCRIPTION
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: AppColors.red,
                      ),
                      decoration: InputDecoration(
                        labelText: "Describe the issue",
                        labelStyle: const TextStyle(
                          color: AppColors.red,
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.red,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.red,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.red,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🚀 SUBMIT
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: AppColors.mainBackground,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (selectedImage == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Photo required")),
                                  );
                                  return;
                                }

                                setState(() => isSubmitting = true);

                                final api = ApiService();

                                final success =
                                    await api.recordTruckIssue(
                                  image: File(selectedImage!.path),
                                  truckId: widget.truckId!,
                                  driverId: widget.driverId,
                                  description: descriptionController.text.trim(),
                                );

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Issue submitted'
                                        : 'Submission failed'),
                                  ),
                                );
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator()
                            : const Text("Submit Issue"),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _liftAsset(String liftType) {
    switch (liftType.trim().toLowerCase()) {
      case "12m":
        return "assets/12m.png";
      case "19s":
        return "assets/19s.png";
      case "26":
        return "assets/26.png";
      case "26s":
        return "assets/26s.png";
      case "32":
        return "assets/32.png";
      case "33rt":
        return "assets/33rt.png";
      case "40":
        return "assets/40.png";
      case "45b":
        return "assets/45b.png";
      default:
        return "assets/26.png"; // fallback
    }
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiftDetails(
    BuildContext context,
    InventoryItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.mainBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.precision_manufacturing,
                color: AppColors.yellow,
              ),
              const SizedBox(width: 10),
              Text(
                "${item.liftType} Lift",
                style: const TextStyle(
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _detailRow(
                  "Serial Number",
                  item.serialNumber,
                ),

                _detailRow(
                  "Position",
                  item.position ?? "Unknown",
                ),

                const Divider(
                  color: AppColors.yellow,
                ),

                // Future API fields

                _detailRow(
                  "Customer",
                  "Loading...",
                ),

                _detailRow(
                  "Address",
                  "Loading...",
                ),

                _detailRow(
                  "Last PM Date",
                  "Loading...",
                ),

                _detailRow(
                  "Last PM Performer",
                  "Loading...",
                ),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(
                  color: AppColors.yellow,
                ),
              ),
            ),
          ],
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

  Widget _buildLiftMarker(
    BuildContext context,
    InventoryItem item,
    double gridLeft,
    double gridTop,
    double cellW,
    double cellH,
  ) {
    final pos = parseGridPosition(item.position);

    final row = pos?.row ?? 1;
    final col = pos?.col ?? 1;

    final Color markerColor;

    if (item.serialNumber == "0") {
      markerColor = AppColors.yellow;
    } else if (item.upToDate) {
      markerColor = AppColors.green;
    } else {
      markerColor = AppColors.red;
    }

    return Positioned(
      left: gridLeft + ((col - 1) * cellW) + (cellW / 2) - 30,
      top: gridTop + ((row - 1) * cellH) + (cellH / 2) - 30,
      child: GestureDetector(
        onTap: () => _showLiftDetails(context, item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _liftAsset(item.liftType),
              height: 60,
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

        return FutureBuilder<bool>(
          future: ApiService().needsInspection(widget.truckId!),
          builder: (context, inspectionSnapshot) {
            final needsInspection =
                inspectionSnapshot.data ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Truck ${widget.truckId}",
                        style: GoogleFonts.permanentMarker(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.yellow,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (needsInspection)

                      OrnateCard(
                        color: AppColors.red,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: AppColors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Truck ${widget.truckId} needs inspection",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "No inspection recorded for this month.",
                              style: TextStyle(
                                color: AppColors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.mainBackground,
                                      side: const BorderSide(
                                        color: AppColors.red,
                                        width: 2,
                                      ),
                                    ),
                                    onPressed: () => _openIssueFlow(context),
                                    icon: const Icon(
                                      Icons.report_problem,
                                      color: AppColors.red,
                                    ),
                                    label: const Text(
                                      "Record Issue",
                                      style: TextStyle(
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: HoldToConfirmButton(
                                    label: "No Issues",
                                    baseColor: AppColors.mainBackground,
                                    textColor: AppColors.red,
                                    progressColor: AppColors.red,
                                    icon: const Icon(
                                      Icons.check,
                                      color: AppColors.red,
                                    ),
                                    onConfirmed: () async {
                                      try {
                                        await ApiService().recordTruckInspection(
                                          truckId: widget.truckId!,
                                          driverId: widget.driverId,
                                        );

                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Inspection recorded successfully.',
                                            ),
                                          ),
                                        );

                                        setState(() {});
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to record inspection: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

                              final gridWidth = constraints.maxWidth / 2.6; // middle third
                              final gridLeft = (constraints.maxWidth - gridWidth) / 2 + 20;

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

                                  ...inventory.map(
                                    (item) => _buildLiftMarker(
                                      context,
                                      item,
                                      gridLeft,
                                      gridTop,
                                      cellW,
                                      cellH,
                                    ),
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