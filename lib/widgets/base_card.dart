import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/stop.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class BaseCard extends StatelessWidget {
  final Stop stop;
  final List<Widget> extraContent;
  final List<Widget> actionButtons;
  final void Function(Stop updatedStop)? onNotesUpdated;
  final Future<void> Function() onRefresh;
  final bool completedView;

  const BaseCard({
    Key? key,
    required this.stop,
    this.extraContent = const [],
    this.actionButtons = const [],
    required this.onRefresh,
    this.onNotesUpdated,
    this.completedView = false,
  }) : super(key: key);

  Future<void> _launchDialer(BuildContext context, String phone) async {
    if (phone.trim().isEmpty) return;

    final url = 'tel:$phone';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('Could not launch dialer for: $phone');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call: $phone'),
        ),
      );
    }
  }

  Future<void> _launchMaps(String query) async {
    if (query.trim().isEmpty) return;

    final geoUrl = 'geo:0,0?q=${Uri.encodeComponent(query)}';
    final webUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';

    // Try geo: first (direct Maps app)
    if (await canLaunchUrlString(geoUrl)) {
      await launchUrlString(geoUrl, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to web URL
    if (await canLaunchUrlString(webUrl)) {
      await launchUrlString(webUrl, mode: LaunchMode.externalApplication);
      return;
    }

    debugPrint('No app or browser available to launch maps for: $query');
  }

  Future<void> _launchHQMaps() async {
    await _launchMaps(
      "5455 Dahlia St, Commerce City, CO",
    );
  }

  String get stopAddress {
    final parts = [
      stop.streetAddress,
      stop.city,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
    return parts;
  }

  String _getServiceIcon() {
    if (stop.liftType == "HQ") return 'assets/shop.png';

    if (stop.serviceType == null || stop.serviceType!.isEmpty) {
      if (stop.status == "Upcoming") return 'assets/dropping-off.png';
      if (stop.status == "Called Off") return 'assets/picking-up.png';
      if (stop.status == "Active") return 'assets/active.png';
      return 'assets/calling-off.png';
    }

    switch (stop.serviceType) {
      case "Change Out":
        return 'assets/changing-out.png';
      case "Service":
        return 'assets/servicing.png';
      case "Service Change Out":
        return 'assets/service-changing-out.png';
      case "Move":
        return 'assets/moving.png';
      default:
        return 'assets/calling-off.png';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      DateTime date = DateTime.parse(dateString);
      String day = DateFormat('d').format(date);
      String month = DateFormat('MMM').format(date);

      int dayNumber = int.parse(day);
      String suffix;
      if (dayNumber >= 11 && dayNumber <= 13) {
        suffix = 'th';
      } else {
        switch (dayNumber % 10) {
          case 1:
            suffix = 'st';
            break;
          case 2:
            suffix = 'nd';
            break;
          case 3:
            suffix = 'rd';
            break;
          default:
            suffix = 'th';
        }
      }

      return '$month $day$suffix';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildNotesRow(Color elementColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stop.notes != null && stop.notes!.isNotEmpty
                  ? stop.notes!
                  : "No notes yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: elementColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final controller =
                  TextEditingController(text: stop.notes ?? "");

              final updatedNotes = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: elementColor,
                    title: const Text(
                      "Edit Notes",
                      style: TextStyle(color: AppColors.main),
                    ),
                    content: TextField(
                      controller: controller,
                      maxLines: 5,
                      autofocus: true,
                      cursorColor: AppColors.main,
                      style: const TextStyle(
                        color: AppColors.main,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter notes here...',
                        hintStyle: TextStyle(color: AppColors.main),

                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.main),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.main,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.main),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.main,
                          foregroundColor: elementColor,
                        ),
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );

              if (updatedNotes == null) return;

              final api = ApiService();

              final success = stop.type == "SERVICE"
                  ? await api.updateServiceNotes(
                      serviceId: stop.id,
                      notes: updatedNotes,
                    )
                  : await api.updateRentalNotes(
                      rentalItemId: stop.id,
                      notes: updatedNotes,
                    );

              if (success && onNotesUpdated != null) {
                onNotesUpdated!(
                  stop.copyWith(notes: updatedNotes),
                );
              }
            },
            child: Image.asset(
              "assets/notes.png",
              width: 20,
              height: 20,
              color: elementColor,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

  final Color elementColor =
      stop.type == "SERVICE"
          ? AppColors.green
          : (stop.status == "Active"
              ? AppColors.green
              : (stop.status == "Upcoming"
                  ? AppColors.yellow
                  : AppColors.red));

  final Color textColor =
      completedView ? Colors.purple.shade50 : Colors.black87;

  final Color iconColor =
      completedView ? Colors.purple.shade50 : Colors.black87;

  final List<Widget> normalExtraContent =
    extraContent.isEmpty
        ? const []
        : extraContent.sublist(0, extraContent.length - 1);

  final Widget? tray =
    extraContent.isNotEmpty ? extraContent.last : null;

    if (stop.liftType == "HQ") {
      return Card(
        color: AppColors.mainBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _launchHQMaps,
                child: Image.asset(
                  'assets/shop.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  color: AppColors.green,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              if (!completedView) ...[
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: HoldToConfirmButton(
                    outlined: true,
                    icon: const Icon(Icons.check_circle_outline),
                    label: "I'm back",
                    baseColor: AppColors.green,
                    textColor: AppColors.green,
                    progressColor: AppColors.yellow,
                    holdDuration: const Duration(seconds: 2),
                    onConfirmed: () async {
                      final api = ApiService();

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      final success = await api.recordHQReturn(
                        stop.id,
                        stop.truck ?? "null",
                        stop.driverId ?? "null",
                      );

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.mainBackground,
                          content: Text(
                            success
                                ? 'HQ stop deleted successfully.'
                                : 'Failed to delete HQ stop.',
                            style: TextStyle(
                              color: success ? AppColors.green : AppColors.red,
                            ),
                          ),
                        ),
                      );

                      if (success) {
                        await onRefresh();
                      }
                    },
                  ),
                ),
              )
              ],
            ],
          ),
        ),
      );
    }


    // 🔹 Normal Stop Card
    return Card(
      color: AppColors.mainBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stop.name != null && stop.name!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stop.name!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: elementColor,
                    )
                  ),
                  if (stop.time != null && stop.time!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        () {
                          final formattedDate = stop.type == "RENTAL"
                              ? _formatDate(stop.deliveryDate)
                              : _formatDate(stop.serviceDate);
                          final t = stop.time ?? "";
                          if (t.toLowerCase() == "any") return "Any for $formattedDate";
                          if (t == "8-10") return "$formattedDate, 8am-10am";
                          if (t.toLowerCase() == "asap") return "Asap on $formattedDate";

                          final startHour = int.tryParse(t);
                          if (startHour != null) {
                            const windows = {
                              7: "7am - 9am",
                              8: "8am - 10am",
                              9: "9am - 11am",
                              10: "10am - 12pm",
                              11: "11am - 1pm",
                              12: "12pm - 2pm",
                              1: "1pm - 3pm",
                              2: "2pm - 4pm",
                              3: "3pm - 5pm",
                              4: "4pm - 6pm",
                            };
                            final window = windows[startHour];
                            if (window != null) return "$formattedDate, $window";
                          }

                          return "$formattedDate at $t";
                        }(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: elementColor),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),

            // Main Row: lift + addresses/contacts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (stop.liftType != null && stop.liftType!.isNotEmpty)
                      Text(
                        stop.liftType!,
                        style: GoogleFonts.knewave(
                          fontSize: 24,
                          // fontWeight: FontWeight.bold,
                          color: elementColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Image.asset(_getServiceIcon(), width: 60, height: 60, color: elementColor),
                    const SizedBox(height: 6),
                    Text(
                      stop.serviceType != null && stop.serviceType!.isNotEmpty
                          ? (stop.serviceType == "Service Change Out"
                              ? "Service\nChange Out"
                              : stop.serviceType!)
                          : (stop.status == "Upcoming"
                              ? "Drop Off"
                              : stop.status == "Called Off"
                                  ? "Pick Up"
                                  : ""),
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500, color: elementColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Addresses
                      Expanded(
                        flex: 7,
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (stop.siteName != null && stop.siteName!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      if (stopAddress.isNotEmpty) _launchMaps(stopAddress);
                                    },
                                    child: Text(
                                      stop.siteName!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: elementColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                if (stop.streetAddress != null && stop.streetAddress!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      if (stopAddress.isNotEmpty) _launchMaps(stopAddress);
                                    },
                                    child: Text(
                                      stop.streetAddress!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: elementColor,
                                        decoration: TextDecoration.none,

                                        // fontSize: 14,
                                        // fontWeight: FontWeight.w700,

                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 3,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (stop.city != null && stop.city!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      if (stopAddress.isNotEmpty) _launchMaps(stopAddress);
                                    },
                                    child: Text(
                                      stop.city!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: elementColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                _buildNotesRow(elementColor, context),
                              ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),


                      // Contacts
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (stop.orderedByContactName != null ||
                                stop.orderedByContactPhone != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Ask:",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: elementColor)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            child:
                                              Text(
                                                stop.orderedByContactName ?? '',
                                                style: TextStyle(
                                                  color: elementColor,
                                                ),
                                              )), 
                                        if (stop.orderedByContactPhone != null)
                                          Transform.translate(
                                            offset: const Offset(-6, -10),
                                            child: GestureDetector(
                                              onTap: () => _launchDialer(
                                                  context,
                                                  stop.orderedByContactPhone!,),
                                              child: Image.asset(
                                                'assets/calling-off.png',
                                                width: 28,
                                                height: 28,
                                                color: elementColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            if (stop.siteContactName != null ||
                                stop.siteContactPhone != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Site:",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: elementColor)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            child:
                                              Text(
                                                stop.siteContactName ?? '',
                                                style: TextStyle(
                                                  color: elementColor,
                                                ),
                                              )), 
                                        if (stop.siteContactPhone != null)
                                          Transform.translate(
                                            offset: const Offset(-6, -10),
                                            child: GestureDetector(
                                              onTap: () => _launchDialer(
                                                  context,
                                                  stop.siteContactPhone!,),
                                              child: Image.asset(
                                                'assets/calling-off.png',
                                                width: 28,
                                                height: 28,
                                                color: elementColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Extra content

            if (actionButtons.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: actionButtons
                    .map((btn) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: btn,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 10),

            ...normalExtraContent,


              if (tray != null) ...[
              const SizedBox(height: 0),
              tray,
            ],
          ],
        ),
      ),
    );
  }
}
