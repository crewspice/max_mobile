import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/rental.dart';
import '../widgets/rental_card.dart';

class RentalListView extends StatefulWidget {
  final String driverId;

  const RentalListView({super.key, required this.driverId});

  @override
  _RentalListViewState createState() => _RentalListViewState();
}

class _RentalListViewState extends State<RentalListView> {
  late Future<List<Rental>> futureRentals;
  late List<TextEditingController> serialControllers;

  @override
  void initState() {
    super.initState();
    futureRentals = ApiService().fetchRentalsByDriver(widget.driverId);
  }

  @override
  void dispose() {
    for (var controller in serialControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void submitSerialNumber(int rentalId, String serialNumber) async {
    try {
      await ApiService().submitSerialNumber(rentalId, serialNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serial number submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit serial number: $e')),
      );
    }
  }

  String _mapDriverId(String driverId) {
    const driverMap = {
      'I': 'Isaiah',
      'K': 'Kaleb',
      'A': 'Adrian',
      'JC': 'Jackson',
      'J': 'John',
      'B': 'Byron',
    };
    return driverMap[driverId] ?? driverId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks for: ${_mapDriverId(widget.driverId)}"),
      ),
      body: FutureBuilder<List<Rental>>(
        future: futureRentals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No rentals available.'));
          }

          List<Rental> rentals = snapshot.data!;
          serialControllers = List.generate(rentals.length, (index) => TextEditingController());

          return ListView.builder(
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: RentalCard(
                  rental: rentals[index],
                  serialController: serialControllers[index],
                  onSubmitSerial: submitSerialNumber,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
