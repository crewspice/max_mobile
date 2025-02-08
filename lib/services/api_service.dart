import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rental.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.5:8080/rentals";

  Future<List<Rental>> fetchRentalsByDriver(String driverId) async {
    print('Fetching rentals for driver ID: $driverId');
    
    final response = await http.get(Uri.parse('$baseUrl/driver/$driverId'));

    if (response.statusCode == 200) {
      print('API Response: ${response.body}');
      
      List<dynamic> data = json.decode(response.body);
      
      print('Decoded Data: $data');
      
      // Map each item to the updated Rental model
      return data.map((item) => Rental.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load rentals');
    }
  }

  Future<void> submitSerialNumber(int rentalId, String serialNumber) async {
    // Add submit logic here
  }
}
