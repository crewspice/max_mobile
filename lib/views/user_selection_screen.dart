import 'dart:io';




import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';




import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/driver_orbit_selector.dart';
import '../widgets/outer_orbit_particles.dart';
import 'home_screen.dart';
import 'rental_list_view.dart';




class UserSelectionScreen extends StatefulWidget {
 const UserSelectionScreen({super.key});




 @override
 State<UserSelectionScreen> createState() =>
     _UserSelectionScreenState();
}




class _UserSelectionScreenState
   extends State<UserSelectionScreen> {
 late Future<List<Map<String, dynamic>>> futureUsers;




 bool _permissionRequested = false;




 @override
 void initState() {
   super.initState();




   // ✅ LOCK THIS SCREEN TO PORTRAIT ONLY
   SystemChrome.setPreferredOrientations([
     DeviceOrientation.portraitUp,
   ]);




   futureUsers = ApiService().fetchUserSelection();




   _loadPermissionFlag();




   FirebaseMessaging.onMessage.listen((message) {
     if (!mounted) return;




     if (message.notification != null) {
       showDialog(
         context: context,
         builder: (_) => AlertDialog(
           backgroundColor: AppColors.mainBackground,
           title: Text(
             message.notification!.title ?? 'Notification',
             style: const TextStyle(
               color: AppColors.yellow,
             ),
           ),
           content: Text(
             message.notification!.body ?? '',
             style: const TextStyle(
               color: AppColors.yellow,
             ),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text(
                 'OK',
                 style: TextStyle(
                   color: AppColors.yellow,
                 ),
               ),
             ),
           ],
         ),
       );
     }
   });
 }




 @override
 void dispose() {
   // ✅ RESTORE FULL ORIENTATION SUPPORT WHEN LEAVING SCREEN
   SystemChrome.setPreferredOrientations([
     DeviceOrientation.portraitUp,
     DeviceOrientation.portraitDown,
     DeviceOrientation.landscapeLeft,
     DeviceOrientation.landscapeRight,
   ]);




   super.dispose();
 }




 Future<void> _loadPermissionFlag() async {
   final prefs = await SharedPreferences.getInstance();




   _permissionRequested =
       prefs.getBool('push_permission_requested') ?? false;
 }




 Future<void> _setPermissionFlag() async {
   final prefs = await SharedPreferences.getInstance();




   await prefs.setBool(
     'push_permission_requested',
     true,
   );




   _permissionRequested = true;
 }




 Future<void> _initPush(String userId) async {
   final messaging = FirebaseMessaging.instance;




   if (!_permissionRequested) {
     await messaging.requestPermission(
       alert: true,
       badge: true,
       sound: true,
     );




     await _setPermissionFlag();
   }




   if (Platform.isIOS) {
     String? apnsToken;




     for (int i = 0; i < 10; i++) {
       apnsToken = await messaging.getAPNSToken();




       if (apnsToken != null) {
         break;
       }




       await Future.delayed(
         const Duration(milliseconds: 500),
       );
     }




     if (apnsToken == null) {
       return;
     }
   }




   final token = await messaging.getToken();




   if (token != null) {
     await ApiService().registerDevice(
       userId,
       token,
     );
   }
 }




 Future<void> _refreshUsers() async {
   setState(() {
     futureUsers = ApiService().fetchUserSelection();
   });
 }




 Future<void> _openUser(
   String userId,
   String userName,
   String truckId,
 ) async {
   await _initPush(userId);




   if (!mounted) return;




   Navigator.pushReplacement(
     context,
     MaterialPageRoute(
       builder: (_) => HomeScreen(
         currentUserId: userId,
         userName: userName,
         truckId: truckId,
       ),
     ),
   );
 }




 void _openAssignments(String userId) {
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (_) => RentalListView(
         driverId: userId,
       ),
     ),
   );
 }




 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: AppColors.mainBackground,
     body: SafeArea(
       child: FutureBuilder<List<Map<String, dynamic>>>(
         future: futureUsers,
         builder: (context, snapshot) {
           if (snapshot.connectionState ==
               ConnectionState.waiting) {
             return const Center(
               child: CircularProgressIndicator(
                 color: AppColors.yellow,
               ),
             );
           }




           if (snapshot.hasError) {
             return Center(
               child: Text(
                 'Error: ${snapshot.error}',
                 style: const TextStyle(
                   color: AppColors.yellow,
                 ),
               ),
             );
           }




           if (!snapshot.hasData ||
               snapshot.data!.isEmpty) {
             return const Center(
               child: Text(
                 'No users available.',
                 style: TextStyle(
                   color: AppColors.yellow,
                 ),
               ),
             );
           }




           return Stack(
             children: [
               const Positioned.fill(
                 child: OuterOrbitParticles(),
               ),




               Positioned(
                 top: 17,
                 left: 0,
                 right: 0,
                 child: Center(
                   child: Text(
                     "PROFILES",
                     style: GoogleFonts.permanentMarker(
                       color: AppColors.mainBackground,
                       fontSize: 34,
                       letterSpacing: 2,
                       shadows: [
                         const Shadow(
                           color: Color(0xAAFFFFFFB8),
                           offset: Offset(0, -2),
                         ),
                         const Shadow(
                           color: Color(0x99FFFFFFB8),
                           offset: Offset(2, -2),
                         ),
                         const Shadow(
                           color: Color(0xAAC8FFE6),
                           offset: Offset(2, 0),
                         ),
                         const Shadow(
                           color: Color(0x99C8FFE6),
                           offset: Offset(2, 2),
                         ),
                         const Shadow(
                           color: Color(0xAAFFC8D6),
                           offset: Offset(0, 2),
                         ),
                         const Shadow(
                           color: Color(0x99FFC8D6),
                           offset: Offset(-2, 2),
                         ),
                         const Shadow(
                           color: Color(0xAAFFFFFFB8),
                           offset: Offset(-2, 0),
                         ),
                         const Shadow(
                           color: Color(0x99FFFFFFB8),
                           offset: Offset(-2, -2),
                         ),
                         const Shadow(
                           color: Color(0x33C8FFE6),
                           blurRadius: 6,
                         ),
                       ],
                     ),
                   ),
                 ),
               ),




               DriverOrbitSelector(
                 users: snapshot.data!,
                 onUserTap: _openUser,
                 onAssignmentTap: _openAssignments,
               ),




               Positioned(
                 bottom: 48,
                 left: 0,
                 right: 0,
                 child: Center(
                   child: IconButton(
                     icon: const Icon(
                       Icons.refresh,
                       color: AppColors.yellow,
                     ),
                     onPressed: _refreshUsers,
                   ),
                 ),
               ),
             ],
           );
         },
       ),
     ),
   );
 }
}
