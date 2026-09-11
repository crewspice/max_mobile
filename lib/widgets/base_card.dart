import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/stop.dart';
import '../models/photo_analysis_score.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hold_to_confirm_button.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../config/device_config.dart';
import 'ornate_card.dart';
import 'watermark_title.dart';

const String _deliveryMarker = '[[DELIVERED]]';

class _NotesSplit {
  final String preDelivery;
  final String postDelivery;
  final bool hasMarker;
  const _NotesSplit(this.preDelivery, this.postDelivery, this.hasMarker);
}

_NotesSplit _splitNotes(String? notes) {
  if (notes == null) return const _NotesSplit('', '', false);
  final idx = notes.indexOf(_deliveryMarker);
  if (idx == -1) return _NotesSplit(notes.trim(), '', false);
  return _NotesSplit(
    notes.substring(0, idx).trim(),
    notes.substring(idx + _deliveryMarker.length).trim(),
    true,
  );
}

class BaseCard extends StatefulWidget {
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

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> {
  // Two-finger long-press toggles siteName/streetAddress/city to rentalId/siteId (dev-only).
  static const _devHoldDuration = Duration(milliseconds: 1500);

  final Set<int> _activePointers = {};
  Timer? _devToggleTimer;
  bool _showDevFields = false;

  // Fetched lazily the first time dev fields are shown for this card - the
  // score endpoint is keyed by rentalId, so this only applies to RENTAL
  // stops (a SERVICE stop's id isn't a rentalId).
  PhotoAnalysisScore? _imageScore;
  bool _imageScoreLoading = false;

  Stop get stop => widget.stop;
  List<Widget> get extraContent => widget.extraContent;
  List<Widget> get actionButtons => widget.actionButtons;
  void Function(Stop updatedStop)? get onNotesUpdated => widget.onNotesUpdated;
  Future<void> Function() get onRefresh => widget.onRefresh;
  bool get completedView => widget.completedView;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    if (_activePointers.length == 2) {
      _devToggleTimer?.cancel();
      _devToggleTimer = Timer(_devHoldDuration, () {
        if (!mounted || _activePointers.length != 2) return;
        setState(() => _showDevFields = !_showDevFields);
        HapticFeedback.mediumImpact();
        if (_showDevFields) _loadImageScore();
      });
    } else {
      _devToggleTimer?.cancel();
    }
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _devToggleTimer?.cancel();
  }

