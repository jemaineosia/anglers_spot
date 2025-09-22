import 'package:flutter/material.dart';

/// Returns an icon + label depending on tide current strength
Widget currentStrengthIcon(double? h1, double? h2) {
  if (h1 == null || h2 == null) {
    return const Text("–", style: TextStyle(color: Colors.grey));
  }

  final diff = (h1 - h2).abs();

  if (diff >= 1.5) {
    return const Text(
      "🌊 Strong Current",
      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    );
  } else {
    return const Text(
      "💤 Weak Current",
      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
    );
  }
}
