import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';

enum DialogType { error, warning, info }

class AppDialog {
  static void show({
    required String message,
    DialogType type = DialogType.info,
  }) {
    final ctx = AppNavigator.context;
    if (ctx == null) return;

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
      context: ctx,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
