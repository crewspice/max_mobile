import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

// This widget is the sole target of AI-driven edits from the Developer page's
// "Describe a change" field (see tools/dev_agent/server.js). It must stay a
// plain embeddable widget - no Scaffold/AppBar/MaterialApp - since it's
// rendered inside a fixed-size box on developer_screen.dart, not as its own
// screen. Keep it self-contained; the control panel is never rewritten, so
// the request/patch loop keeps working even if this widget's content changes
// completely.
class DeveloperPlayground extends StatelessWidget {
  const DeveloperPlayground({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.main,
          child: Icon(
            Icons.person,
            size: 40,
            color: AppColors.yellow,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'User Name',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            color: AppColors.yellow,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'AI Pipeline Test v2',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
