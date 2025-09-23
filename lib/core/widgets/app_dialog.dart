import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';

enum DialogType { error, warning, info, success }

class AppDialog {
  /// Popup Dialog
  static void show({
    required String message,
    DialogType type = DialogType.info,
  }) {
    final ctx = AppNavigator.context;
    if (ctx == null) return;

    final title = switch (type) {
      DialogType.error => "Error",
      DialogType.warning => "Warning",
      DialogType.success => "Success",
      DialogType.info => "Info",
    };

    final icon = switch (type) {
      DialogType.error => Icons.error_outline,
      DialogType.warning => Icons.warning_amber_rounded,
      DialogType.success => Icons.check_circle_outline,
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

  /// SnackBar (non-blocking)
  static void showSnackBar({
    required String message,
    DialogType type = DialogType.info,
  }) {
    final ctx = AppNavigator.context;
    if (ctx == null) return;

    final color = switch (type) {
      DialogType.error => Colors.red,
      DialogType.warning => Colors.orange,
      DialogType.success => Colors.green,
      DialogType.info => Colors.blue,
    };

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
