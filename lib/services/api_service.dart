import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/stop.dart';
import '../models/lift.dart';
import '../models/lift_maintenance_snapshot.dart';
import '../models/lift_pm_history_item.dart';
import '../models/lift_maintenance_history_item.dart';
import '../models/lift_rental_history_item.dart';
import '../models/inventory_item.dart';
import '../models/lift_option.dart';
import '../models/chat_message.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl = "http://5.78.73.173:8080/rentals";
  final String userUrl = "http://5.78.73.173:8080/user";
  final String routeUrl = "http://5.78.73.173:8080/routes";
  final String maintenanceUrl = "http://5.78.73.173:8080/maintenance";
  final String chatUrl = "http://5.78.73.173:8080/driver-chat";

  /// Fetch chat messages. Pass sinceId to get only messages newer than it
  /// (for polling); omit it for the initial page of recent history.
  Future<List<ChatMessage>> fetchChatMessages({int? sinceId}) async {
    final uri = sinceId != null
        ? Uri.parse('$chatUrl/messages?sinceId=$sinceId')
        : Uri.parse('$chatUrl/messages');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load chat messages');
    }

    final List<dynamic> decoded =
        json.decode(utf8.decode(response.bodyBytes));

    return decoded.map((m) => ChatMessage.fromJson(m)).toList();
  }

  Future<void> sendChatMessage({
    required String senderUserId,
    required String senderName,
    required String body,
  }) async {
    final response = await http.post(
      Uri.parse('$chatUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderUserId': senderUserId,
        'senderName': senderName,
        'body': body,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send chat message');
    }
  }

  /// Fetch all driver IDs/initials that have routes (excluding "null")
  Future<List<Map<String, dynamic>>> fetchUserSelection() async {
    final response =
        await http.get(Uri.parse('$userUrl/selection'));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user selection');
    }

    final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));

    return jsonList.cast<Map<String, dynamic>>();
  }
  
  /// Fetch route stops or completed stops by driver ID.
  ///
  /// [asSelf] must only be true when this is the logged-in driver viewing
  /// their own route (not the "what's everyone else up to" summary fetch
  /// that loops over every driver ID) — the API uses it to decide whether
  /// this counts as the driver having "seen" their route.
  Future<List<Stop>> fetchStopsByDriver(
    String driverId, {
    bool completed = false,
    bool unassigned = false,
    bool asSelf = false,
  }) async {

    String endpoint;

    if (completed) {
      endpoint = "$routeUrl/completed/$driverId";
    } else if (unassigned) {
      endpoint = "$routeUrl/stops/unassigned";
    } else {
      endpoint = "$routeUrl/driver/$driverId${asSelf ? '?asSelf=true' : ''}";
    }

    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      List<dynamic> stopsJson = data['stops'] ?? [];

      return stopsJson.map((json) {
        final stop = Stop.fromJson(json);
        return Stop(
          id: stop.id,
          siteId: stop.siteId,
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
          driverId: driverId,
        );
      }).toList();

    } else {
      throw 'No route';
    }
  }

  Future<List<InventoryItem>> fetchInventoryByDriver(String driverId) async {
    final response = await http.get(
      Uri.parse("$routeUrl/driver/$driverId"),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load inventory');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));

    final List<dynamic> inventoryJson = data['inventory'] ?? [];

    return inventoryJson
        .map((json) => InventoryItem.fromJson(json))
        .toList();
  }

  /// Whether the signed-in driver has an active route, and whether their
  /// assigned truck is near the shop (with the truck's own lat/lng so the
  /// caller can compare it against the phone's current location).
  Future<Map<String, dynamic>> fetchShopStatus(String driverId) async {
    final response = await http.get(
      Uri.parse("$routeUrl/driver/$driverId/shop-status"),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load shop status');
    }

    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<bool> recordDeliveryWithPhoto(
    File imageFile,
    int rentalId,
    String serialNumber,
    String truck,
    String driver,
    {String? nullRouteId}
  ) async {
    final String url = routeUrl;

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


  Future<bool> recordPickup(
    int rentalId,
    String truck,
    String driver, {
    int? selectedRentalId,
  }) async {
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
          if (selectedRentalId != null)
            'selectedRentalId': selectedRentalId.toString(),
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
    int? selectedRentalId,
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

    // Which physical lift the driver picked up, for "no preference" sites
    if (selectedRentalId != null) {
      request.fields['selectedRentalId'] = selectedRentalId.toString();
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
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
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

  /// Candidate lifts for a "no preference" Change Out service stop.
  Future<List<LiftOption>> fetchLiftOptionsForService(int serviceId) async {
    final String url = '$baseUrl/proximity-groups/service/$serviceId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => LiftOption.fromJson(e)).toList();
      } else {
        print('❌ Failed to fetch lift options: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🔥 Exception while fetching lift options: $e');
      return [];
    }
  }

  /// Candidate lifts for a "no preference" pickup.
  Future<List<LiftOption>> fetchLiftOptionsForRental(int rentalId) async {
    final String url = '$baseUrl/proximity-groups/rental/$rentalId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => LiftOption.fromJson(e)).toList();
      } else {
        print('❌ Failed to fetch lift options: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🔥 Exception while fetching lift options: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchUserStatistics(
    String userInitial, {
    int? year,
    int? month,
  }) async {

    final String endpoint;

    if (year != null && month != null) {
      endpoint = '$userUrl/stats/month/$year/$month';
    } else {
      endpoint = '$userUrl/stats/current';
    }

    final response = await http.get(Uri.parse(endpoint));

    if (response.statusCode != 200) {
      throw Exception('Failed to load user statistics');
    }

    List<dynamic> statsList =
        jsonDecode(utf8.decode(response.bodyBytes));


    final userData = statsList.firstWhere(
      (item) => item['userInitial'] == userInitial,
      orElse: () => {
        "userName": "",
        "userInitial": userInitial,
        "driveSeconds": 0,
        "driveTotalSeconds": 0,
        "pmChecks": 0,
        "pmTotalChecks": 0,
        "repairs": 0,
        "repairTotal": 0,
      },
    );

    return userData;
  }
    
  Future<bool> updateRentalNotes({
    required int rentalId,
    required String notes,
  }) async {
    print("RAW NOTES: $notes");
    print("JSON BODY: ${jsonEncode({'notes': notes})}");
    print("CODE UNITS: ${notes.codeUnits}");
    final uri = Uri.parse('$baseUrl/$rentalId/notes');

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

  Future<bool> updateServiceNotes({
    required int serviceId,
    required String notes,
  }) async {
    final uri = Uri.parse('$baseUrl/service/$serviceId/notes');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notes': notes,
        }),
      );

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
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Lift.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load lifts');
    }
  }

  Future<void> submitPreventiveMaintenance({
    required int liftId,
    required String completedByInitial,
    bool isAnnualInspection = false,
  }) async {
    final res = await http.post(
      Uri.parse('$maintenanceUrl/pm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'liftId': liftId,
        'completedByInitial': completedByInitial,
        'isAnnualInspection': isAnnualInspection,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to submit PM');
    }
  }

  Future<void> submitMaintenanceAction({
    required int liftId,
    required String notes,
    required String createdByInitial,
    required bool isRepair,
  }) async {
    final res = await http.post(
      Uri.parse('$maintenanceUrl/issue'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'liftId': liftId,
        'notes': notes,
        'createdByInitial': createdByInitial,
        'isRepair': isRepair,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to submit maintenance action');
    }
  }

  Future<LiftMaintenanceSnapshot> fetchLiftMaintenanceSnapshot(int liftId) async {
    final response = await http.get(
      Uri.parse('$maintenanceUrl/snapshot/$liftId'),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(utf8.decode(response.bodyBytes));
      return LiftMaintenanceSnapshot.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load lift maintenance snapshot');
    }
  }

  // Truck inventory only carries a serial number, not a liftId.
  Future<LiftMaintenanceSnapshot?> fetchLiftMaintenanceSnapshotBySerial(
    String serialNumber,
  ) async {
    final response = await http.get(
      Uri.parse('$maintenanceUrl/snapshot/by-serial/$serialNumber'),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(utf8.decode(response.bodyBytes));
      return LiftMaintenanceSnapshot.fromJson(jsonMap);
    } else if (response.statusCode == 404) {
      return null;
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

  /// URL a user's profile picture is served from — may 404 if they haven't
  /// set one, callers should fall back to the default avatar in that case.
  String profilePictureUrl(String initial) {
    return 'http://5.78.73.173:8080/profile/profile_$initial.jpg';
  }

  Future<bool> uploadProfilePicture(String initial, File imageFile) async {
    final uri = Uri.parse('$userUrl/profile-picture');

    var request = http.MultipartRequest('POST', uri)
      ..fields['initial'] = initial;

    request.files.add(await http.MultipartFile.fromPath(
      'photoFile',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        print('Profile picture updated successfully.');
        return true;
      } else {
        print('Failed to update profile picture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      return false;
    }
  }

  Future<bool> hasProfilePicture(String initial) async {
    try {
      final response = await http.get(Uri.parse(profilePictureUrl(initial)));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetProfilePicture(String initial) async {
    final uri = Uri.parse('$userUrl/profile-picture?initial=$initial');

    try {
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        print('Profile picture reset successfully.');
        return true;
      } else {
        print('Failed to reset profile picture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error resetting profile picture: $e');
      return false;
    }
  }

  Future<List<LiftPmHistoryItem>> fetchPmHistory(int liftId) async {
    final response = await http.get(Uri.parse('$maintenanceUrl/pm-history/$liftId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => LiftPmHistoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load PM history');
    }
  }

  // -----------------------------
  // New: Maintenance / issue history
  // -----------------------------
  Future<List<LiftMaintenanceHistoryItem>> fetchMaintenanceHistory(int liftId) async {
    final response =
        await http.get(Uri.parse('$maintenanceUrl/issue-history/$liftId'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      return data
          .map((e) => LiftMaintenanceHistoryItem.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load maintenance history');
    }
  }

  Future<List<LiftRentalHistoryItem>> fetchRentalHistory(int liftId) async {
    final response =
        await http.get(Uri.parse('$maintenanceUrl/rental-history/$liftId'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      return data
          .map((e) => LiftRentalHistoryItem.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load rental history');
    }
  }

  
  Future<void> resolveMaintenanceAction({
    required int actionId,
    required String resolvedByInitial,
    required bool noRepairNeeded,
    required String repairNotes,
  }) async {
    final res = await http.post(
      Uri.parse('$maintenanceUrl/issue/resolve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actionId': actionId,
        'resolvedByInitial': resolvedByInitial,
        'noRepairNeeded': noRepairNeeded,
        'repairNotes': repairNotes,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to resolve maintenance action');
    }
  }

  Future<bool> needsInspection(String truckId) async {
    final url = '$maintenanceUrl/inspections/needs/$truckId';
    print("CALLING: $url");

    final res = await http.get(Uri.parse(url));

    print("STATUS: ${res.statusCode}");
    print("BODY: '${res.body}'");

    return res.body.trim().toLowerCase() == 'true';
  }

  Future<bool> recordIssue({
    required File image,
    required String truckId,
    required String driverId,
    required String description,
  }) async {
    // Fake network delay
    await Future.delayed(const Duration(seconds: 1));

    // Debug logging
    print('recordIssue called');
    print('truckId: $truckId');
    print('driverId: $driverId');
    print('description: $description');
    print('image path: ${image.path}');

    // Always succeed for now
    return true;
  }

  Future<void> updateMaintenanceRepairNotes(
      int actionId,
      String repairNotes,
  ) async {
    final response = await http.put(
      Uri.parse('$maintenanceUrl/repair-notes/$actionId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'repairNotes': repairNotes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update repair notes: ${response.body}',
      );
    }
  }

  Future<bool> recordCancellation({
    required String rentalId,
    required String truck,
    required String driver,
    required String type,
    String? nullRouteId,
  }) async {
    try {
      final uri = Uri.parse('$routeUrl/recordCancellation').replace(
        queryParameters: {
          'rentalId': rentalId,
          'truck': truck,
          'driver': driver,
          'type': type,
          if (nullRouteId != null) 'nullRouteId': nullRouteId,
        },
      );

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      return false;

    } catch (e) {
      return false;
    }
  }

  Future<void> recordTruckInspection({
    required String truckId,
    required String driverId,
  }) async {
    final response = await http.post(
      Uri.parse('$maintenanceUrl/truck-inspections/record'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'truckId': truckId,
        'driverId': driverId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to record truck inspection: ${response.body}',
      );
    }
  }

  Future<bool> recordTruckIssue({
    required File image,
    required String truckId,
    required String driverId,
    required String description,
    String? issueType,
  }) async {
    try {
      final uri = Uri.parse('$maintenanceUrl/recordTruckIssue');

      final request = http.MultipartRequest('POST', uri);

      request.fields['truckId'] = truckId;
      request.fields['driverId'] = driverId;
      request.fields['description'] = description;

      if (issueType != null && issueType.isNotEmpty) {
        request.fields['issueType'] = issueType;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'photoFile',
          image.path,
        ),
      );

      final response = await request.send();

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('recordTruckIssue failed: $e');
      return false;
    }
  }

}