  // iOS "Bold Text" accessibility setting makes Flutter's Text widget
  // silently merge FontWeight.bold onto every style, which fights the
  // hand-tuned Knewave look of the lift type characters. Force it off here,
  // same as lift_selector_panel.dart's _noAccessibilityTextStyling.
  Widget _noAccessibilityTextStyling({required Widget child}) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
        boldText: false,
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _devToggleTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadImageScore() async {
    // Upcoming rentals haven't been delivered yet, so there's no photo to
    // have scored - skip the call rather than fetching a guaranteed 404.
    if (_imageScore != null ||
        _imageScoreLoading ||
        stop.type != "RENTAL" ||
        stop.status == "Upcoming") {
      return;
    }
    _imageScoreLoading = true;
    final result = await ApiService().fetchDeliveryImageScore(stop.id);
    if (!mounted) return;
    setState(() {
      _imageScore = result;
      _imageScoreLoading = false;
    });
  }

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
    final webUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';

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
    final split = _splitNotes(stop.notes);
    final baseStyle = TextStyle(
      fontStyle: FontStyle.italic,
      color: elementColor,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: !split.hasMarker
                ? Text(
                    stop.notes != null && stop.notes!.isNotEmpty
                        ? stop.notes!
                        : "No notes yet",
                    textAlign: TextAlign.center,
                    style: baseStyle,
                  )
                : Text.rich(
                    TextSpan(
                      style: baseStyle,
                      children: [
                        TextSpan(
                          text: "◆ ",
                          style: TextStyle(
                              color: elementColor.withValues(alpha: 0.55)),
                        ),
                        TextSpan(
                          text: "Delivery ",
                          style: TextStyle(
                              color: elementColor.withValues(alpha: 0.55)),
                        ),
                        TextSpan(text: split.preDelivery),
                        TextSpan(
                          text: " ◆",
                          style: TextStyle(
                              color: elementColor.withValues(alpha: 0.55)),
                        ),
                        if (split.postDelivery.isNotEmpty)
                          TextSpan(text: " ${split.postDelivery}"),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          GestureDetector(
            onTap: () async {
              final prefill = [split.preDelivery, split.postDelivery]
                  .where((s) => s.isNotEmpty)
                  .join('\n');
              final controller = TextEditingController(text: prefill);

              final updatedNotes = await showDialog<String>(
                context: context,
                builder: (dialogContext) {
                  final cancelButton = OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.mainBackground,
                      side: BorderSide(color: elementColor, width: 1.3),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: elementColor),
                    ),
                  );

                  final saveButton = ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: elementColor,
                      foregroundColor: AppColors.mainBackground,
                    ),
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      controller.text.trim(),
                    ),
                    child: const Text('Save'),
                  );

                  final buttons = DeviceConfig.isIphone
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            saveButton,
                            const SizedBox(height: 10),
                            cancelButton,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: cancelButton),
                            const SizedBox(width: 10),
                            Expanded(child: saveButton),
                          ],
                        );

                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: DeviceConfig.isIpad
                            ? MediaQuery.of(dialogContext).size.width * 0.6
                            : double.infinity,
                      ),
                      child: OrnateCard(
                        color: elementColor,
                        backgroundColor: AppColors.mainBackground,
                        padding: EdgeInsets.zero,
                        child: Container(
                          color: AppColors.mainBackground,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: WatermarkTitle(
                                  text: "Edit Notes",
                                  glyph: Icons.edit_note,
                                  glyphSize: 190,
                                  glyphAlignment: const Alignment(0, -0.6),
                                  textColor: elementColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: controller,
                                maxLines: 5,
                                autofocus: true,
                                cursorColor: elementColor,
                                style: TextStyle(color: elementColor),
                                decoration: InputDecoration(
                                  hintText: 'Enter notes here...',
                                  hintStyle: TextStyle(
                                    color: elementColor.withValues(alpha: 0.55),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: elementColor),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: elementColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              buttons,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );

              if (updatedNotes == null) return;

              String reconstructed;
              if (!split.hasMarker) {
                reconstructed = updatedNotes;
              } else {
                final boundary = split.preDelivery.length;
                if (updatedNotes.length >= boundary) {
                  final head = updatedNotes.substring(0, boundary);
                  final tail = updatedNotes.substring(boundary).trim();
                  reconstructed =
                      '$head\n$_deliveryMarker${tail.isNotEmpty ? '\n$tail' : ''}';
                } else {
                  reconstructed = '$updatedNotes\n$_deliveryMarker';
                }
              }

              final api = ApiService();

              // stop.driverId is the same "who's doing this" identity every
              // other action in this card (deliver/pickup/cancel) already
              // sends as "driver" - the API resolves it to a contract_edits
              // editor_initials value for the NOTES row this write logs.
              final success = stop.type == "SERVICE"
                  ? await api.updateServiceNotes(
                      serviceId: stop.id,
                      notes: reconstructed,
                      driverId: stop.driverId,
                    )
                  : await api.updateRentalNotes(
                      rentalId: stop.id,
                      notes: reconstructed,
                      driverId: stop.driverId,
                    );

              if (success && onNotesUpdated != null) {
                onNotesUpdated!(
                  stop.copyWith(notes: reconstructed),
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

  // Dev-mode replacement for the contacts column: how the backend's AI
  // photo analysis scored this rental's delivery photo as a future
  // "previous site photo" resource. See ImageService.analyzePhotoAsync.
  Widget _buildImageScoreColumn(Color elementColor) {
    final labelStyle =
        TextStyle(fontWeight: FontWeight.bold, color: elementColor);
    final valueStyle = TextStyle(color: elementColor);

    if (stop.type != "RENTAL") {
      return Text("Photo score:\nN/A (service)",
          style: valueStyle, textAlign: TextAlign.center);
    }

    if (stop.status == "Upcoming") {
      return Text("Photo score:\nNo photo yet",
          style: valueStyle, textAlign: TextAlign.center);
    }

    if (_imageScoreLoading) {
      return Text("Photo score:\nLoading...",
          style: valueStyle, textAlign: TextAlign.center);
    }

    final score = _imageScore;
    if (score == null) {
      return Text("Photo score:\nNot scored yet",
          style: valueStyle, textAlign: TextAlign.center);
    }

    final helpful = score.isHelpfulSiteResource;
    final verdict = helpful == null
        ? score.status ?? 'Unknown'
        : (helpful ? 'Helpful' : 'Not helpful');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Photo score:", style: labelStyle),
        Text(
          score.confidence != null
              ? '$verdict (${score.confidence}%)'
              : verdict,
          style: valueStyle,
        ),
        if ((score.reason ?? '').isNotEmpty)
          Text(
            score.reason!,
            style: valueStyle.copyWith(fontStyle: FontStyle.italic, fontSize: 12),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final Color elementColor = stop.type == "SERVICE"
        ? AppColors.green
        : (stop.status == "Active"
            ? AppColors.green
            : (stop.status == "Upcoming" ? AppColors.yellow : AppColors.red));

    final Color textColor =
        completedView ? Colors.purple.shade50 : Colors.black87;

    final Color iconColor =
        completedView ? Colors.purple.shade50 : Colors.black87;

    final List<Widget> normalExtraContent = extraContent.isEmpty
        ? const []
        : extraContent.sublist(0, extraContent.length - 1);

    final Widget? tray = extraContent.isNotEmpty ? extraContent.last : null;

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
                                color:
                                    success ? AppColors.green : AppColors.red,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    _getServiceIcon(),
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                    color: elementColor,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stop.name != null && stop.name!.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(stop.name!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: elementColor,
                          )),
                      if (_showDevFields)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'PO: ${stop.poNumber ?? "none"}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: elementColor),
                          ),
                        )
                      else if (stop.time != null && stop.time!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            () {
                              final formattedDate = stop.type == "RENTAL"
                                  ? _formatDate(stop.deliveryDate)
                                  : _formatDate(stop.serviceDate);
                              final t = stop.time ?? "";
                              if (t.toLowerCase() == "any")
                                return "Any for $formattedDate";
                              if (t == "8-10")
                                return "$formattedDate, 8am-10am";
                              if (t.toLowerCase() == "asap")
                                return "Asap on $formattedDate";

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
                                if (window != null)
                                  return "$formattedDate, $window";
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
                          _noAccessibilityTextStyling(
                            child: Text(
                              stop.liftType!,
                              style: GoogleFonts.knewave(
                                fontSize: 24,
                                // fontWeight: FontWeight.bold,
                                color: elementColor,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Image.asset(_getServiceIcon(),
                            width: 60, height: 60, color: elementColor),
                        const SizedBox(height: 6),
                        Text(
                          stop.serviceType != null &&
                                  stop.serviceType!.isNotEmpty
                              ? (stop.serviceType == "Service Change Out"
                                  ? "Service\nChange Out"
                                  : stop.serviceType!)
                              : (stop.status == "Upcoming"
                                  ? "Drop Off"
                                  : stop.status == "Called Off"
                                      ? "Pick Up"
                                      : ""),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: elementColor),
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
                                  if (_showDevFields) ...[
                                    Text(
                                      '${stop.type == "SERVICE" ? "Service ID" : "Rental ID"}: ${stop.id}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: elementColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      'Site ID: ${stop.siteId}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: elementColor,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ] else ...[
                                    if (stop.siteName != null &&
                                        stop.siteName!.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          if (stopAddress.isNotEmpty)
                                            _launchMaps(stopAddress);
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
                                    if (stop.streetAddress != null &&
                                        stop.streetAddress!.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          if (stopAddress.isNotEmpty)
                                            _launchMaps(stopAddress);
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
                                    if (stop.city != null &&
                                        stop.city!.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          if (stopAddress.isNotEmpty)
                                            _launchMaps(stopAddress);
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
                                  ],
                                  if (!DeviceConfig.isIphone)
                                    _buildNotesRow(elementColor, context),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Contacts (dev mode: photo usefulness score instead)
                          Expanded(
                            flex: 5,
                            child: _showDevFields
                                ? _buildImageScoreColumn(elementColor)
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (stop.orderedByContactName != null ||
                                    stop.orderedByContactPhone != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Ask:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: elementColor)),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                                child: Text(
                                              stop.orderedByContactName ?? '',
                                              style: TextStyle(
                                                color: elementColor,
                                              ),
                                            )),
                                            if (stop.orderedByContactPhone !=
                                                null)
                                              DeviceConfig.isIpad
                                                  ? Text(
                                                      stop.orderedByContactPhone!,
                                                      style: TextStyle(
                                                        color: elementColor,
                                                      ),
                                                    )
                                                  : Transform.translate(
                                                      offset:
                                                          const Offset(-6, -10),
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            _launchDialer(
                                                          context,
                                                          stop.orderedByContactPhone!,
                                                        ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Site:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: elementColor)),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                                child: Text(
                                              stop.siteContactName ?? '',
                                              style: TextStyle(
                                                color: elementColor,
                                              ),
                                            )),
                                            if (stop.siteContactPhone != null)
                                              DeviceConfig.isIpad
                                                  ? Text(
                                                      stop.siteContactPhone!,
                                                      style: TextStyle(
                                                        color: elementColor,
                                                      ),
                                                    )
                                                  : Transform.translate(
                                                      offset:
                                                          const Offset(-6, -10),
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            _launchDialer(
                                                          context,
                                                          stop.siteContactPhone!,
                                                        ),
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

                if (DeviceConfig.isIphone)
                  _buildNotesRow(elementColor, context),

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
        ],
      ),
    );
  }
}
