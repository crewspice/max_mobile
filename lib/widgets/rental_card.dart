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
  final void Function(Stop updatedStop)? onNotesUpdated;

  const RentalCard({
    Key? key,
    required this.stop,
    required this.serialController,
    required this.onRefresh,
    required this.onNotesUpdated,
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

  String computeSerial(String? liftType, String typed) {
    if (liftType == null) return typed.trim();

    final lower = liftType.toLowerCase().trim();

    if (lower.startsWith("45")) return "45";
    if (lower.startsWith("33")) return "33";

    return typed.trim();
  }


  Future<void> _handlePhotoUpload(BuildContext context) async {
    String serial = serialController.text.trim();
    if (!await _validateSerial(serial)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or empty serial number')));
      return;
    }

    if (stop.liftType != null) {
      final lower = stop.liftType!.toLowerCase();
      if (lower.startsWith("45")) {
        serial = "45";
      } else if (lower.startsWith("33")) {
        serial = "33";
      } else {
        serial = serialController.text.trim();
      }
    }

    final file = await _pickImage();
    if (file != null) {
      final compressed = await _compressImage(file);
      final api = ApiService();
      final success =
          await api.recordDeliveryWithPhoto(compressed, stop.id, serial, stop.truck ?? "null", stop.driverId ?? "null");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Photo uploaded!' : 'Upload failed')));
      if (success) await onRefresh();
    }
  }

  Future<void> _handlePickupComplete(BuildContext context) async {
    final api = ApiService();

    final success = await api.recordPickup(
      stop.id,
      stop.truck ?? "null",   // or "TRUCK101"
      stop.driverId ?? "null",   // or "Jake"
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Pickup completed!' : 'Failed')),
    );

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

  final List<Widget> preInfoWidgets = [];


  // Notes row with flush-right edit icon
  Widget notesRow = Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Text(
              stop.notes != null && stop.notes!.isNotEmpty
                  ? stop.notes!
                  : 'No notes yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () async {
              final controller = TextEditingController(text: stop.notes ?? '');

              final updatedNotes = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Edit Notes'),
                    content: TextField(
                      controller: controller,
                      maxLines: 5,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter notes here...',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );

              if (updatedNotes == null) return;

              final api = ApiService();
              final success = await api.updateRentalNotes(
                rentalItemId: stop.id,
                notes: updatedNotes,
              );

              if (success) {
                final updatedStop = stop.copyWith(notes: updatedNotes);

                // Call the parent callback instead of setState
                if (onNotesUpdated != null) {
                  onNotesUpdated!(updatedStop); // ✅ safe call
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes updated')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update notes')),
                );
              }

            },
            child: Image.asset(
              'assets/notes.png',
              width: 20,
              height: 20,
            ),
          ),
        ),
      ],
    ),
  );


  // --- Serial input field ---
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

  // --- Action buttons ---
  List<Widget> actionButtons = [];

  // UPCOMING → show delivery buttons
  if (stop.status == 'Upcoming') {
    actionButtons.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Take Photo
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: requiresSerial
                  ? () => _handlePhotoUpload(context)
                  : () async {
                      final file = await _pickImage();
                      if (file != null) {
                        final compressed = await _compressImage(file);
                        String serial = "i";
                        if (stop.liftType != null) {
                          final lower = stop.liftType!.toLowerCase();
                          if (lower.startsWith("45")) serial = "45";
                          else if (lower.startsWith("33")) serial = "33";
                          else serial = serialController.text.trim();
                        }
                        final api = ApiService();
                        final success = await api.recordDeliveryWithPhoto(
                          compressed,
                          stop.id,
                          serial,
                          stop.truck ?? "null",
                          stop.driverId ?? "null",
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  success ? 'Photo uploaded!' : 'Upload failed')),
                        );
                        if (success) await onRefresh();
                      }
                    },
              child: const Text('Take Photo'),
            ),
          ),

          const SizedBox(width: 10),

          // Upload Photo
          SizedBox(
            width: 160,
            child: ElevatedButton.icon(
              onPressed: () async {
                final file = await _pickImage(camera: false);
                if (file != null) {
                  final compressed = await _compressImage(file);
                  String serial = "o";
                  if (stop.liftType != null) {
                    final lower = stop.liftType!.toLowerCase();
                    if (lower.startsWith("45")) serial = "45";
                    else if (lower.startsWith("33")) serial = "33";
                    else serial = serialController.text.trim();
                  }
                  final api = ApiService();
                  final success = await api.recordDeliveryWithPhoto(
                    compressed,
                    stop.id,
                    serial,
                    stop.truck ?? "null",
                    stop.driverId ?? "null",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(success ? 'Photo uploaded!' : 'Upload failed')),
                  );
                  if (success) await onRefresh();
                }
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Photo'),
            ),
          ),
        ],
      ),
    );
  }

  // CALLED OFF → show Complete + See Photo
  else if (stop.status == 'Called Off') {
    List<Widget> calledOffButtons = [];

    calledOffButtons.add(
      ElevatedButton(
        onPressed: () => _showRentalPhoto(context),
        child: const Text('See Photo'),
      ),
    );

    calledOffButtons.add(
      ElevatedButton(
        onPressed: () => _handlePickupComplete(context),
        child: const Text('Complete'),
      ),
    );

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
    extraContent: [
      ...preInfoWidgets,
      notesRow,
      serialInput,
    ],
    actionButtons: actionButtons,
    onRefresh: onRefresh,
  );
}


}
