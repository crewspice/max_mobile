import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stop.dart';
import '../services/api_service.dart';
import 'base_card.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../theme/app_colors.dart';
import 'lift_selector_panel.dart';
import '../models/lift.dart';
import 'action_ribbon.dart';

class RentalCard extends StatefulWidget {
  final Stop stop;
  final TextEditingController serialController;
  final Future<void> Function() onRefresh;
  final bool completedView;
  final bool unassignedView;
  final void Function(Stop updatedStop)? onNotesUpdated;

  const RentalCard({
    super.key,
    required this.stop,
    required this.serialController,
    required this.onRefresh,
    this.completedView = false,
    this.unassignedView = false,
    this.onNotesUpdated,
  });

  @override
  State<RentalCard> createState() => _RentalCardState();
}


class _RentalCardState extends State<RentalCard> {

  Future<File?> _pickImage({bool camera = true}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }

  Future<File> _compressImage(File file) async {
    Uint8List bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image != null) {
      img.Image resized = img.copyResize(image, width: 800);
      return File(file.path)
        ..writeAsBytesSync(img.encodeJpg(resized, quality: 85));
    }
    return file;
  }

  Future<bool> _validateSerial(String serial) async {
    if (serial.isEmpty) return false;
    final api = ApiService();
    return await api.validateSerialNumber(serial);
  }

  String computeSerial(String? liftType, String typed) {
    if (liftType == null) return typed.trim();

    final lower = liftType.toLowerCase().trim();

    if (lower.startsWith("45")) return "45";
    if (lower.startsWith("33")) return "33";

    return typed.trim();
  }


  Future<void> _handlePhotoUpload(BuildContext context) async {
    String serial = widget.serialController.text.trim();
    if (!await _validateSerial(serial)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or empty serial number')));
      return;
    }

    if (widget.stop.liftType != null) {
      final lower = widget.stop.liftType!.toLowerCase();
      if (lower.startsWith("45")) {
        serial = "45";
      } else if (lower.startsWith("33")) {
        serial = "33";
      } else {
        serial = widget.serialController.text.trim();
      }
    }

    final file = await _pickImage();
    if (file != null) {
      final compressed = await _compressImage(file);
      final api = ApiService();
      final success =
          await api.recordDeliveryWithPhoto(compressed, widget.stop.id, serial, widget.stop.truck ?? "null", widget.stop.driverId ?? "null");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')));
      if (success) await widget.onRefresh();
    }
  }

  Future<void> _handleGalleryUpload(BuildContext context) async {
    String serial = widget.serialController.text.trim();
    if (!await _validateSerial(serial)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or empty serial number')),
      );
      return;
    }
    if (widget.stop.liftType != null) {
      final lower = widget.stop.liftType!.toLowerCase();
      if (lower.startsWith("45")) {
        serial = "45";
      } else if (lower.startsWith("33")) {
        serial = "33";
      } else {
        serial = widget.serialController.text.trim();
      }
    }
    final file = await _pickImage(camera: false);
    if (file != null) {
      final compressed = await _compressImage(file);
      final api = ApiService();
      final success = await api.recordDeliveryWithPhoto(
        compressed,
        widget.stop.id,
        serial,
        widget.stop.truck ?? "null",
        widget.stop.driverId ?? "null",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Photo uploaded!' : 'Upload failed',
          ),
        ),
      );
      if (success) {
        await widget.onRefresh();
      }
    }
  }


  Future<void> _handlePickupComplete(BuildContext context) async {
    final api = ApiService();

    final success = await api.recordPickup(
      widget.stop.id,
      widget.stop.truck ?? "null",   // or "TRUCK101"
      widget.stop.driverId ?? "null",   // or "Jake"
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Pickup completed!' : 'Failed')),
    );

    if (success) await widget.onRefresh();
  }

  void _showRentalPhoto(BuildContext context) {
    final Color elementColor =
        widget.stop.status == "Active"
            ? AppColors.green
            : (widget.stop.status == "Upcoming"
                ? AppColors.yellow
                : AppColors.red);

    final imageUrl =
        'http://5.78.73.173:8080/images/deliveries/rental_${widget.stop.id}.jpg';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delivery Photo',
            style: TextStyle(
              color: AppColors.main,
            ),
          ),
          backgroundColor: elementColor,
          content: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) {
              return Text('Image not found or failed to load.');
            },
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppColors.main,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context) {
    final Color elementColor =
        widget.stop.status == "Active"
            ? AppColors.green
            : (widget.stop.status == "Upcoming"
                ? AppColors.yellow
                : AppColors.red);

    int selected = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: elementColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: ToggleButtons(
                      isSelected: [
                        selected == 0,
                        selected == 1,
                      ],
                      onPressed: (index) {
                        setState(() {
                          selected = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      fillColor: AppColors.main,
                      selectedColor: elementColor,
                      color: AppColors.main,
                      constraints: const BoxConstraints(
                        minWidth: 135,
                        minHeight: 42,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "Before\nArrival",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "On\nArrival",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: AppColors.main),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: HoldToConfirmButton(
                    icon: const Icon(Icons.cancel),
                    label: "Submit Cancellation",
                    baseColor: AppColors.main,
                    progressColor: AppColors.main,
                    textColor: elementColor,
                    holdDuration: const Duration(seconds: 1),
                    onConfirmed: () async {
                      final bool onArrival = selected == 1;

                      Navigator.pop(context);

                      final api = ApiService();

                      final success = await api.recordCancellation(
                        rentalId: widget.stop.id.toString(),
                        truck: widget.stop.truck ?? "null",
                        driver: widget.stop.driverId ?? "null",
                        type: onArrival
                            ? "Cancelled on Arrival"
                            : "Cancelled",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? (onArrival
                                    ? "Cancelled on arrival"
                                    : "Cancelled before arrival")
                                : "Cancellation failed",
                          ),
                        ),
                      );

                      if (success) {
                        await widget.onRefresh();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if serial is required
    final bool requiresSerial = widget.stop.status == 'Upcoming' &&
        !(widget.stop.liftType == '33rt' || widget.stop.liftType == '45b');

    final Color elementColor =
        widget.stop.status == "Active"
            ? AppColors.green
            : (widget.stop.status == "Upcoming"
                ? AppColors.yellow
                : AppColors.red);

    // --- Serial input field ---
Widget serialInput = Container();

if (requiresSerial && !widget.completedView && !widget.unassignedView) {
  serialInput = Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: LiftSelectorPanel(
          serials: null,
          initialText: widget.serialController.text,
          onChanged: (serial) {
            widget.serialController.text = serial;
          },
        ),
      ),
    ),
  );
} else if (
  !requiresSerial &&
  widget.stop.status != "Upcoming"
) {
  serialInput = Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: LiftSelectorPanel(
  initialText: widget.stop.serialNumber ?? '',
  readOnly: true,
  colors: LiftSelectorColorScheme(
    ball: elementColor,
    border: elementColor,
    selectedBorder: elementColor,
    shadow: AppColors.main,
    text: AppColors.mainBackground,
  ),
  onChanged: (_) {},
),
      ),
    ),
  );
}

    // --- Action buttons ---
    List<ActionItem> actions = [];

    // COMPLETED VIEW → read-only, but allow photo viewing
    if (widget.completedView) {
      actions.add(
        ActionItem(
          label: "See Photo",
          icon: Icons.photo,
          color: elementColor,
          onPressed: () => _showRentalPhoto(context),
        ),
      );
    }

    else if (widget.stop.status == "Upcoming") {

      if (!widget.unassignedView) {

        actions.add(
          ActionItem(
            label: "Take Photo",
            icon: Icons.camera_alt,
            color: elementColor,
            onPressed: requiresSerial
                ? () => _handlePhotoUpload(context)
                : () async {
                  // existing camera upload code
                },
          ),
        );

        actions.add(
          ActionItem(
            label: "Upload",
            icon: Icons.upload,
            color: elementColor,
            onPressed: () => _handleGalleryUpload(context),
          ),
        );

        actions.add(
          ActionItem(
            label: "Cancel",
            icon: Icons.block,
            color: elementColor,
            onPressed: () => _showCancelDialog(context),
          ),
        );
      }
    }

    // CALLED OFF → show Complete + See Photo
    else if (widget.stop.status == "Called Off" ||
            widget.stop.status == "Active") {

      actions.add(
        ActionItem(
          label: "See Photo",
          icon: Icons.photo,
          color: elementColor,
          onPressed: () => _showRentalPhoto(context),
        ),
      );

      if (!widget.unassignedView) {

        actions.add(
          ActionItem(
            label: "Complete",
            icon: Icons.check,
            color: elementColor,
            onPressed: () => _handlePickupComplete(context),
          ),
        );

        actions.add(
          ActionItem(
            label: "Cancel",
            icon: Icons.block,
            color: elementColor,
            onPressed: () => _showCancelDialog(context),
          ),
        );
      }
    }

    Widget actionTray = _ActionTray(
      color: elementColor,
      children: [
        SizedBox(
          width: 140,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainBackground,
              foregroundColor: elementColor,
            ),
            onPressed: () => _showCancelDialog(context),
            icon: const Icon(Icons.block),
            label: const Text("Cancel"),
          ),
        ),
      ],
    );

    return BaseCard(
      stop: widget.stop,
      extraContent: [
        if (actions.isNotEmpty)
          ActionRibbon(actions: actions, color: elementColor),
        serialInput,
      ],
      onRefresh: widget.onRefresh,
      completedView: widget.completedView,
    );
  }
}


  class _ActionTray extends StatefulWidget {
    final Color color;
    final List<Widget> children;

    const _ActionTray({
      required this.color,
      required this.children,
    });

    @override
    State<_ActionTray> createState() => _ActionTrayState();
  }

 class _ActionTrayState extends State<_ActionTray> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              expanded = !expanded;
            });
          },
          child: Center(
            child: Container(
              width: 45,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: AnimatedSlide(
                offset: expanded
                    ? const Offset(0, 0.25)
                    : const Offset(0, -0.35),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.main,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: expanded
              ? Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}