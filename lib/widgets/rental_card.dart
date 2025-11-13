import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stop.dart';
import '../services/api_service.dart';
import 'base_card.dart';

class RentalCard extends StatelessWidget {
  final Stop stop;
  final TextEditingController serialController;
  final Future<void> Function() onRefresh;

  const RentalCard({
    Key? key,
    required this.stop,
    required this.serialController,
    required this.onRefresh,
  }) : super(key: key);

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
    if (!await _validateSerial(serial)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or empty serial number')));
      return;
    }

    final file = await _pickImage();
    if (file != null) {
      final compressed = await _compressImage(file);
      final api = ApiService();
      final success =
          await api.recordDeliveryWithPhoto(compressed, stop.id, serial);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')));
      if (success) await onRefresh();
    }
  }

  Future<void> _handlePickupComplete(BuildContext context) async {
    final api = ApiService();
    final success = await api.recordPickup(stop.id);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Pickup completed!' : 'Failed')));
    if (success) await onRefresh();
  }

  void _showRentalPhoto(BuildContext context) {
    final imageUrl = 'http://5.78.73.173:8080/images/deliveries/rental_${stop.id}.jpg';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delivery Photo'),
          content: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) {
              return Text('Image not found or failed to load.');
            },
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    // Determine if serial is required
    final bool requiresSerial = stop.status == 'Upcoming' &&
        !(stop.liftType == '33rt' || stop.liftType == '45b');

    // Serial input field
    Widget serialInput = Container();
    if (requiresSerial) {
      serialInput = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: TextField(
              controller: serialController,
              decoration: const InputDecoration(labelText: 'Serial Number'),
            ),
          ),
        ),
      );
    }

    // Action buttons
    List<Widget> actionButtons = [];
    if (stop.status == 'Upcoming') {
      actionButtons.addAll([
        ElevatedButton(
          onPressed: requiresSerial
              ? () => _handlePhotoUpload(context)
              : () async {
                  // If lift type is 33rt or 45b, bypass serial
                  final file = await _pickImage();
                  if (file != null) {
                    final compressed = await _compressImage(file);
                    final api = ApiService();
                    final success = await api.recordDeliveryWithPhoto(
                        compressed, stop.id, ''); // empty serial
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(success ? 'Photo uploaded!' : 'Upload failed')));
                    if (success) await onRefresh();
                  }
                },
          child: const Text('Take Photo'),
        ),
        ElevatedButton.icon(
          onPressed: requiresSerial
              ? () async {
                  final file = await _pickImage(camera: false);
                  if (file != null) {
                    final compressed = await _compressImage(file);
                    final api = ApiService();
                    final success = await api.recordDeliveryWithPhoto(
                      compressed,
                      stop.id,
                      serialController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')),
                    );
                    if (success) await onRefresh();
                  }
                }
              : () async {
                  final file = await _pickImage(camera: false);
                  if (file != null) {
                    final compressed = await _compressImage(file);
                    final api = ApiService();
                    final success = await api.recordDeliveryWithPhoto(
                      compressed,
                      stop.id,
                      '', // empty serial for bypass
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')),
                    );
                    if (success) await onRefresh();
                  }
                },
          icon: const Icon(Icons.upload),
          label: const Text('Upload Photo'),
        ),
      ]);
    } else if (stop.status == 'Called Off') {
      List<Widget> calledOffButtons = [];

      // Only show "See Photo" if a photo exists
      if (stop.hasPhoto) {
        calledOffButtons.add(
          ElevatedButton(
            onPressed: () => _showRentalPhoto(context),
            child: const Text('See Photo'),
          ),
        );
      }

      // "Complete" button always shows
      calledOffButtons.add(
        ElevatedButton(
          onPressed: () => _handlePickupComplete(context),
          child: const Text('Complete'),
        ),
      );

      // Wrap in a centered row
      actionButtons.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < calledOffButtons.length; i++) ...[
              calledOffButtons[i],
              if (i < calledOffButtons.length - 1) const SizedBox(width: 8),
            ]
          ],
        ),
      );
    }



    return BaseCard(
      stop: stop,
      extraContent: [serialInput],
      actionButtons: actionButtons,
      onRefresh: onRefresh,
    );
  }

}
