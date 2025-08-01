import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rental.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class RentalCard extends StatelessWidget {
  final Rental rental;
  final TextEditingController serialController;
  final Future<void> Function() onRefresh;

  const RentalCard({
    super.key,
    required this.rental,
    required this.serialController,
    required this.onRefresh,
  });

  Future<File?> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  String _mapLiftType(String? liftType) {
    if (liftType == '<19S') return '19s';
    return liftType ?? '';
  }

  Widget _getIndentedText(String text) {
    if (text.length <= 13) {
      return Text(text, style: TextStyle(fontSize: 16));
    }

    List<String> words = text.split(' ');
    String firstLine = '';
    String secondLine = '';
    int currentLineLength = 0;
    int breakIndex = 0;

    while (breakIndex < words.length &&
        currentLineLength + words[breakIndex].length + (breakIndex > 0 ? 1 : 0) <= 13) {
      if (breakIndex > 0) firstLine += ' ';
      firstLine += words[breakIndex];
      currentLineLength = firstLine.length;
      breakIndex++;
    }

    String remainingText = words.sublist(breakIndex).join(' ');

    if (remainingText.length > 10) {
      secondLine = '   ' + remainingText.substring(0, 7) + '...';
    } else {
      secondLine = '   ' + remainingText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(firstLine, style: TextStyle(fontSize: 16)),
        if (secondLine.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Text(secondLine, style: TextStyle(fontSize: 16)),
          ),
        ],
      ],
    );
  }

  Future<bool> _validateSerialNumber(String serialNumber) async {
    var apiService = ApiService();
    bool isValid = await apiService.validateSerialNumber(serialNumber);
    if (!isValid) {
      print("Invalid serial number!");
    }
    return isValid;
  }

  Future<void> _handlePhotoUpload(BuildContext context) async {
    String serialNumber = serialController.text.trim();

    if (serialNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Serial number is not set yet!")),
      );
      return;
    }

    // Step 1: Validate serial number
    bool isValidSerial = await _validateSerialNumber(serialNumber);
    if (!isValidSerial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Serial number is invalid. Please check.")),
      );
      return;
    }

    // Step 2: Take photo
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      File imageFile = File(photo.path);
      File compressedImageFile = await compressImage(imageFile);

      var apiService = ApiService();
      bool success = await apiService.recordDeliveryWithPhoto(
        compressedImageFile,
        rental.rentalId,
        serialNumber,
      );

      if (success) {
        serialController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("All steps completed successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload delivery info.")),
        );
      }
    }
  }

  Future<void> _handlePickupComplete(BuildContext context) async {
    var apiService = ApiService();
    bool success = await apiService.recordPickup(rental.rentalId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pickup completed successfully.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to complete pickup. Please try again.")),
      );
    }
  }


  Future<File> compressImage(File file) async {
    Uint8List imageBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image != null) {
      img.Image resized = img.copyResize(image, width: 800); // Resize width to 800px
      File compressedFile = File(file.path)..writeAsBytesSync(img.encodeJpg(resized, quality: 85)); // Adjust quality
      return compressedFile;
    }
    return file;
  }


  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      DateTime date = DateTime.parse(dateString);
      String day = DateFormat('d').format(date);
      String month = DateFormat('MMM').format(date);

      int dayNumber = int.parse(day);
      String suffix;
      if (dayNumber >= 11 && dayNumber <= 13) {
        suffix = 'th';
      } else {
        switch (dayNumber % 10) {
          case 1:
            suffix = 'st';
            break;
          case 2:
            suffix = 'nd';
            break;
          case 3:
            suffix = 'rd';
            break;
          default:
            suffix = 'th';
        }
      }

      return '$month $day$suffix';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _launchDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  void launchMaps(String address) async {
    if (address.isEmpty) {
      print('Address is empty');
      return;
    }

    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl = 'https://www.google.com/maps?q=$encodedAddress';

    final googleMapsUri = Uri.parse(googleMapsUrl);

    if (await canLaunch(googleMapsUri.toString())) {
      await launch(googleMapsUri.toString());
    } else {
      final geoUri = Uri.parse('geo:0,0?q=$encodedAddress');
      if (await canLaunch(geoUri.toString())) {
        await launch(geoUri.toString());
      } else {
        throw 'Could not launch Google Maps or Geo scheme for address: $address';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side - Status Icon + Lift Type
                Column(
                  children: [
                    Image.asset(
                      rental.status == 'Upcoming'
                          ? 'assets/dropping-off.png'
                          : 'assets/picking-up.png',
                      height: 68,
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        _mapLiftType(rental.liftType),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                // Right Side Layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          rental.customer ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Address + Serial
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => launchMaps(rental.siteName ?? ''),
                                  child: Text(
                                    rental.siteName ?? 'Unknown Site',
                                    style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => launchMaps(rental.streetAddress ?? ''),
                                  child: Text(
                                    rental.streetAddress ?? 'Unknown Address',
                                    style: TextStyle(color: Color(0xFF8B0000)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => launchMaps(rental.city ?? ''),
                                  child: Text(
                                    rental.city ?? 'Unknown City',
                                    style: TextStyle(color: Color(0xFF8B0000)),
                                  ),
                                ),
                                if (rental.status == 'Upcoming') ...[
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: serialController,
                                    decoration: InputDecoration(
                                      labelText: 'Enter Serial Number',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          // Right Column - Contacts + Action Buttons
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_formatDate(rental.deliveryDate) != 'Unknown')
                                  Text('Start: ' + _formatDate(rental.deliveryDate)),
                                if ((rental.orderedByContactName ?? 'Unknown') != 'Unknown')
                                  Row(
                                    children: [
                                      Text('Ask: ${rental.orderedByContactName}', style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: () => _launchDialer(rental.orderedByContactNumber ?? ''),
                                        child: Image.asset(
                                          'assets/calling-off.png',
                                          height: 20,
                                          width: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                if ((rental.siteContactName ?? 'Unknown') != 'Unknown')
                                  Row(
                                    children: [
                                      Text(
                                        'Site: ${rental.siteContactName}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: () => _launchDialer(rental.siteContactNumber ?? ''),
                                        child: Image.asset(
                                          'assets/calling-off.png',
                                          height: 20,
                                          width: 20,
                                        ),
                                      ),
                                    ],
                                  ),

                                // Unified conditional button group
                                ...[
                                  if (rental.status == 'Upcoming') ...[
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () => _handlePhotoUpload(context),
                                      child: Text('Take Photo'),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        File? image = await _pickImage();
                                        if (image != null) {
                                          String serialNumber = serialController.text.trim();
                                          File compressedImage = await compressImage(image);
                                          var apiService = ApiService();
                                          bool success = await apiService.uploadPhoto(
                                            compressedImage,
                                            rental.rentalId,
                                            serialNumber,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success
                                                  ? 'Photo uploaded successfully!'
                                                  : 'Failed to upload photo.'),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(Icons.upload),
                                      label: Text('Upload Photo'),
                                    ),
                                  ] else if (rental.status == 'Called Off') ...[
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () => _handlePickupComplete(context),
                                      child: Text('Complete'),
                                    ),
                                  ]
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
