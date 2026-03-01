import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'rental_list_view.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  static const userMap = {
    'JS': 'Jacob',
    'K': 'Kaleb',
    'A': 'Adrian',
    'JC': 'Jackson',
    'J': 'John',
    'B': 'Byron',
  };

  late Future<List<String>> futureUsersWithRoutes;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    futureUsersWithRoutes = ApiService().fetchDriversWithRoutes();
    _loadPermissionFlag();

    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification!.title ?? 'Notification'),
            content: Text(message.notification!.body ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _loadPermissionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _permissionRequested = prefs.getBool('push_permission_requested') ?? false;
  }

  Future<void> _setPermissionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_permission_requested', true);
    _permissionRequested = true;
  }

  Future<void> _initPush(String userId) async {
    final messaging = FirebaseMessaging.instance;

    // Only request permission once ever
    if (!_permissionRequested) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _setPermissionFlag();

      debugPrint('Push permission settings: $settings');
    }

    // Get FCM token
    final token = await messaging.getToken();
    debugPrint('FCM token for $userId = $token');

    if (token != null) {
      // Register/move device token to this user
      await ApiService().registerDevice(userId, token);
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      futureUsersWithRoutes = ApiService().fetchDriversWithRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: FutureBuilder<List<String>>(
        future: futureUsersWithRoutes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No users available.'));
          }

          final usersWithRoutes = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView.builder(
              itemCount: userMap.length,
              itemBuilder: (context, index) {
                final userId = userMap.keys.elementAt(index);
                final userName = userMap[userId]!;
                final hasRoute = usersWithRoutes.contains(userId);

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(userId),
                    backgroundColor: hasRoute ? Colors.green : Colors.grey,
                  ),
                  title: Text(userName),
                  trailing: hasRoute
                      ? IconButton(
                          icon: Image.asset(
                            'assets/assignment.png',
                            width: 26,
                            height: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RentalListView(driverId: userId),
                              ),
                            );
                          },
                        )
                      : null,
                  onTap: () async {
                    // Register/move device token
                    await _initPush(userId);

                    // Navigate to home screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(currentUserId: userId),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}