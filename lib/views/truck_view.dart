import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/inventory_item.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../theme/app_colors.dart';

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

class TruckView extends StatelessWidget {
  final String? truckId;
  final String driverId;

  const TruckView({
    super.key,
    required this.truckId,
    required this.driverId,
  });

  // 📸 Image picker
  Future<XFile?> _pickImage({bool camera = true}) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
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
            return Padding(
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
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  // 📸 PHOTO BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final file = await _pickImage();
                            if (file != null) {
                              setState(() => selectedImage = file);
                            }
                          },
                          child: const Text("Take Photo"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
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
                    Image.file(
                      File(selectedImage!.path),
                      height: 120,
                    ),

                  const SizedBox(height: 12),

                  // 📝 DESCRIPTION
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Describe the issue",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🚀 SUBMIT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                                  await api.recordIssue(
                                image:
                                    File(selectedImage!.path),
                                truckId: truckId!,
                                driverId: driverId,
                                description:
                                    descriptionController.text.trim(),
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

  Widget _buildLiftMarker(InventoryItem item, double cellW, double cellH) {
    final pos = parseGridPosition(item.position);

    final row = pos?.row ?? 1;
    final col = pos?.col ?? 1;

    return Positioned(
      left: (col - 1) * cellW + cellW / 2 - 30,
      top: (row - 1) * cellH + cellH / 2 - 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _liftAsset(item.liftType),
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            item.serialNumber,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (truckId == null) {
      return const Center(child: Text('No truck assigned',
        style: TextStyle(
          color: AppColors.yellow,
        ),
      ));
    }

    return FutureBuilder<List<InventoryItem>>(
      future: ApiService().fetchInventoryByDriver(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final inventory = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              "Truck $truckId",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // 🚨 INSPECTION SECTION
            FutureBuilder<bool>(
              future: ApiService().needsInspection(truckId!),
              builder: (context, inspectionSnapshot) {
                if (inspectionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox();
                }

                if (inspectionSnapshot.hasError) {
                  return const SizedBox();
                }

                final needsInspection =
                    inspectionSnapshot.data ?? false;

                if (!needsInspection) {
                  return const SizedBox();
                }

                return Card(
                  color: Colors.orange.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Truck $truckId needs inspection",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "No inspection recorded for this month.",
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // 🛠 Record Issue (NOW WIRED)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _openIssueFlow(context),
                                icon: const Icon(
                                    Icons.report_problem),
                                label:
                                    const Text("Record Issue"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ✅ Hold confirm
                            Expanded(
                              child: HoldToConfirmButton(
                                label: "No Issues",
                                baseColor: AppColors.red,
                                textColor: AppColors.main,
                                progressColor: AppColors.yellow,
                                icon:
                                    const Icon(Icons.check),
                                onConfirmed: () {
                                  // TODO: inspection complete API
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // 📦 INVENTORY
            const Text(
              "Inventory",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            if (inventory.isEmpty)
              const Text("No inventory found")
            else
              SizedBox(
                height: 320,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellW = constraints.maxWidth / 3;
                    final cellH = constraints.maxHeight / 3;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/truck-overhead.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        ...inventory.map((item) {
                          return _buildLiftMarker(item, cellW, cellH);
                        }),
                      ],
                    );
                  },
                ),
              )
          ],
        );
      },
    );
  }
}