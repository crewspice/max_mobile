import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stop.dart';
import '../models/lift_option.dart';
import '../services/api_service.dart';
import 'base_card.dart';
import '../theme/app_colors.dart';
import 'cancel_dialog.dart';
import 'lift_selector_panel.dart';
import 'action_ribbon.dart';
import '../config/device_config.dart';
import '../utils/lift_assets.dart';
import 'ornate_card.dart';
import 'watermark_title.dart';

class ServiceCard extends StatefulWidget {
  final Stop stop;
  final Future<void> Function() onRefresh;
  final bool completedView;
  final bool unassignedView;

  const ServiceCard({
    super.key,
    required this.stop,
    required this.onRefresh,
    this.completedView = false,
    this.unassignedView = false,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  late Stop _stop;
  String _serial = '';
  int? _selectedRentalId;
  String? _selectedSerial;
  bool _loadingLiftOptions = false;

  // Dispatch stamps a stop's serialNumber as this literal sentinel when the
  // customer had no preference between several interchangeable units at the
  // site — the driver has to tell us which one they actually serviced. This
  // applies to any service type, not just the two Change Out variants.
  bool get _isNoPreference =>
      !widget.completedView &&
      !widget.unassignedView &&
      (_stop.serialNumber?.trim() == 'noPref');

  // Dispatch appends "?" to a designated lift's serialNumber when its
  // proximity group still has other unresolved (Active) siblings at the
  // site — the customer asked for a specific lift, but the driver may still
  // find themselves working on the other one. Never shown on screen.
  bool get _hasDesignatedAmbiguity =>
      !widget.completedView &&
      !widget.unassignedView &&
      (_stop.serialNumber?.trim().endsWith('?') ?? false);

  String _stripAmbiguityMarker(String? raw) {
    final serial = (raw ?? '').trim();
    return serial.endsWith('?')
        ? serial.substring(0, serial.length - 1)
        : serial;
  }

  @override
  void initState() {
    super.initState();
    _stop = widget.stop;
  }

  @override
  void didUpdateWidget(ServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stop != widget.stop) {
      _stop = widget.stop;
    }
  }

  bool _requiresSerial(String serviceType) {
    return serviceType == "Change Out" ||
        serviceType == "Service Change Out";
  }

  bool _skipSerial(String serviceType) {
    return serviceType == "MOVE" ||
        serviceType == "SERVICE";
  }

  // The 33rt and 45b lift types only have a single unit company-wide, so
  // their serial is always fixed ("33"/"45") — the driver never has to type
  // one in for a delivery or Change Out involving the new lift being dropped off.
  bool get _isSpecialLiftType {
    final liftType = _stop.newLiftType?.toLowerCase().trim() ?? '';
    return liftType.startsWith('45') || liftType.startsWith('33');
  }

  String _computeSerial(String typed) {
    final liftType = _stop.newLiftType?.toLowerCase().trim() ?? '';
    if (liftType.startsWith('45')) return '45';
    if (liftType.startsWith('33')) return '33';
    return typed.trim();
  }

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

  String _noPreferenceVerb() {
    final type = _stop.serviceType?.trim() ?? '';
    switch (type) {
      case 'Change Out':
      case 'Service Change Out':
        return 'change out';
      case 'Move':
        return 'move';
      case 'Service':
        return 'service';
      default:
        return 'service';
    }
  }

  Future<void> _openLiftOptionPicker(
    BuildContext context, {
    String? requestedSerial,
  }) async {
    final api = ApiService();
    setState(() => _loadingLiftOptions = true);
    List<LiftOption> options;
    try {
      options = await api.fetchLiftOptionsForService(_stop.id);
    } finally {
      if (mounted) setState(() => _loadingLiftOptions = false);
    }

    if (!context.mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lift options found for this site.'),
        ),
      );
      return;
    }

    const Color elementColor = AppColors.green;

