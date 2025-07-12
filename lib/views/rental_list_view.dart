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

  Future<void> _refreshRentals() async {
    // Refresh the rental data by calling the API again
    setState(() {
      futureRentals = ApiService().fetchRentalsByDriver(widget.driverId);
    });
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

          return RefreshIndicator(
            onRefresh: _refreshRentals, // Trigger the refresh action here
            child: ListView.builder(
              itemCount: rentals.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RentalCard(
                    rental: rentals[index],
                    serialController: serialControllers[index],
                    onRefresh: _refreshRentals,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
