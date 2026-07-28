import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stop.dart';
import '../services/api_service.dart';
import 'base_card.dart';
import '../theme/app_colors.dart';
import 'hold_to_confirm_button.dart';
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

  Future<void> _handlePhotoUpload(BuildContext context) async {
    final serial = _serial.trim();
    final type = widget.stop.serviceType?.trim() ?? "";

    final requiresSerial = _requiresSerial(type);
    final skipSerial = _skipSerial(type);

    print("DEBUG: stop.type=${widget.stop.type}");
    print("DEBUG: stop.serviceType=${widget.stop.serviceType}");

    // Validate serial if required
    if (!skipSerial && requiresSerial) {
      final isValid = await _validateSerial(serial);
      if (!isValid) {
        print("DEBUG: serial validation failed for type=$type");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or empty serial number')),
        );
        return;
      }
    }

    // Pick and upload photo
    final file = await _pickImage();
    if (file != null) {
      final compressed = await _compressImage(file);
      final api = ApiService();

      final success = await api.recordServiceWithPhoto(
        compressed,
        widget.stop.id,
        serialNumber: requiresSerial ? serial : null, // ✅ now safe
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
        return AlertDialog(
          title: Text(
            'Delivery Photo',
            style: TextStyle(
              color: AppColors.main,
            ),
          ),
          backgroundColor: AppColors.green,
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
    final Color elementColor = AppColors.green;

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
                      Navigator.pop(context);

                      final bool onArrival = selected == 1;

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
      actions.add(
        ActionItem(
          label: "See Photo",
          icon: Icons.photo,
          color: AppColors.green,
          onPressed: () => _showServicePhoto(context),
        ),
      );

      if (!widget.unassignedView) {
        actions.add(
          ActionItem(
            label: "Take Photo",
            icon: Icons.camera_alt,
            color: AppColors.green,
            onPressed: () => _handlePhotoUpload(context),
          ),
        );

        actions.add(
          ActionItem(
            label: "Upload",
            icon: Icons.upload,
            color: AppColors.green,
            onPressed: () async {
              final serial = _serial.trim();

              if (requiresSerial && !await _validateSerial(serial)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid or empty serial number'),
                  ),
                );
                return;
              }

              final file = await _pickImage(camera: false);

              if (file != null) {
                final compressed = await _compressImage(file);
                final api = ApiService();

                final success = await api.uploadPhoto(
                  compressed,
                  _stop.id,
                  serialNumber: requiresSerial ? serial : null,
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
            },
          ),
        );

        actions.add(
          ActionItem(
            label: "Cancel",
            icon: Icons.block,
            color: AppColors.green,
            onPressed: () => _showCancelDialog(context),
          ),
        );
      }
    }

    Widget serialInput = Container();

    if (!widget.completedView && requiresSerial && !widget.unassignedView) {
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

    // --- Content setup (unchanged) ---
    Widget content = const SizedBox.shrink();

    if (_stop.type.toUpperCase() == "SERVICE") {
      final serviceType = _stop.serviceType?.trim().toUpperCase() ?? "";

    if (serviceType == "CHANGE OUT" &&
        _stop.newLiftType?.isNotEmpty == true) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          serialSelector,
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
          serialSelector,
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
            serialSelector,
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
            serialSelector,
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

