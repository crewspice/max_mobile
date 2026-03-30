import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import '../models/stop.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_snapshot.dart';
import '../models/lift_pm_history_item.dart';
import '../models/lift_maintenance_history_item.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl = "http://5.78.73.173:8080/rentals";
  final String userUrl = "http://5.78.73.173:8080/user";
  final String routeUrl = "http://5.78.73.173:8080/routes";
  final String maintenanceUrl = "http://5.78.73.173:8080/maintenance";

  /// Fetch all driver IDs/initials that have routes (excluding "null")
  Future<List<String>> fetchDriversWithRoutes() async {
    final response = await http.get(Uri.parse('$routeUrl/drivers'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      // Ensure we return a list of strings
      return jsonList.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to fetch drivers with routes');
    }
  }

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
          serialNumber: stop.serialNumber,
          newSiteName: stop.newSiteName,
          newStreetAddress: stop.newStreetAddress,
          newCity: stop.newCity,
          newLiftType: stop.newLiftType,
          time: stop.time,
          orderedByContactName: stop.orderedByContactName,
          orderedByContactPhone: stop.orderedByContactPhone,
          siteContactName: stop.siteContactName,
          siteContactPhone: stop.siteContactPhone,
          notes: stop.notes,
          latitude: stop.latitude,
          longitude: stop.longitude,
          arrivalTime: stop.arrivalTime,
          departedTime: stop.departedTime,
          driverNumber: stop.driverNumber,
          truck: stop.truck,
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


  Future<bool> recordDeliveryWithPhoto(
    File imageFile,
    int rentalId,
    String serialNumber,
    String truck,
    String driver,
    {String? nullRouteId}
  ) async {
    final String url = '$routeUrl/recordDeliveryWithPhoto';

    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['rentalId'] = rentalId.toString()
      ..fields['serialNumber'] = serialNumber
      ..fields['truck'] = truck
      ..fields['driver'] = driver;

    // Only send nullRouteId if it actually exists (same as pickup)
    if (nullRouteId != null) {
      request.fields['nullRouteId'] = nullRouteId;
    }

    request.files.add(await http.MultipartFile.fromPath(
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
      print('Error during delivery upload: $e');
      return false;
    }
  }


  Future<bool> recordPickup(int rentalId, String truck, String driver) async {
    final String url = '$routeUrl/recordPickup';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'rentalId': rentalId.toString(),
          'truck': truck,
          'driver': driver,
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


  Future<bool> recordServiceWithPhoto(
    File imageFile,
    int serviceId,
    String truck,
    String driver, {
    String? serialNumber,
  }) async {
    final String url = '$routeUrl/recordServiceWithPhoto';

    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['serviceId'] = serviceId.toString()
      ..fields['truck'] = truck
      ..fields['driver'] = driver;

    // Optional serial number
    if (serialNumber != null && serialNumber.isNotEmpty) {
      request.fields['serialNumber'] = serialNumber;
    }

    // Add photo file
    request.files.add(
      await http.MultipartFile.fromPath(
        'photoFile',
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

  Future<bool> recordHQReturn(int hqId, String truck, String driver) async {
    final String url = '$routeUrl/hqComplete';

    print('📡 Preparing to record HQ return with ID: $hqId');
    print('🔗 URL: $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'hqId': hqId.toString(),
          'truck': truck,
          'driver': driver,
        },
      );

      print('📤 HTTP POST sent to $url');

      if (response.statusCode == 200) {
        print('✅ HQ return recorded successfully.');
        return true;
      } else {
        print('❌ Failed to record HQ return: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('🔥 Error during HQ return: $e');
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

  Future<Map<String, dynamic>> fetchDriverStatistics(String driverId) async {
    final response = await http.get(Uri.parse('$userUrl/driver-stats'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load driver statistics');
    }

    List<dynamic> statsList = jsonDecode(response.body);

    // Find stats for the selected driver
    final driverData = statsList.firstWhere(
      (item) => item['driver'] == driverId,
      orElse: () => {"driver": driverId, "driverSeconds": 0, "monthTotalSeconds": 0},
    );

    return driverData;
  }
  
  Future<bool> updateRentalNotes({
    required int rentalItemId,
    required String notes,
  }) async {
    final uri = Uri.parse('$baseUrl/$rentalItemId/notes');

    print('➡️ SENDING REQUEST');
    print('URL: $uri');
    print('BODY: $notes');

    try {
      final response = await http.put( // or patch
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notes': notes,
        }),
      );

      print('⬅️ RESPONSE STATUS: ${response.statusCode}');
      print('⬅️ RESPONSE BODY: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ HTTP ERROR: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchMaintenanceLifts() async {
    final res = await http.get(Uri.parse('$maintenanceUrl/lifts'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load lifts');
    }

    return jsonDecode(res.body);
  }

  Future<List<Lift>> fetchLifts() async {
    final response =
        await http.get(Uri.parse('http://5.78.73.173:8080/maintenance/lifts'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Lift.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load lifts');
    }
  }


  Future<void> submitPreventiveMaintenance({
    required int liftId,
    required String completedByInitial,
  }) async {
    final res = await http.post(
      Uri.parse('$maintenanceUrl/pm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'liftId': liftId,
        'completedByInitial': completedByInitial,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to submit PM');
    }
  }

  Future<void> submitMaintenanceIssue({
    required int liftId,
    required String notes,
    required String createdByInitial,
  }) async {
    final res = await http.post(
      Uri.parse('$maintenanceUrl/issue'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'liftId': liftId,
        'notes': notes,
        'createdByInitial': createdByInitial,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to submit maintenance issue');
    }
  }

  Future<LiftMaintenanceSnapshot> fetchLiftMaintenanceSnapshot(int liftId) async {
    final response = await http.get(
      Uri.parse('$maintenanceUrl/snapshot/$liftId'),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      return LiftMaintenanceSnapshot.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load lift maintenance snapshot');
    }
  }

  Future<void> registerDevice(String userId, String token) async {
    await http.post(
      Uri.parse('$userUrl/register-device'),
      body: {
        'userId': userId,
        'token': token,
      },
    );
  }

  Future<List<LiftPmHistoryItem>> fetchPmHistory(int liftId) async {
    final response = await http.get(Uri.parse('$maintenanceUrl/pm-history/$liftId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => LiftPmHistoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load PM history');
    }
  }

  // -----------------------------
  // New: Maintenance / issue history
  // -----------------------------
  Future<List<LiftMaintenanceHistoryItem>> fetchMaintenanceHistory(int liftId) async {
    final response = await http.get(Uri.parse('$maintenanceUrl/issue-history/$liftId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => LiftMaintenanceHistoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load maintenance history');
    }
  }
  
  Future<void> resolveMaintenanceAction({
    required int actionId,
    required String resolvedByInitial,
  }) async {
    final res = await http.post(
      Uri.parse('$maintenanceUrl/issue/resolve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actionId': actionId,
        'resolvedByInitial': resolvedByInitial,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to resolve maintenance action');
    }
  }
  
}
