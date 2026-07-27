import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

Future<String?> showRepairNotesDialog(
  BuildContext context, {
  required String initialValue,
  Color color = AppColors.red,
}) async {
  final controller = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: color,
      title: const Text(
        'Repair Notes',
        style: TextStyle(color: AppColors.main),
      ),
      content: TextField(
        controller: controller,
        maxLines: 5,
        autofocus: true,
        cursorColor: AppColors.main,
        style: const TextStyle(color: AppColors.main),
        decoration: const InputDecoration(
          hintText: 'Enter repair notes...',
          hintStyle: TextStyle(color: AppColors.main),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.main),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.main, width: 2),
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
            foregroundColor: color,
          ),
          onPressed: () =>
              Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}