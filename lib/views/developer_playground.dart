import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DeveloperPlayground extends StatelessWidget {
  const DeveloperPlayground({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'AI Pipeline Test v2',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.green,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}