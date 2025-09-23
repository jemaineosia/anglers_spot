import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';

class AppLoader {
  static bool _isShowing = false;

  static final ValueNotifier<String?> _message = ValueNotifier<String?>(null);
  static final ValueNotifier<double?> _progress = ValueNotifier<double?>(null);

  static void show({String? message, double? progress}) {
    final ctx = AppNavigator.context;
    if (ctx == null || _isShowing) return;

    _isShowing = true;
    _message.value = message;
    _progress.value = progress;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (_) => PopScope(
        canPop: false, // disables back button
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double?>(
                valueListenable: _progress,
                builder: (_, value, __) {
                  if (value == null) {
                    return const CircularProgressIndicator();
                  }
                  return Column(
                    children: [
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(value: value / 100),
                      ),
                      const SizedBox(height: 8),
                      Text("${value.toStringAsFixed(0)}%"),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String?>(
                valueListenable: _message,
                builder: (_, value, __) {
                  if (value == null) return const SizedBox.shrink();
                  return Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void updateMessage(String message) {
    if (_isShowing) {
      _message.value = message;
    }
  }

  static void updateProgress(double progress) {
    if (_isShowing) {
      _progress.value = progress.clamp(0, 100);
    }
  }

  static void hide() {
    final ctx = AppNavigator.context;
    if (ctx == null || !_isShowing) return;

    Navigator.of(ctx, rootNavigator: true).pop();
    _isShowing = false;
    _message.value = null;
    _progress.value = null;
  }
}
