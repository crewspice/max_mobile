import 'package:flutter/material.dart';
import 'rental_list_view.dart';
import 'maintenance_view.dart';
import 'driver_statistics_screen.dart';
import 'user_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  const HomeScreen({super.key, required this.currentUserId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Map user IDs to full names
  static const Map<String, String> userNames = {
    'JS': 'Jacob',
    'K': 'Kaleb',
    'A': 'Adrian',
    'JC': 'Jackson',
    'J': 'John',
    'B': 'Byron',
  };

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      RentalListView(driverId: widget.currentUserId),
      MaintenanceView(currentUserId: widget.currentUserId),
    ];

    final currentUserName =
        userNames[widget.currentUserId] ?? widget.currentUserId;

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        // Show full name
        backgroundColor: Colors.purple[50],
        title: Text('Welcome, $currentUserName'),

        // Switch user button
        leading: IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Switch user',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const UserSelectionScreen(),
              ),
              (route) => false,
            );
          },
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/statistics',
                arguments: widget.currentUserId,
              );
            },
          ),
        ],
      ),

      // Main body
      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple[50],
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Maintenance',
          ),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
