import 'package:flutter/material.dart';

enum DialogType { error, warning, info }

class AppDialog {
  static void show(
    BuildContext context, {
    required String message,
    DialogType type = DialogType.info,
  }) {
    final title = switch (type) {
      DialogType.error => "Error",
      DialogType.warning => "Warning",
      DialogType.info => "Info",
    };

    final icon = switch (type) {
      DialogType.error => Icons.error_outline,
      DialogType.warning => Icons.warning_amber_rounded,
      DialogType.info => Icons.info_outline,
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