    // Same ornate-card dialog shape as the rental card's lift picker (and
    // the inspection prompt / cancel dialog), so this popup reads as the
    // same family instead of a plain bottom sheet.
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
                  // a two-lift job as well as a six-lift one, instead of one
                  // fixed size that's oversized for a single row or cramped
                  // against three.
                  final tileWidth = 92.0 * DeviceConfig.liftOptionTileScale;
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
                          text: 'Which lift did you ${_noPreferenceVerb()}?',
                          glyph: Icons.search,
                          glyphSize: glyphSize,
                          glyphAlignment: const Alignment(0, -0.65),
                          textColor: elementColor,
                          fontSize: 16,
                        ),
                      ),
                      if (requestedSerial != null && requestedSerial.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Customer requested you ${_noPreferenceVerb()} lift '
                            '$requestedSerial — tap it again to confirm, or '
                            'choose a different one below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: elementColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                                isRequested: option.serialNumber == requestedSerial,
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
  // image standing in for the plain type string, tiled instead of listed one
  // per row.
  Widget _buildLiftOptionTile(
    BuildContext context,
    LiftOption option,
    Color color, {
    bool isRequested = false,
  }) {
    final scale = DeviceConfig.liftOptionTileScale;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, option),
      child: Container(
        width: 92 * scale,
        padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 2 * scale),
        decoration: BoxDecoration(
          color: isRequested
              ? color.withOpacity(0.18)
              : AppColors.mainBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRequested ? color : color.withOpacity(0.6),
            width: isRequested ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              liftAssetPath(option.liftType),
              height: 56 * scale,
              fit: BoxFit.contain,
              color: color,
              colorBlendMode: BlendMode.srcIn,
            ),
            SizedBox(height: 6 * scale),
            Text(
              option.serialNumber,
              style: TextStyle(
                color: color,
                fontSize: 12 * scale,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (isRequested) ...[
              SizedBox(height: 2 * scale),
              Text(
                'Requested',
                style: TextStyle(
                  color: color,
                  fontSize: 9 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handlePhotoUpload(
    BuildContext context, {
    bool camera = true,
  }) async {
    final serial = _computeSerial(_serial);
    final type = widget.stop.serviceType?.trim() ?? "";

    final requiresSerial = _requiresSerial(type);
    final skipSerial = _skipSerial(type);

    print("DEBUG: stop.type=${widget.stop.type}");
    print("DEBUG: stop.serviceType=${widget.stop.serviceType}");

    // Validate serial if required (33rt/45b's fixed serial never needs validating)
    if (!skipSerial && requiresSerial && !_isSpecialLiftType) {
      final isValid = await _validateSerial(serial);
      if (!isValid) {
        print("DEBUG: serial validation failed for type=$type");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or empty serial number')),
        );
        return;
      }
    }

    if (_isNoPreference && _selectedRentalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select which lift you picked up first'),
        ),
      );
      return;
    }

    // Pick and upload photo
    final file = await _pickImage(camera: camera);
    if (file != null) {
      final compressed = await _compressImage(file);
      final api = ApiService();

      final success = await api.recordServiceWithPhoto(
        compressed,
        widget.stop.id,
        serialNumber: requiresSerial ? serial : null, // ✅ now safe
        selectedRentalId: _selectedRentalId,
        widget.stop.truck ?? "null",
        widget.stop.driverId ?? "null"
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')),
      );

      if (success && widget.onRefresh != null) {
        await widget.onRefresh!();
      }
    }
  }


  void _showServicePhoto(BuildContext context) {
    final imageUrl =
        'http://5.78.73.173:8080/images/deliveries/by-service/${widget.stop.id}';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.green,
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


  void _showCancelDialog(BuildContext context) {
    showCancelDialog(
      context: context,
      color: AppColors.green,
      stopType: "Service",
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

    final String serviceType = _stop.serviceType?.trim() ?? "";

    final bool requiresSerial = 
        serviceType == "Change Out" || serviceType == "Service Change Out";
    final bool skipSerial = serviceType == "MOVE" || serviceType == "SERVICE";


    // Action buttons
    List<ActionItem> actions = [];

    if (widget.completedView) {
      actions.add(
        ActionItem(
          label: "See Photo",
          icon: Icons.photo,
          color: AppColors.green,
          onPressed: () => _showServicePhoto(context),
        ),
      );
    } else {
      final seePhoto = ActionItem(
        label: "See Photo",
        icon: Icons.photo,
        color: AppColors.green,
        onPressed: () => _showServicePhoto(context),
      );

      if (!widget.unassignedView) {
        final takePhoto = ActionItem(
          label: "Take Photo",
          icon: Icons.camera_alt,
          color: AppColors.green,
          onPressed: () => _handlePhotoUpload(context),
        );

        final upload = ActionItem(
          label: "Upload",
          icon: Icons.upload,
          color: AppColors.green,
          onPressed: () => _handlePhotoUpload(context, camera: false),
        );

        final cancel = ActionItem(
          label: "Cancel",
          icon: Icons.block,
          color: AppColors.green,
          onPressed: () => _showCancelDialog(context),
        );

        if (_isNoPreference) {
          // Select is inserted at index 0 below — lead with the photo steps
          // that actually finish the stop before See Photo/Cancel.
          actions.addAll([takePhoto, upload, seePhoto, cancel]);
        } else {
          actions.addAll([seePhoto, takePhoto, upload, cancel]);
        }
      } else {
        actions.add(seePhoto);
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
          color: AppColors.green,
          loading: _loadingLiftOptions,
          onPressed: () => _openLiftOptionPicker(context),
        ),
      );
    }

    // A specific lift was designated, but its proximity group still has an
    // unresolved sibling nearby — offer the same picker, just optional and
    // tucked at the end of the ribbon instead of required up front.
    if (_hasDesignatedAmbiguity) {
      actions.add(
        ActionItem(
          label: _selectedRentalId == null ? "Select" : "Selected",
          icon: _selectedRentalId == null
              ? Icons.question_mark
              : Icons.rule,
          color: AppColors.green,
          loading: _loadingLiftOptions,
          onPressed: () => _openLiftOptionPicker(
            context,
            requestedSerial: _stripAmbiguityMarker(_stop.serialNumber),
          ),
        ),
      );
    }

    Widget serialInput = Container();

    if (!widget.completedView &&
        requiresSerial &&
        !widget.unassignedView &&
        !_isSpecialLiftType) {
      serialInput = Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Transform.scale(
              scale: DeviceConfig.liftSelectorScale(),
              child: LiftSelectorPanel(
                initialText: _serial,
                emptyTextSize: 18,
                ipadEmptyTextSize: 30,
                colors: const LiftSelectorColorScheme(
                  ball: AppColors.green,
                  border: AppColors.green,
                  selectedBorder: AppColors.yellow,
                  shadow: AppColors.yellow,
                  text: AppColors.mainBackground,
                ),
                onChanged: (serial) {
                  setState(() {
                    _serial = serial;
                  });
                },
              ),
            ),
          ),
        ),
      );
    }

    final Widget serialSelector = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Transform.scale(
            scale: DeviceConfig.liftSelectorScale(),
            child: LiftSelectorPanel(
              emptyTextSize: 18,
              ipadEmptyTextSize: 30,
              initialText:
                  _selectedSerial ?? _stripAmbiguityMarker(_stop.serialNumber),
              readOnly: true,
              colors: LiftSelectorColorScheme(
                ball: AppColors.green,
                border: AppColors.green,
                selectedBorder: AppColors.green,
                shadow: AppColors.main,
                text: AppColors.mainBackground,
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    // Selecting which lift was serviced now lives in the action ribbon; once
    // picked, show it here read-only so the driver can confirm which serial
    // they chose (and see it update if they reselect).
    final Widget selectedSerialPanel = _selectedSerial == null
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
                    ipadEmptyTextSize: 30,
                    initialText: _selectedSerial!,
                    readOnly: true,
                    colors: const LiftSelectorColorScheme(
                      ball: AppColors.green,
                      border: AppColors.green,
                      selectedBorder: AppColors.green,
                      shadow: AppColors.main,
                      text: AppColors.mainBackground,
                    ),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          );

    // Completed Change Out / Service Change Out stops carry the old and new
    // serials joined by a colon (stamped server-side at completion time, e.g.
    // "6742:6749"). Once completed, split that pair into two read-only panels
    // stacked with a label between them instead of the single serialSelector.
    Widget buildSerialPanel(String text) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Transform.scale(
          scale: DeviceConfig.liftSelectorScale(),
          child: LiftSelectorPanel(
            emptyTextSize: 18,
            ipadEmptyTextSize: 30,
            initialText: text,
            readOnly: true,
            colors: const LiftSelectorColorScheme(
              ball: AppColors.green,
              border: AppColors.green,
              selectedBorder: AppColors.green,
              shadow: AppColors.main,
              text: AppColors.mainBackground,
            ),
            onChanged: (_) {},
          ),
        ),
      );
    }

    Widget buildDoubleSerialSelector({
      required String oldSerial,
      required String newSerial,
      required String label,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Center(
          child: Column(
            children: [
              buildSerialPanel(oldSerial),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              buildSerialPanel(newSerial),
            ],
          ),
        ),
      );
    }

    final String rawSerial = _stop.serialNumber ?? '';
    final int colonIndex = rawSerial.indexOf(':');
    final bool hasSerialPair = widget.completedView && colonIndex != -1;
    final String oldSerial = hasSerialPair ? rawSerial.substring(0, colonIndex) : '';
    final String newSerial = hasSerialPair ? rawSerial.substring(colonIndex + 1) : '';

    // --- Content setup (unchanged) ---
    Widget content = const SizedBox.shrink();

    if (_stop.type.toUpperCase() == "SERVICE") {
      final serviceType = _stop.serviceType?.trim().toUpperCase() ?? "";

    if (serviceType == "CHANGE OUT" &&
        _stop.newLiftType?.isNotEmpty == true) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasSerialPair)
            buildDoubleSerialSelector(
              oldSerial: oldSerial,
              newSerial: newSerial,
              label: "to ${_stop.newLiftType}: ",
            )
          else ...[
            _isNoPreference ? selectedSerialPanel : serialSelector,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'to: ',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.green,
                  ),
                ),
                Text(
                  _stop.newLiftType!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ],

          if (_stop.reason != null && _stop.reason != "")
            Text(
              "\"${_stop.reason!}\"",
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.green,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      );
    } else if (serviceType == "SERVICE CHANGE OUT") {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasSerialPair)
            buildDoubleSerialSelector(
              oldSerial: oldSerial,
              newSerial: newSerial,
              label: "to: ",
            )
          else
            _isNoPreference ? selectedSerialPanel : serialSelector,
          if (_stop.reason != null && _stop.reason != "")
            SizedBox(
              width: double.infinity,
              child: Text(
                "\"${_stop.reason!}\"",
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    } else if (serviceType == "MOVE") {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _isNoPreference ? selectedSerialPanel : serialSelector,
            if (_stop.newStreetAddress?.isNotEmpty == true)
              Text(
                "New Site:",
                style: const TextStyle(fontSize: 13, color: AppColors.green),
                textAlign: TextAlign.center,
              ),
            if (_stop.newSiteName?.isNotEmpty == true)
              Text(
                _stop.newSiteName!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.green),
                textAlign: TextAlign.center,
              ),
            if (_stop.newStreetAddress?.isNotEmpty == true)
              Text(
                _stop.newStreetAddress!,
                style: const TextStyle(fontSize: 16, color: AppColors.green),
                textAlign: TextAlign.center,
              ),
            if (_stop.newCity?.isNotEmpty == true)
              Text(
                _stop.newCity!,
                style: const TextStyle(fontSize: 16, color: AppColors.green),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            if (_stop.reason != null && _stop.reason != "")
              Text(
                "\"${_stop.reason!}\"",
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.green),
                textAlign: TextAlign.center,
              ),
          ],
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _isNoPreference ? selectedSerialPanel : serialSelector,
            if (_stop.reason != null && _stop.reason != "")
              Text(
                "\"${_stop.reason!}\"",
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.green),
                textAlign: TextAlign.center,
              ),
          ],
        );
      }
    }

    return BaseCard(
      stop: _stop,
      extraContent: [
        SizedBox(
          width: double.infinity,
          child: content,
        ),
        if (actions.isNotEmpty)
          const SizedBox(height: 3),
          ActionRibbon(
            actions: actions,
            color: AppColors.green,
        ),
        const SizedBox(height: 7),
        serialInput,
      ],
      onRefresh: widget.onRefresh,
      onNotesUpdated: (updatedStop) {
        setState(() {
          _stop = updatedStop;
        });
      },
    );

  }
}

