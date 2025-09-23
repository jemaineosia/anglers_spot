import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

import '../widgets/app_dialog.dart';

final logger = Logger();

Future<T?> safeCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    logger.e("Error occurred", error: e, stackTrace: st);

    // Run after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDialog.show(message: e.toString(), type: DialogType.error);
    });

    return null;
  }
}
