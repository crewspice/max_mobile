import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'views/home_screen.dart';
import 'views/user_selection_screen.dart';
import 'views/user_statistics_screen.dart';
import 'theme/app_colors.dart';

// Lets notification-tap handling push routes from outside any widget's own
// BuildContext (the FCM listeners in _RentalAppState aren't under one).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Deep-links a "welcome_back" push straight to the Truck tab, skipping the
// profile picker — the notification already tells us which driver this is,
// since it only ever arrives on that driver's own registered device.
Future<void> _handleWelcomeBackTap(Map<String, dynamic> data) async {
  final driverId = data['driverId'] as String?;
  if (driverId == null || driverId.isEmpty) return;

  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  try {
    final users = await ApiService().fetchUserSelection();
    final match = users.firstWhere(
      (u) => u['initial'] == driverId,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return;

    final truckId = (data['truckId'] as String?) ?? match['truckId']?.toString();
    final maintenanceOnly = match['driver'] != 1;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          currentUserId: driverId,
          userName: match['nickname'] as String? ?? '',
          truckId: truckId,
          maintenanceOnly: maintenanceOnly,
          initialTabIndex: 2,
        ),
      ),
      (route) => false,
    );
  } catch (e) {
    debugPrint('Failed to deep-link welcome_back push: $e');
  }
}

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

  // Let iOS show the native banner/sound even while the app is foregrounded,
  // instead of silently handing the message to onMessage only.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

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

    // Handle notification taps (app was backgrounded, not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.notification?.title}');
      if (message.data['type'] == 'welcome_back') {
        _handleWelcomeBackTap(message.data);
      }
    });

    // Handle app opened from terminated state - the navigator isn't mounted
    // yet inside initState, so wait for the first frame before pushing.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('App opened from push: ${message.notification?.title}');
        if (message.data['type'] == 'welcome_back') {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _handleWelcomeBackTap(message.data),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Rental App',
      theme: ThemeData(colorSchemeSeed: AppColors.yellow),
      home: const UserSelectionScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/statistics': (context) {
          final driverId = ModalRoute.of(context)!.settings.arguments as String;
          return UserStatisticsScreen(driverId: driverId);
        },
      },
    );
  }
}