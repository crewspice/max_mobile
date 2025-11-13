import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import '../models/stop.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl = "http://5.78.73.173:8080/rentals";
  final String userUrl = "http://5.78.73.173:8080/user";
  final String routeUrl = "http://5.78.73.173:8080/routes";

  /// Fetch rentals by driver ID
  Future<List<Stop>> fetchStopsByDriver(String driverId) async {
    final response = await http.get(
      Uri.parse("http://5.78.73.173:8080/routes/driver/$driverId")
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> stopsJson = data['stops'] ?? [];

      // Inject driverId into each Stop
      return stopsJson.map((json) {
        final stop = Stop.fromJson(json);
        return Stop(
          id: stop.id,
          orderId: stop.orderId,
          type: stop.type,
          name: stop.name,
          status: stop.status,
          deliveryDate: stop.deliveryDate,
          serviceDate: stop.serviceDate,
          serviceType: stop.serviceType,
          reason: stop.reason,
          siteName: stop.siteName,
          streetAddress: stop.streetAddress,
          city: stop.city,
          liftType: stop.liftType,
          newSiteName: stop.newSiteName,
          newStreetAddress: stop.newStreetAddress,
          newCity: stop.newCity,
          newLiftType: stop.newLiftType,
          time: stop.time,
          orderedByContactName: stop.orderedByContactName,
          orderedByContactPhone: stop.orderedByContactPhone,
          siteContactName: stop.siteContactName,
          siteContactPhone: stop.siteContactPhone,
          locationNotes: stop.locationNotes,
          preTripInstructions: stop.preTripInstructions,
          latitude: stop.latitude,
          longitude: stop.longitude,
          arrivalTime: stop.arrivalTime,
          departedTime: stop.departedTime,
          driverNumber: stop.driverNumber,
          hasPhoto: stop.hasPhoto,
          driverId: driverId, // ✅ Injected here
        );
      }).toList();
    } else {
      throw Exception('Failed to load stops');
    }
  }

    
  /// Upload Photo with Rental ID and optional Serial Number
  Future<bool> uploadPhoto(File imageFile, int rentalId, {String? serialNumber}) async {
    final String uploadUrl = '$baseUrl/recordDeliveryWithPhoto';

    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields['rentalId'] = rentalId.toString();

    if (serialNumber != null && serialNumber.isNotEmpty) {
      request.fields['serialNumber'] = serialNumber;
    }

    String? mimeType = lookupMimeType(imageFile.path);
    var fileStream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    var multipartFile = http.MultipartFile(
      'photoFile',
      fileStream,
      length,
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

  // Record a service with photo
  Future<bool> recordServiceWithPhoto(
    File imageFile,
    int serviceId, {
    String? serialNumber,
  }) async {
    final String url = '$baseUrl/recordServiceWithPhoto';

    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['serviceId'] = serviceId.toString();

    // Only include serialNumber if it exists and is non-empty
    if (serialNumber != null && serialNumber.isNotEmpty) {
      request.fields['serialNumber'] = serialNumber;
    }

    // Add photo file
    request.files.add(
      await http.MultipartFile.fromPath(
        'photoFile', // removed the space
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        print('✅ Service and photo recorded successfully.');
        return true;
      } else {
        final body = await response.stream.bytesToString();
        print('❌ Failed to record service: ${response.statusCode}, body=$body');
        return false;
      }
    } catch (e) {
      print('🔥 Error during service upload: $e');
      return false;
    }
  }

  Future<bool> recordHQReturnById(int hqId) async {
    final String url = '$routeUrl/hq/$hqId';
    print('📡 Preparing to delete HQ stop with ID: $hqId');
    print('🔗 URL: $url'); // <-- print the full URL

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📤 HTTP DELETE sent to $url'); // optional extra debug

      if (response.statusCode == 200) {
        print('✅ HQ stop deleted successfully.');
        return true;
      } else {
        print('❌ Failed to delete HQ stop: ${response.statusCode}');
        print('📄 Response body: ${response.body}'); // optional for debugging
        return false;
      }
    } catch (e) {
      print('🔥 Error during HQ stop deletion: $e');
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
