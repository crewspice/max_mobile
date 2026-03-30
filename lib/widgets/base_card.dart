import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/stop.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../services/api_service.dart';

class BaseCard extends StatelessWidget {
  final Stop stop;
  final List<Widget> extraContent;
  final List<Widget> actionButtons;
  final Future<void> Function() onRefresh;

  const BaseCard({
    Key? key,
    required this.stop,
    this.extraContent = const [],
    this.actionButtons = const [],
    required this.onRefresh, // now required
  }) : super(key: key);


  Future<void> _launchDialer(String phone) async {
    if (phone.trim().isEmpty) return;
    final url = 'tel:$phone';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch dialer for: $phone');
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

  @override
  Widget build(BuildContext context) {
    // 🔹 HQ Card
    // 🔹 HQ Card
    if (stop.liftType == "HQ") {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/shop.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              HoldToConfirmButton(
                icon: const Icon(Icons.check_circle_outline),
                label: "I'm back",
                holdDuration: const Duration(seconds: 1),
                onConfirmed: () async {
                  final api = ApiService();

                  // Show loading indicator
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

                  // Remove loading indicator
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? '✅ HQ stop deleted successfully.'
                        : '❌ Failed to delete HQ stop.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ));

                  // Trigger refresh callback if provided
                  if (success) {
                    await onRefresh();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }


    // 🔹 Normal Stop Card
    return Card(
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
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
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 6),
                    Image.asset(_getServiceIcon(), width: 60, height: 60),
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
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
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
                                      style: const TextStyle(
                                        color: Color(0xFF800020),
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
                                      style: const TextStyle(
                                        color: Color(0xFF800020),
                                        decoration: TextDecoration.none,
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
                                      style: const TextStyle(
                                        color: Color(0xFF800020),
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                if (stop.serialNumber != null && stop.serialNumber!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(
                                          "#${stop.serialNumber}",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.orbitron(
                                            color: Colors.black87,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                    const Text("Ask:",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            child: Text(stop
                                                    .orderedByContactName ??
                                                '')),
                                        if (stop.orderedByContactPhone != null)
                                          Transform.translate(
                                            offset: const Offset(-6, -10),
                                            child: GestureDetector(
                                              onTap: () => _launchDialer(
                                                  stop.orderedByContactPhone!),
                                              child: Image.asset(
                                                'assets/calling-off.png',
                                                width: 28,
                                                height: 28,
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
                                    const Text("Site:",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            child:
                                                Text(stop.siteContactName ?? '')),
                                        if (stop.siteContactPhone != null)
                                          Transform.translate(
                                            offset: const Offset(-6, -10),
                                            child: GestureDetector(
                                              onTap: () => _launchDialer(
                                                  stop.siteContactPhone!),
                                              child: Image.asset(
                                                'assets/calling-off.png',
                                                width: 28,
                                                height: 28,
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
            ...extraContent,
            const SizedBox(height: 10),

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
          ],
        ),
      ),
    );
  }
}
