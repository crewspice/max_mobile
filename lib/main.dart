import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'views/user_selection_screen.dart';
import 'views/driver_statistics_screen.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background push: ${message.notification?.title} / ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const RentalApp());
}

class RentalApp extends StatefulWidget {
  const RentalApp({super.key});

  @override
  State<RentalApp> createState() => _RentalAppState();
}

class _RentalAppState extends State<RentalApp> {
  @override
  void initState() {
    super.initState();

    // Foreground push notifications (optional logging)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground push: ${message.notification?.title} / ${message.notification?.body}');
      // The system handles heads-up + sound automatically if message.notification is set
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.notification?.title}');
      // Navigate if desired
    });

    // Handle app opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('App opened from push: ${message.notification?.title}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental App',
      theme: ThemeData(primarySwatch: Colors.yellow),
      home: const UserSelectionScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/statistics': (context) {
          final driverId = ModalRoute.of(context)!.settings.arguments as String;
          return DriverStatisticsScreen(driverId: driverId);
        },
      },
    );
  }
}