import 'package:flutter/material.dart';

String scoreLabel(double score) {
  if (score >= 85) return "Best";
  if (score >= 70) return "Better";
  return "Good";
}

Color scoreColor(double score) {
  if (score >= 85) return Colors.green;
  if (score >= 70) return Colors.orange;
  return Colors.blueGrey;
}
