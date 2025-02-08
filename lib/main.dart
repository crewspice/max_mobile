import 'package:flutter/material.dart';
import 'views/rental_list_view.dart';

void main() {
  runApp(RentalApp(driverId: 'K'));  // Pass the correct driverId ("K")
}

class RentalApp extends StatelessWidget {
  final String driverId;

  const RentalApp({super.key, required this.driverId});  // Accept driverId in constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RentalListView(driverId: driverId),  // Pass driverId to RentalListView
    );
  }
}
