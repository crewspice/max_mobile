import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stop.dart';
import '../models/lift_option.dart';
import '../models/site_resource_photos.dart';
import '../services/api_service.dart';
import 'base_card.dart';
import 'cancel_dialog.dart';
import '../theme/app_colors.dart';
import 'lift_selector_panel.dart';
import '../models/lift.dart';
import 'action_ribbon.dart';
import '../config/device_config.dart';
import '../utils/lift_assets.dart';
import 'ornate_card.dart';
import 'watermark_title.dart';

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
  int? _selectedRentalId;
  String? _selectedSerial;
  SiteResourcePhotos? _siteResourcePhotos;

  @override
  void initState() {
    super.initState();
    _loadSiteResourcePhotos();
  }

  @override
  void didUpdateWidget(RentalCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stop.id != widget.stop.id) {
      setState(() {});
    }
    if (oldWidget.stop.siteId != widget.stop.siteId) {
      _loadSiteResourcePhotos();
    }
  }

  // Backend answers "does this site have previous helpful delivery photos" -
  // the mobile side never does its own address matching, it just consumes
  // the result to decide whether to show the "Previous Site Photos" button.
  Future<void> _loadSiteResourcePhotos() async {
    final result = await ApiService().fetchSiteResourcePhotos(widget.stop.siteId);
    if (mounted) {
      setState(() {
        _siteResourcePhotos = result;
      });
    }
  }

  // Dispatch stamps a pickup stop's serialNumber as this literal sentinel
  // when the customer had no preference between several interchangeable
  // units at the site — the driver has to tell us which one they picked up.
  bool get _isNoPreference =>
      !widget.completedView &&
      !widget.unassignedView &&
      widget.stop.status == 'Called Off' &&
      (widget.stop.serialNumber?.trim() == 'noPref');

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

  // 33rt and 45b only have a single unit company-wide, so their serial is
  // always fixed ("33"/"45") and never needs typing or validating.
  bool isSpecialLiftType(String? liftType) {
    final lower = liftType?.toLowerCase().trim() ?? '';
    return lower.startsWith('45') || lower.startsWith('33');
  }


  Future<void> _handlePhotoUpload(BuildContext context) async {
    final serial = computeSerial(widget.stop.liftType, widget.serialController.text);

    if (!isSpecialLiftType(widget.stop.liftType) && !await _validateSerial(serial)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or empty serial number')));
      return;
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
    final serial = computeSerial(widget.stop.liftType, widget.serialController.text);

    if (!isSpecialLiftType(widget.stop.liftType) && !await _validateSerial(serial)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or empty serial number')),
      );
      return;
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
    if (_isNoPreference && _selectedRentalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select which lift you picked up first'),
        ),
      );
      return;
    }

    final api = ApiService();

    final success = await api.recordPickup(
      widget.stop.id,
      widget.stop.truck ?? "null",   // or "TRUCK101"
      widget.stop.driverId ?? "null",   // or "Jake"
      selectedRentalId: _selectedRentalId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Pickup completed!' : 'Failed')),
    );

    if (success) await widget.onRefresh();
  }

  Future<void> _openLiftOptionPicker(BuildContext context) async {
    final api = ApiService();
    final options = await api.fetchLiftOptionsForRental(widget.stop.id);

    if (!context.mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lift options found for this site.'),
        ),
      );
      return;
    }

    final Color elementColor = widget.stop.status == "Active"
        ? AppColors.green
        : (widget.stop.status == "Upcoming" ? AppColors.yellow : AppColors.red);

    // Same ornate-card dialog shape as the inspection prompt / cancel
    // dialog, rather than a bottom sheet, so all three popups on this
    // screen read as one family.
    final selected = await showDialog<LiftOption>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: OrnateCard(
            color: elementColor,
            backgroundColor: AppColors.mainBackground,
            padding: EdgeInsets.zero,
            child: Container(
              color: AppColors.mainBackground,
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The watermark scales with how many tile rows the grid
                  // actually wraps to, so it still reads as sized-to-fit on
                  // a two-lift rental as well as a six-lift one, instead of
                  // one fixed size that's oversized for a single row or
                  // cramped against three.
                  const tileWidth = 92.0;
                  const tileSpacing = 10.0;
                  final columns = ((constraints.maxWidth + tileSpacing) /
                          (tileWidth + tileSpacing))
                      .floor()
                      .clamp(1, options.length);
                  final rows = (options.length / columns).ceil();
                  final glyphSize = (190 + (rows - 1) * 50)
                      .toDouble()
                      .clamp(190.0, 300.0);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: WatermarkTitle(
                          text: 'Which lift did you pick up?',
                          glyph: Icons.search,
                          glyphSize: glyphSize,
                          glyphAlignment: const Alignment(0, -0.65),
                          textColor: elementColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: tileSpacing,
                          runSpacing: tileSpacing,
                          children: [
                            for (final option in options)
                              _buildLiftOptionTile(
                                dialogContext,
                                option,
                                elementColor,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedRentalId = selected.rentalId;
        _selectedSerial = selected.serialNumber;
      });
    }
  }

  // Matches the inventory markers on the truck view: the lift-type asset
  // image standing in for the plain type string, tiled instead of listed
  // one per row. Horizontal padding is tight against the border - the
  // reclaimed width goes to a bigger image instead - so the tile's overall
  // footprint stays the same while the image reads as the dominant thing in
  // it; the type code isn't repeated as text since the image already says
  // it.
  Widget _buildLiftOptionTile(
    BuildContext context,
    LiftOption option,
    Color color,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, option),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.mainBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              liftAssetPath(option.liftType),
              height: 56,
              fit: BoxFit.contain,
              color: color,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 6),
            Text(
              option.serialNumber,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
        return Dialog(
          backgroundColor: elementColor,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Image not found or failed to load.'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, Color elementColor, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: elementColor,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Image not found or failed to load.'),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSiteResourcePhotos(BuildContext context) {
    final Color elementColor =
        widget.stop.status == "Active"
            ? AppColors.green
            : (widget.stop.status == "Upcoming"
                ? AppColors.yellow
                : AppColors.red);

    final photos = _siteResourcePhotos?.photos ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: elementColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Previous Site Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return GestureDetector(
                          onTap: () =>
                              _showFullImage(context, elementColor, photo.imageUrl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photo.imageUrl,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Padding(
                                    padding: EdgeInsets.all(12),
                                    child:
                                        Text('Image not found or failed to load.'),
                                  ),
                                ),
                              ),
                              if (photo.reason.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    photo.reason,
                                    style: const TextStyle(
                                        color: Colors.black87, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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

    // Upcoming = not yet delivered; Active/Called Off = delivered, awaiting
    // pickup.
    final String stopType =
        widget.stop.status == "Upcoming" ? "Delivery" : "Pickup";

    showCancelDialog(
      context: context,
      color: elementColor,
      stopType: stopType,
      onCancel: (onArrival) => ApiService().recordCancellation(
        rentalId: widget.stop.id.toString(),
        truck: widget.stop.truck ?? "null",
        driver: widget.stop.driverId ?? "null",
        type: onArrival ? "Cancelled on Arrival" : "Cancelled",
      ),
      onSuccess: widget.onRefresh,
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
            child: Transform.scale(
              scale: DeviceConfig.liftSelectorScale(),
              child: LiftSelectorPanel(
                emptyTextSize: 18,
                serials: null,
                initialText: widget.serialController.text,
                onChanged: (serial) {
                  widget.serialController.text = serial;
                },
              ),
            ),
          ),
        ),
      );
    } else if (widget.completedView &&
        widget.stop.status == "Upcoming" &&
        (widget.stop.serialNumber ?? '').isNotEmpty) {
      // Completed delivery — serial number stamped by the driver at delivery time.
      serialInput = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Transform.scale(
              scale: DeviceConfig.liftSelectorScale(),
              child: LiftSelectorPanel(
                emptyTextSize: 18,
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
        ),
      );
    } else if (_isNoPreference) {
      // Selecting which lift was picked up now lives in the action ribbon;
      // once picked, show it here read-only so the driver can confirm which
      // serial they chose (and see it update if they reselect).
      serialInput = _selectedSerial == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Transform.scale(
                    scale: DeviceConfig.liftSelectorScale(),
                    child: LiftSelectorPanel(
                      emptyTextSize: 18,
                      initialText: _selectedSerial!,
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
              ),
            );
    } else if (!requiresSerial && widget.stop.status != "Upcoming") {
      serialInput = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Transform.scale(
              scale: DeviceConfig.liftSelectorScale(),
              child: LiftSelectorPanel(
                emptyTextSize: 18,
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
            onPressed: () => _handlePhotoUpload(context),
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

        if (_siteResourcePhotos?.hasHelpfulPhotos == true) {
          actions.add(
            ActionItem(
              label: "Previous Site Photos",
              icon: Icons.photo_library,
              color: elementColor,
              onPressed: () => _showSiteResourcePhotos(context),
            ),
          );
        }
      }
    }

    // CALLED OFF → show Complete + See Photo
    else if (widget.stop.status == "Called Off" ||
            widget.stop.status == "Active") {
      if (!widget.unassignedView) {
        actions.add(
          ActionItem(
            label: "Complete",
            icon: Icons.check,
            color: elementColor,
            onPressed: () => _handlePickupComplete(context),
            holdToConfirm: true,
            progressColor: AppColors.green,
          ),
        );

        actions.add(
          ActionItem(
            label: "See Photo",
            icon: Icons.photo,
            color: elementColor,
            onPressed: () => _showRentalPhoto(context),
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
      } else {
        actions.add(
          ActionItem(
            label: "See Photo",
            icon: Icons.photo,
            color: elementColor,
            onPressed: () => _showRentalPhoto(context),
          ),
        );
      }
    }

    if (_isNoPreference) {
      actions.insert(
        0,
        ActionItem(
          label: _selectedRentalId == null ? "Select" : "Selected",
          icon: _selectedRentalId == null
              ? Icons.question_mark
              : Icons.rule,
          color: elementColor,
          onPressed: () => _openLiftOptionPicker(context),
        ),
      );
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
      onNotesUpdated: widget.onNotesUpdated,
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