import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';




class DriverOrbitSelector extends StatefulWidget {
 final List<Map<String, dynamic>> users;




 final Future<void> Function(
   String userId,
   String userName,
   String truckId,
 ) onUserTap;




 final void Function(String userId) onAssignmentTap;




 const DriverOrbitSelector({
   super.key,
   required this.users,
   required this.onUserTap,
   required this.onAssignmentTap,
 });




 @override
 State<DriverOrbitSelector> createState() =>
     _DriverOrbitSelectorState();
}




class _DriverOrbitSelectorState
   extends State<DriverOrbitSelector>
   with SingleTickerProviderStateMixin {
 late final AnimationController orbit;




 @override
 void initState() {
   super.initState();




   orbit = AnimationController(
     vsync: this,
     duration: const Duration(seconds: 65),
   )..repeat();
 }




 @override
 void dispose() {
   orbit.dispose();
   super.dispose();
 }




 @override
 Widget build(BuildContext context) {
   return LayoutBuilder(
     builder: (context, constraints) {
       return AnimatedBuilder(
         animation: orbit,
         builder: (_, __) {
           final centerX = constraints.maxWidth / 2;
           final centerY = constraints.maxHeight / 2;




           final shortestSide =
               MediaQuery.of(context).size.shortestSide;




           final uiScale =
               (shortestSide / 420).clamp(0.85, 1.6);




           final count = widget.users.length;




           // ✅ DEVICE-SAFE ORBIT SIZE (this is the BIG fix)
           final radiusX = constraints.maxWidth * 0.31;
           final radiusY = constraints.maxHeight * 0.28;




           final nodeSizeBase = 110 * uiScale;




           final nodes = <Widget>[];




           for (int i = 0; i < count; i++) {
             final user = widget.users[i];




             final count = widget.users.length;




             final angleStep = (2 * pi) / count;
             const phaseOffset = pi / 2;




             final angle =
                 (i * angleStep) +
                 phaseOffset +
                 (orbit.value * 2 * pi);










             // ✅ soft inward breathing (prevents edge hugging)
             final t =
                 0.88 + (sin(angle * 2) * 0.10);




             final x =
                 centerX + cos(angle) * radiusX * t;




             final y =
                 centerY + sin(angle) * radiusY * t;




             // depth feel (subtle)
             final depth = (sin(angle) + 1) / 2;
             final scale = 0.78 + depth * 0.34;




             final nodeSize = nodeSizeBase * scale;




             nodes.add(
               Positioned(
                 left: x - nodeSize / 2,
                 top: y - nodeSize / 2,
                 child: Transform.scale(
                   scale: scale,
                   child: _DriverNode(
                     user: user,
                     uiScale: uiScale,
                     onTap: () {
                       widget.onUserTap(
                         user['initial'],
                         user['nickname'],
                         user['truckId'].toString(),
                       );
                     },
                     onAssignmentTap: () {
                       widget.onAssignmentTap(
                         user['initial'],
                       );
                     },
                   ),
                 ),
               ),
             );
           }




           return SizedBox(
             width: constraints.maxWidth,
             height: constraints.maxHeight,
             child: Stack(children: nodes),
           );
         },
       );
     },
   );
 }
}




class _DriverNode extends StatelessWidget {
 final Map<String, dynamic> user;
 final double uiScale;




 final VoidCallback onTap;
 final VoidCallback onAssignmentTap;




 const _DriverNode({
   required this.user,
   required this.uiScale,
   required this.onTap,
   required this.onAssignmentTap,
 });




 @override
 Widget build(BuildContext context) {
   final hasRoute =
       user['hasRoute'].toString() == 'true';




   return Material(
     color: Colors.transparent,
     child: InkWell(
       borderRadius: BorderRadius.circular(14),
       onTap: onTap,
       child: ConstrainedBox(
         constraints: BoxConstraints(
           minWidth: 90 * uiScale,
           maxWidth: 180 * uiScale,
         ),
         child: Container(
           padding: const EdgeInsets.symmetric(
             horizontal: 8,
             vertical: 8,
           ),
           decoration: BoxDecoration(
             color: AppColors.main.withOpacity(0.92),
             borderRadius: BorderRadius.circular(14),
             border: Border.all(
               color: hasRoute
                   ? AppColors.green
                   : AppColors.yellow,
               width: 1.2,
             ),
             boxShadow: [
               BoxShadow(
                 blurRadius: 12,
                 color: hasRoute
                     ? AppColors.green.withOpacity(0.15)
                     : AppColors.yellow.withOpacity(0.08),
               )
             ],
           ),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   CircleAvatar(
                     radius: 18 * uiScale,
                     backgroundColor: hasRoute
                         ? AppColors.green
                         : AppColors.mainBackground,
                     child: Text(
                       user['initial'],
                       style: TextStyle(
                         fontSize: 18 * uiScale,
                         fontWeight: FontWeight.bold,
                         color: hasRoute
                             ? AppColors.main
                             : AppColors.yellow,
                       ),
                     ),
                   ),
                   const SizedBox(width: 6),
                   GestureDetector(
                     onTap:
                         hasRoute ? onAssignmentTap : null,
                     child: Opacity(
                       opacity: hasRoute ? 1 : 0.25,
                       child: Image.asset(
                         'assets/assignment.png',
                         width: 34 * uiScale,
                         height: 34 * uiScale,
                         color: hasRoute
                             ? AppColors.green
                             : AppColors.yellow,
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 6),
               Text(
                 user['nickname'],
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 18 * uiScale,
                   fontWeight: FontWeight.w600,
                   color: hasRoute
                       ? AppColors.green
                       : AppColors.yellow,
                 ),
               ),
               const SizedBox(height: 2),
               if (user['truckId'] != null &&
                   user['truckId']
                       .toString()
                       .isNotEmpty)
                 Text(
                   "Truck ${user['truckId']}",
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     fontSize: 13 * uiScale,
                     color: hasRoute
                         ? AppColors.green
                         : AppColors.yellow,
                   ),
                 ),
             ],
           ),
         ),
       ),
     ),
   );
 }
}




