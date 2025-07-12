import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import '../models/rental.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl = "http://api.maxhighreach.com:8080/rentals";

  /// Fetch rentals by driver ID
  Future<List<Rental>> fetchRentalsByDriver(String driverId) async {
    print('Fetching rentals for driver ID: $driverId');

    final response = await http.get(Uri.parse('$baseUrl/driver/$driverId'));

    if (response.statusCode == 200) {
      print('API Response: ${response.body}');
      
      List<dynamic> data = json.decode(response.body);
      print('Decoded Data: $data');

      return data.map((item) => Rental.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load rentals');
    }
  }
  
  /// Upload Photo with Rental ID and Serial Number
  Future<bool> uploadPhoto(File imageFile, int rentalId, String serialNumber) async {
    final String uploadUrl = '$baseUrl/recordDeliveryWithPhoto';

    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields['rentalId'] = rentalId.toString()
      ..fields['serialNumber'] = serialNumber;

    // Get MIME type for the file
    String? mimeType = lookupMimeType(imageFile.path);
    var fileStream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    var multipartFile = http.MultipartFile(
      'photoFile', fileStream, length,
      filename: basename(imageFile.path),
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    );

    request.files.add(multipartFile);

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        print('Photo uploaded successfully.');
        return true;
      } else {
        print('Failed to upload photo: ${await response.stream.bytesToString()}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<bool> recordDeliveryWithPhoto(File imageFile, int rentalId, String serialNumber) async {
    final String url = '$baseUrl/recordDeliveryWithPhoto';

    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['rentalId'] = rentalId.toString()
      ..fields['serialNumber'] = serialNumber
      ..files.add(await http.MultipartFile.fromPath(
        'photoFile',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), // import 'package:http_parser/http_parser.dart';
      ));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Delivery and photo recorded successfully.');
        return true;
      } else {
        print('Failed to record delivery: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error during upload: $e');
      return false;
    }
  }


  // Method to validate serial number
  Future<bool> validateSerialNumber(String serialNumber) async {
    final String apiUrl = '$baseUrl/validateSerialNumber?serialNumber=$serialNumber';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        print('Serial number is valid');
        return true;
      } else {
        print('Serial number is invalid');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

}
