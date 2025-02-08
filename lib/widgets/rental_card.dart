import 'package:flutter/material.dart';
import '../models/rental.dart';

class RentalCard extends StatelessWidget {
  final Rental rental;
  final TextEditingController serialController;
  final Function(int, String) onSubmitSerial;

  const RentalCard({
    super.key,
    required this.rental,
    required this.serialController,
    required this.onSubmitSerial,
  });

  String _mapLiftType(String? liftType) {
    if (liftType == '<19S') return '19s';
    return liftType ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.all(8.0),
        title: Row(
          children: [
            Column(
              children: [
                Image.asset(
                  rental.status == 'Upcoming'
                      ? 'assets/dropping-off.png'
                      : 'assets/picking-up.png',
                  height: 68,
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    _mapLiftType(rental.liftType),
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rental.customer ?? 'Unknown'),
                  SizedBox(height: 8),
                  Text('Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(rental.siteName ?? 'Unknown'),
                  Text(rental.streetAddress ?? 'Unknown'),
                  Text(rental.city ?? 'Unknown'),
                  if (rental.status == 'Upcoming') ...[
                    SizedBox(height: 10),
                    TextField(
                      controller: serialController,
                      decoration: InputDecoration(
                        labelText: 'Enter Serial Number',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        String serialNumber = serialController.text.trim();
                        if (serialNumber.isNotEmpty) {
                          onSubmitSerial(rental.rentalId, serialNumber);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Serial number cannot be empty.'),
                            ),
                          );
                        }
                      },
                      child: Text('Submit Serial Number'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
