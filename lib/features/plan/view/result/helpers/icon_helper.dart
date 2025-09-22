import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Returns an icon depending on whether the given [time]
/// falls into night, sunrise/sunset window, or day.
///
/// If sunrise/sunset times are provided, use them to determine
/// the day cycle instead of static hour ranges.
IconData fishingTimeIcon(DateTime time, {DateTime? sunrise, DateTime? sunset}) {
  if (sunrise != null && sunset != null) {
    if (time.isBefore(sunrise)) {
      return LucideIcons.moon; // 🌙 Night before sunrise
    } else if (time.isAfter(sunset)) {
      return LucideIcons.moon; // 🌙 Night after sunset
    } else if (time.isAfter(sunrise.subtract(const Duration(minutes: 60))) &&
        time.isBefore(sunrise.add(const Duration(minutes: 60)))) {
      return LucideIcons.sunrise; // 🌅 Sunrise window
    } else if (time.isAfter(sunset.subtract(const Duration(minutes: 60))) &&
        time.isBefore(sunset.add(const Duration(minutes: 60)))) {
      return LucideIcons.sunset; // 🌇 Sunset window
    } else {
      return LucideIcons.sun; // ☀️ Daytime
    }
  }

  // Fallback to simple hour-based ranges if no sunrise/sunset given
  final hour = time.hour;
  if (hour < 5) return LucideIcons.moon;
  if (hour < 8) return LucideIcons.sunrise;
  if (hour < 17) return LucideIcons.sun;
  if (hour < 20) return LucideIcons.sunset;
  return LucideIcons.moon;
}
