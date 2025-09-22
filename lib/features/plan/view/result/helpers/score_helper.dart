import 'package:flutter/material.dart';

/// Holds insights about each fishing hour
class HourInsight {
  final DateTime time;
  final double score;
  HourInsight(this.time, this.score);
}

/// Calculate best fishing windows based on multiple factors
List<HourInsight> calculateBestWindows(
  List<Map<String, dynamic>> hours,
  List<Map<String, dynamic>> daily,
  List<Map<String, dynamic>> astronomy,
  List<Map<String, dynamic>> tides,
) {
  final sunriseTimes = daily
      .map((d) => DateTime.tryParse(d['sunrise'] ?? ''))
      .whereType<DateTime>()
      .toList();

  final sunsetTimes = daily
      .map((d) => DateTime.tryParse(d['sunset'] ?? ''))
      .whereType<DateTime>()
      .toList();

  // Moon phase → 0 = new, 0.5 = full
  final moonPhases = astronomy
      .map((a) => (a['moon_phase'] ?? 0).toDouble())
      .toList();

  // Use tide extremes to approximate current strength
  List<Map<String, dynamic>> tideEvents = tides;

  List<HourInsight> scored = [];

  for (final h in hours) {
    final t = DateTime.parse(h['time']);
    final wind = (h['wind_kmh'] ?? 0).toDouble();
    final gust = (h['gust_kmh'] ?? wind).toDouble();
    final precip = (h['precip_prob'] ?? 0).toDouble();
    final cloud = (h['cloud'] ?? 50).toDouble();

    double score = 0;

    // ✅ Weather Factors
    score += 40 * (1 - (wind.clamp(0, 30) / 30));
    score += 10 * (1 - (gust.clamp(0, 40) / 40));
    score += 30 * (1 - (precip.clamp(0, 100) / 100));
    score += 10 * (1 - ((cloud - 50).abs() / 50));

    // ✅ Sunrise & Sunset
    for (var s in [...sunriseTimes, ...sunsetTimes]) {
      final diff = (t.difference(s).inMinutes).abs();
      if (diff <= 120) score += (120 - diff) / 120 * 20;
    }

    // ✅ Moon Phase (new/full moon = stronger feeding)
    if (moonPhases.isNotEmpty) {
      final moon = moonPhases.first; // crude, pick first for now
      if (moon <= 0.1 || (moon >= 0.4 && moon <= 0.6)) {
        score += 15; // bonus for new/full moon
      }
    }

    // ✅ Tide/Current Strength (bonus if near tide extremes)
    if (tideEvents.isNotEmpty) {
      final nearest = tideEvents
          .map((e) {
            final tt = DateTime.tryParse(e['time'] ?? '');
            return tt == null ? null : {'time': tt, 'height': e['height']};
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      for (int i = 0; i < nearest.length - 1; i++) {
        final h1 = (nearest[i]['height'] as num?)?.toDouble();
        final h2 = (nearest[i + 1]['height'] as num?)?.toDouble();
        final t1 = nearest[i]['time'] as DateTime;
        final t2 = nearest[i + 1]['time'] as DateTime;

        if (h1 != null && h2 != null) {
          final diffHeight = (h2 - h1).abs();
          final diffMinutes = t2.difference(t1).inMinutes.abs();
          final slope = diffMinutes > 0 ? diffHeight / diffMinutes : 0;

          // Current strength factor
          final currentScore = (slope * 100).clamp(0, 15);
          if (t.isAfter(t1) && t.isBefore(t2)) {
            score += currentScore;
          }
        }
      }
    }

    scored.add(HourInsight(t, score.clamp(0, 100)));
  }

  // Sort by best scores and upcoming times
  scored.sort((a, b) => a.time.compareTo(b.time));
  return scored;
}

/// Label for score ranges
String scoreLabel(double score) {
  if (score >= 85) return "Best";
  if (score >= 70) return "Better";
  return "Good";
}

/// Color for score ranges
Color scoreColor(double score) {
  if (score >= 85) return Colors.green;
  if (score >= 70) return Colors.orange;
  return Colors.blueGrey;
}

class WindowRange {
  final DateTime start;
  final DateTime end;
  final String label;
  WindowRange(this.start, this.end, this.label);
}

List<WindowRange> groupConsecutiveWindows(List<HourInsight> hours) {
  if (hours.isEmpty) return [];

  List<WindowRange> ranges = [];
  HourInsight first = hours.first;
  DateTime rangeStart = first.time;
  DateTime rangeEnd = first.time;
  String currentLabel = scoreLabel(first.score);

  for (int i = 1; i < hours.length; i++) {
    final h = hours[i];
    final label = scoreLabel(h.score);

    final diff = h.time.difference(rangeEnd).inHours;

    if (label == currentLabel && diff == 1) {
      // Continue the range
      rangeEnd = h.time;
    } else {
      // Save previous range
      ranges.add(WindowRange(rangeStart, rangeEnd, currentLabel));
      // Start new range
      rangeStart = h.time;
      rangeEnd = h.time;
      currentLabel = label;
    }
  }

  // Add final range
  ranges.add(WindowRange(rangeStart, rangeEnd, currentLabel));

  return ranges;
}
