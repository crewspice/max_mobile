import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stop.dart';
import '../services/api_service.dart';
import 'base_card.dart';

class ServiceCard extends StatelessWidget {
  final Stop stop;
  final TextEditingController serialController = TextEditingController();
  final Future<void> Function() onRefresh;

  ServiceCard({Key? key, required this.stop, required this.onRefresh}) : super(key: key);

  bool _requiresSerial(String serviceType) {
    return serviceType == "Change Out" || serviceType == "Service Change Out";
  }

  bool _skipSerial(String serviceType) {
    return serviceType == "MOVE" || serviceType == "SERVICE";
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
    final serial = serialController.text.trim();
    final type = stop.serviceType?.trim() ?? "";

    final requiresSerial = _requiresSerial(type);
    final skipSerial = _skipSerial(type);

    print("DEBUG: stop.type=${stop.type}");
    print("DEBUG: stop.serviceType=${stop.serviceType}");
    print("DEBUG: requiresSerial=$requiresSerial");
    print("DEBUG: skipSerial=$skipSerial");

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
        stop.id,
        serialNumber: requiresSerial ? serial : null, // ✅ now safe
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')),
      );

      if (success && onRefresh != null) {
        await onRefresh!();
      }
    }
  }



  Future<void> _handlePickupComplete(BuildContext context) async {
    final api = ApiService();
    final success = await api.recordPickup(stop.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Pickup completed!' : 'Failed')),
    );
    if (success && onRefresh != null) await onRefresh!();
  }

  void _showServicePhoto(BuildContext context) {
    final imageUrl =
        'http://5.78.73.173:8080/images/deliveries/by-service/${stop.id}';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Service Photo'),
          content: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) {
              return const Text('Image not found or failed to load.');
            },
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final String serviceType = stop.serviceType?.trim() ?? "";

    final bool requiresSerial = 
        serviceType == "Change Out" || serviceType == "Service Change Out";
    final bool skipSerial = serviceType == "MOVE" || serviceType == "SERVICE";

    Widget serialInput = Container();
    if (requiresSerial) {
      serialInput = Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: TextField(
            controller: serialController,
            decoration: const InputDecoration(labelText: 'Serial Number'),
          ),
        ),
      );
    }

    // Action buttons (universal)
    List<Widget> actionButtons = [];

    // Row 1: See Photo (only if stop.hasPhoto)
    if (stop.hasPhoto) {
      actionButtons.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showServicePhoto(context),
              child: const Text("See Photo"),
            ),
          ],
        ),
      );
      actionButtons.add(const SizedBox(height: 8));
    }

    // Row 2: Take Photo + Upload Photo (always available)
    actionButtons.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _handlePhotoUpload(context),
            child: const Text('Take Photo'),
          ),
          const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final serial = serialController.text.trim();
                if (requiresSerial && !await _validateSerial(serial)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid or empty serial number')),
                  );
                  return;
                }

                final file = await _pickImage(camera: false);
                if (file != null) {
                  final compressed = await _compressImage(file);
                  final api = ApiService();
                  final success = await api.uploadPhoto(
                    compressed,
                    stop.id,
                    serialNumber: requiresSerial ? serial : null, // ✅ safe now
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')),
                  );
                  if (success && onRefresh != null) await onRefresh!();
                }
              },

              icon: const Icon(Icons.upload),
              label: const Text('Upload Photo'),
            ),

        ],
      ),
    );



    // --- Content setup (unchanged) ---
    Widget content = const SizedBox.shrink();

    if (stop.type.toUpperCase() == "SERVICE") {
      final serviceType = stop.serviceType?.trim().toUpperCase() ?? "";

      if (serviceType == "CHANGE OUT" && stop.newLiftType?.isNotEmpty == true) {
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  const Text(
                    'to: ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    stop.newLiftType!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stop.reason != null)
                    Text(
                      "\"${stop.reason!}\"",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  if (stop.locationNotes != null)
                    Text(
                      stop.locationNotes!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  if (stop.preTripInstructions != null)
                    Text(
                      "Pre-trip: ${stop.preTripInstructions}",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  serialInput,
                ],
              ),
            ),
          ],
        );
      } else if (serviceType == "SERVICE CHANGE OUT") {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stop.reason != null)
              Text(
                "\"${stop.reason!}\"",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (stop.locationNotes != null)
              Text(
                stop.locationNotes!,
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (stop.preTripInstructions != null)
              Text(
                "Pre-trip: ${stop.preTripInstructions}",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (serialInput is! Container) Center(child: serialInput),
          ],
        );
      } else if (serviceType == "MOVE") {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stop.newSiteName?.isNotEmpty == true)
              Text(
                stop.newSiteName!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            if (stop.newStreetAddress?.isNotEmpty == true)
              Text(
                stop.newStreetAddress!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            if (stop.newCity?.isNotEmpty == true)
              Text(
                stop.newCity!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            if (stop.reason != null)
              Text(
                "\"${stop.reason!}\"",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (stop.locationNotes != null)
              Text(
                stop.locationNotes!,
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (stop.preTripInstructions != null)
              Text(
                "Pre-trip: ${stop.preTripInstructions}",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            serialInput,
          ],
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stop.reason != null)
              Text(
                "\"${stop.reason!}\"",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (stop.locationNotes != null)
              Text(
                stop.locationNotes!,
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            if (stop.preTripInstructions != null)
              Text(
                "Pre-trip: ${stop.preTripInstructions}",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            serialInput,
          ],
        );
      }
    }

    return BaseCard(
      stop: stop,
      extraContent: [content],
      actionButtons: actionButtons, // <-- pass directly
      onRefresh: onRefresh,
    );


  }
}
