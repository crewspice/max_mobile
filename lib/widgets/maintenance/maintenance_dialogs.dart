import 'package:flutter/material.dart';
import '../../config/device_config.dart';
import '../../theme/app_colors.dart';
import '../ornate_card.dart';
import '../watermark_title.dart';

// Shared notes-editing dialog styled to match the ornate-card look the
// stop card's own "Edit Notes" dialog (base_card.dart) established - the
// beaded OrnateCard border, a WatermarkTitle instead of a plain title bar,
// and an underline-bordered TextField over the dark app background rather
// than a flat-colored AlertDialog. Used for every notes popup prompted from
// a maintenance card (record repair, record issue, resolution notes) so
// they all read as one consistent dialog style.
Future<String?> showNotesDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  String hintText = 'Enter notes here...',
  Color color = AppColors.yellow,
  IconData glyph = Icons.edit_note,
  bool barrierDismissible = true,
}) async {
  final controller = TextEditingController(text: initialValue);
  final textScale = DeviceConfig.notesDialogTextScale;
  final buttonFontSize = 14.0 * textScale;
  final buttonPadding = DeviceConfig.isIpad
      ? const EdgeInsets.symmetric(horizontal: 24, vertical: 18)
      : null;

  return showDialog<String>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final cancelButton = OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.mainBackground,
          side: BorderSide(color: color, width: 1.3),
          padding: buttonPadding,
        ),
        onPressed: () => Navigator.pop(dialogContext),
        child: Text(
          "Cancel",
          style: TextStyle(color: color, fontSize: buttonFontSize),
        ),
      );

      final saveButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.mainBackground,
          padding: buttonPadding,
        ),
        onPressed: () => Navigator.pop(
          dialogContext,
          controller.text.trim(),
        ),
        child: Text('Save', style: TextStyle(fontSize: buttonFontSize)),
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(dialogContext).unfocus(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DeviceConfig.isIpad
                  ? MediaQuery.of(dialogContext).size.width * 0.6
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
                        text: title,
                        glyph: glyph,
                        glyphSize: 190 * textScale,
                        glyphAlignment: const Alignment(0, -0.6),
                        textColor: color,
                        fontSize: 16 * textScale,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 5,
                      autofocus: true,
                      cursorColor: color,
                      style: TextStyle(
                        color: color,
                        fontSize: 16 * textScale,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: color.withValues(alpha: 0.55),
                          fontSize: 16 * textScale,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: color),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: color,
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
        ),
      );
    },
  );
}

Future<String?> showRepairNotesDialog(
  BuildContext context, {
  required String initialValue,
  Color color = AppColors.red,
}) {
  return showNotesDialog(
    context,
    title: 'Repair Notes',
    initialValue: initialValue,
    hintText: 'Enter repair notes...',
    color: color,
    barrierDismissible: false,
  );
}
