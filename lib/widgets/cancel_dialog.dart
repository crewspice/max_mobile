import 'package:flutter/material.dart';
import '../config/device_config.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/driver_route_status.dart';
import 'hold_to_confirm_button.dart';
import 'ornate_card.dart';
import 'watermark_title.dart';

// The stop-cancellation prompt: an ornate-bordered card styled to match
// InspectionPromptCard, shared by RentalCard and ServiceCard. The title's
// second word ("Delivery" / "Pickup" / "Service") is supplied by the caller
// so the copy matches whichever stop type is being cancelled.
//
// rentalId/driverId are only passed by RentalCard - when present, and only
// once the driver is confirmed on-route (isDriverOnRoute, the same check
// HomeScreen uses to unlock Driver Chat), the dialog shows the rental's
// cancellation fee next to the Close button. ServiceCard's cancellations
// never pass these, so its dialog renders exactly as before.
Future<void> showCancelDialog({
  required BuildContext context,
  required Color color,
  required String stopType,
  required Future<bool> Function(bool onArrival) onCancel,
  required Future<void> Function() onSuccess,
  int? rentalId,
  String? driverId,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _CancelDialogContent(
      outerContext: context,
      color: color,
      stopType: stopType,
      onCancel: onCancel,
      onSuccess: onSuccess,
      rentalId: rentalId,
      driverId: driverId,
    ),
  );
}

class _CancelDialogContent extends StatefulWidget {
  final BuildContext outerContext;
  final Color color;
  final String stopType;
  final Future<bool> Function(bool onArrival) onCancel;
  final Future<void> Function() onSuccess;
  final int? rentalId;
  final String? driverId;

  const _CancelDialogContent({
    required this.outerContext,
    required this.color,
    required this.stopType,
    required this.onCancel,
    required this.onSuccess,
    required this.rentalId,
    required this.driverId,
  });

  @override
  State<_CancelDialogContent> createState() => _CancelDialogContentState();
}

class _CancelDialogContentState extends State<_CancelDialogContent> {
  int _selected = 0;

  // Stays null (fee row hidden) unless the driver turns out to be on-route
  // and a fee resolves - covers "not a driver right now" and "no price for
  // this rental" with the same as-is dialog layout.
  double? _deliveryPrice;

  @override
  void initState() {
    super.initState();
    _loadFeeIfOnRoute();
  }

  Future<void> _loadFeeIfOnRoute() async {
    final rentalId = widget.rentalId;
    if (rentalId == null) return;

    final onRoute = await isDriverOnRoute(widget.driverId);
    if (!onRoute || !mounted) return;

    final price = await ApiService().fetchCancellationFee(rentalId);
    if (!mounted || price == null) return;

    setState(() => _deliveryPrice = price);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    final closeButton = OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.mainBackground,
        side: BorderSide(color: color, width: 1.3),
      ),
      onPressed: () => Navigator.pop(context),
      child: Text("Close", style: TextStyle(color: color)),
    );

    final submitButton = HoldToConfirmButton(
      icon: const Icon(Icons.cancel_schedule_send_outlined),
      label: "Submit",
      baseColor: color,
      progressColor: color,
      textColor: color,
      outlined: true,
      holdDuration: const Duration(seconds: 2),
      onConfirmed: () async {
        final bool onArrival = _selected == 1;

        Navigator.pop(context);

        final success = await widget.onCancel(onArrival);

        ScaffoldMessenger.of(widget.outerContext).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (onArrival
                      ? "Cancelled after arrival"
                      : "Cancelled before arrival")
                  : "Cancellation failed",
            ),
          ),
        );

        if (success) {
          await widget.onSuccess();
        }
      },
    );

    // "After arrival" means the driver already made the trip out, so the
    // delivery's cancellation fee applies; "before arrival" means nothing
    // was delivered yet, so it's $0.
    final feeText = _deliveryPrice == null
        ? null
        : '\$${(_selected == 1 ? _deliveryPrice! : 0.0).toStringAsFixed(2)}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      // submitButton (HoldToConfirmButton) stretches to whatever width its
      // parent allows, which otherwise drags this whole dialog out to the
      // full inset width - fine on phone, but there's no need for it to
      // span iPad's much wider screen.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: DeviceConfig.isIpad
              ? MediaQuery.of(context).size.width * 0.6
              : double.infinity,
        ),
        child: OrnateCard(
          color: color,
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
                    text: "Cancel ${widget.stopType}",
                    glyph: Icons.block,
                    glyphSize: 220,
                    glyphAlignment: const Alignment(0, -0.8),
                    textColor: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Text("Was it", style: TextStyle(color: color)),
                    ToggleButtons(
                      isSelected: [_selected == 0, _selected == 1],
                      onPressed: (index) {
                        setState(() {
                          _selected = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      borderColor: color,
                      selectedBorderColor: color,
                      fillColor: color,
                      selectedColor: AppColors.mainBackground,
                      color: color,
                      constraints: const BoxConstraints(
                        minWidth: 64,
                        minHeight: 30,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("before"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("after"),
                        ),
                      ],
                    ),
                    Text("arrival?", style: TextStyle(color: color)),
                  ],
                ),
                const SizedBox(height: 16),
                submitButton,
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    feeText != null
                        ? Text(
                            feeText,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const SizedBox.shrink(),
                    closeButton,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
