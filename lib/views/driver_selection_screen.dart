import 'package:flutter/material.dart';
import 'rental_list_view.dart';

class DriverSelectionScreen extends StatelessWidget {
  const DriverSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const driverMap = {
      'I': 'Isaiah',
      'K': 'Kaleb',
      'A': 'Adrian',
      'JC': 'Jackson',
      'J': 'John',
      'B': 'Byron',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Driver'),
      ),
      body: ListView.builder(
        itemCount: driverMap.length,
        itemBuilder: (context, index) {
          String driverId = driverMap.keys.elementAt(index);
          String driverName = driverMap[driverId]!;

          return ListTile(
            title: Text(driverName),
            onTap: () {
              // Navigate to RentalListView with selected driverId
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RentalListView(driverId: driverId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
