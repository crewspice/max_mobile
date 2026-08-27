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

  // Dispatch stamps a stop's serialNumber as this literal sentinel when the
  // customer had no preference between several interchangeable units at the
  // site — the driver has to tell us which one they actually serviced. This
  // applies to any service type, not just the two Change Out variants.
  bool get _isNoPreference =>
      !widget.completedView &&
      !widget.unassignedView &&
      (_stop.serialNumber?.trim() == 'noPref');

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

  Future<void> _openLiftOptionPicker(BuildContext context) async {
    final api = ApiService();
    final options = await api.fetchLiftOptionsForService(_stop.id);

    if (!context.mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lift options found for this site.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<LiftOption>(
      context: context,
      backgroundColor: AppColors.main,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Which lift did you ${_noPreferenceVerb()}?',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              for (final option in options)
                ListTile(
                  title: Text(
                    option.liftType,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    option.serialNumber,
                    style: const TextStyle(color: AppColors.green),
                  ),
                  onTap: () => Navigator.pop(context, option),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedRentalId = selected.rentalId;
      });
    }
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
          onPressed: () => _openLiftOptionPicker(context),
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
              initialText: _stop.serialNumber ?? '',
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
            _isNoPreference ? const SizedBox.shrink() : serialSelector,
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
            _isNoPreference ? const SizedBox.shrink() : serialSelector,
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
            _isNoPreference ? const SizedBox.shrink() : serialSelector,
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
            _isNoPreference ? const SizedBox.shrink() : serialSelector,
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

