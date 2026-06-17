import 'package:flutter/material.dart';
import 'rental_list_view.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';


class CompletedStopsScreen extends StatelessWidget {
  final String driverId;
  final bool unassigned;

  const CompletedStopsScreen({
    super.key,
    required this.driverId,
    this.unassigned = false,
  });

  @override
  Widget build(BuildContext context) {

    final title = unassigned ? "Unassigned Stops" : "Completed Stops";

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.yellow,
                AppColors.green,
                AppColors.red,
              ],
            ).createShader(bounds);
          },
          child: Text(
            title,
            style: GoogleFonts.permanentMarker(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.5,
            ),
          ),
        ),
        backgroundColor: AppColors.mainBackground,
        foregroundColor: AppColors.yellow,
      ),

      body: RentalListView(
        driverId: driverId,
        completed: !unassigned, // 👈 key swap
        unassigned: unassigned,
      ),
    );
  }
}