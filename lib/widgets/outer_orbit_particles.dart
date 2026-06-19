import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';




class OuterOrbitParticles extends StatefulWidget {
 const OuterOrbitParticles({
   super.key,
   this.particleCount = 720,
 });




 final int particleCount;




 @override
 State<OuterOrbitParticles> createState() =>
     _OuterOrbitParticlesState();
}




class _OuterOrbitParticlesState
   extends State<OuterOrbitParticles>
   with SingleTickerProviderStateMixin {
 late final AnimationController _controller;
 late final List<_Particle> particles;




 final Random _random = Random();




 @override
 void initState() {
   super.initState();




   double velocityAt(double angle) {
     final vertical = sin(angle);
     final normalized = (vertical + 1) / 2;
     final topBias = pow(1 - normalized, 2.2).toDouble();
     return 0.12 + (1 - topBias) * 2.6;
   }




   double equilibriumWeight(double v) {
     return pow(1.0 / v, 12.4).toDouble();
   }




   double pickAngle() {
     const correctionStrength = 0.90;




     while (true) {
       final a = _random.nextDouble() * pi * 2;
       final v = velocityAt(a);
       final eqWeight = equilibriumWeight(v);




       final eqProb = (eqWeight / 4.0).clamp(0.0, 1.0);




       final uniformProb = 0.5;
       final mixedProb =
           (uniformProb * (1 - correctionStrength)) +
           (eqProb * correctionStrength);




       if (_random.nextDouble() < mixedProb) {
         return a;
       }
     }
   }




   particles = List.generate(widget.particleCount, (_) {
     return _Particle(
       angle: pickAngle(),
       radius: 0.85 + _random.nextDouble() * 0.25,
       size: 2 + _random.nextDouble() * 30,
       baseSpeed: 0.8 + _random.nextDouble() * 1.2,
       velocity: 1.0,
     );
   });




   _controller = AnimationController(
     vsync: this,
     duration: const Duration(seconds: 60),
   )..repeat();
 }




 @override
 void dispose() {
   _controller.dispose();
   super.dispose();
 }




 Color _particleColor(
   double x,
   double centerX,
   double maxRadius,
 ) {
   final normalized =
       ((x - centerX) / maxRadius).clamp(-1.0, 1.0);




   if (normalized < 0) {
     return Color.lerp(
       AppColors.yellow,
       AppColors.green,
       normalized + 1,
     )!;
   }




   return Color.lerp(
     AppColors.green,
     AppColors.red,
     normalized,
   )!;
 }




 double _lerpDouble(double a, double b, double t) {
   return a + (b - a) * t;
 }




 @override
 Widget build(BuildContext context) {
   return IgnorePointer(
     child: AnimatedBuilder(
       animation: _controller,
       builder: (context, child) {
         return LayoutBuilder(
           builder: (context, constraints) {
             final width = constraints.maxWidth;
             final height = constraints.maxHeight;




             final centerX = width / 2;
             final centerY = height / 2;




             final shortest = min(width, height);
             final longest = max(width, height);




             /// 🔥 DEVICE NORMALIZED BASE RADIUS
             // iphones
             // final baseRadius = shortest * 0.645;


             // ipads
             final baseRadius = shortest * 0.465;


             /// 🔥 ASPECT RATIO CORRECTION
             final aspect = width / height;




             final radiusX = baseRadius * (aspect >= 1 ? 3.0 : 2.6);
             final radiusY = baseRadius * (aspect <= 1 ? 1.25 : 0.95);




             const dt = 0.016;
             const globalSpeedFactor = 0.03;




             for (final p in particles) {
               final vertical = sin(p.angle);
               final normalized = (vertical + 1) / 2;




               final topBias =
                   pow(1 - normalized, 2.2).toDouble();




               final targetVelocity =
                   0.12 + (1 - topBias) * 2.6;




               p.velocity = _lerpDouble(
                 p.velocity,
                 targetVelocity,
                 0.08,
               );




               p.angle +=
                   p.velocity *
                   p.baseSpeed *
                   dt *
                   globalSpeedFactor;
             }




             return Stack(
               children: particles.map((p) {
                 /// 🔥 normalized orbit instead of hardcoded multipliers
                 final orbitRadiusX =
                     radiusX * (0.85 + p.radius * 0.25);




                 final orbitRadiusY =
                     radiusY * (0.85 + p.radius * 0.25);




                 final x =
                     centerX + cos(p.angle) * orbitRadiusX;




                 final y =
                     centerY + sin(p.angle) * orbitRadiusY;




                 return Positioned(
                   left: x,
                   top: y,
                   child: Container(
                     width: p.size,
                     height: p.size,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: _particleColor(
                         x,
                         centerX,
                         baseRadius,
                       ),
                     ),
                   ),
                 );
               }).toList(),
             );
           },
         );
       },
     ),
   );
 }
}




class _Particle {
 double angle;
 double velocity;




 final double radius;
 final double size;
 final double baseSpeed;




 _Particle({
   required this.angle,
   required this.velocity,
   required this.radius,
   required this.size,
   required this.baseSpeed,
 });
}
