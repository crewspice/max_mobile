import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import '../models/rental.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl = "http://5.78.73.173:8080/rentals";
  final String userUrl = "http://5.78.73.173:8080/user";

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
        contentType: MediaType('image', 'jpeg'),
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

  Future<bool> recordPickup(int rentalId) async {
    final String url = '$baseUrl/recordPickup';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'rentalId': rentalId.toString(),
        },
      );

      if (response.statusCode == 200) {
        print('Pickup recorded successfully.');
        return true;
      } else {
        print('Failed to record pickup: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error during pickup: $e');
      return false;
    }
  }

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

  Future<List<String>> fetchAllUserNames() async {
    final String url = '$userUrl/all-names';
    print('📡 Sending GET request to: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<String> names = data.map((e) => e.toString()).toList();
        print('✅ Parsed names: $names');
        return names;
      } else {
        print('❌ Failed to fetch names: ${response.statusCode}');
        throw Exception('Failed to fetch names');
      }
    } catch (e) {
      print('🔥 Exception while fetching names: $e');
      return [];
    }
  }
}
