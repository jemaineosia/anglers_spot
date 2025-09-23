import 'package:anglers_spot/features/plan/view/result/helpers/moonphase_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  // Precompute sunrise/sunset DateTimes
  final sunriseTimes = daily
      .map((d) => DateTime.tryParse(d['sunrise'] ?? ''))
      .whereType<DateTime>()
      .toList();
  final sunsetTimes = daily
      .map((d) => DateTime.tryParse(d['sunset'] ?? ''))
      .whereType<DateTime>()
      .toList();

  // Build a quick lookup for astronomy by date (YYYY-MM-DD)
  final Map<String, Map<String, dynamic>> astroByDate = {
    for (final a in astronomy)
      if (a['date'] != null) a['date'] as String: a,
  };

  // Normalize tide events into typed list
  final tideEvents =
      tides
          .map((e) {
            final tt = DateTime.tryParse(e['time'] ?? '');
            final height = (e['height'] is num)
                ? (e['height'] as num).toDouble()
                : null;
            return (tt == null) ? null : {'time': tt, 'height': height};
          })
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort(
          (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
        );

  final List<HourInsight> scored = [];

  for (final h in hours) {
    final t = DateTime.parse(h['time']);
    final wind = (h['wind_kmh'] ?? 0).toDouble();
    final gust = (h['gust_kmh'] ?? wind).toDouble();
    final precip = (h['precip_prob'] ?? 0).toDouble();
    final cloud = (h['cloud'] ?? 50).toDouble();

    double score = 0.0;

    // 1) Weather (max ~90)
    score += 40 * (1 - (wind.clamp(0, 30) / 30));
    score += 10 * (1 - (gust.clamp(0, 40) / 40));
    score += 30 * (1 - (precip.clamp(0, 100) / 100));
    score += 10 * (1 - ((cloud - 50).abs() / 50));

    // 2) Dawn/Dusk proximity (max +20)
    for (final s in [...sunriseTimes, ...sunsetTimes]) {
      final diff = (t.difference(s).inMinutes).abs();
      if (diff <= 120) score += (120 - diff) / 120 * 20;
    }

    // 3) Moon (phase + moonrise/set)
    double springBoost = 0.0; // defer until after current strength is known
    final key =
        '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    final astro = astroByDate[key];

    if (astro != null) {
      final moonPhaseStr = (astro['moon_phase'] ?? 'UNKNOWN').toString();

      // Phase bonus/penalty
      switch (normalizeMoonPhase(moonPhaseStr)) {
        case 'NEW_MOON':
        case 'FULL_MOON':
          score += 15; // stronger feeding tendency
          springBoost = 5; // keep a small extra boost for strong currents
          break;
        case 'QUARTER':
          score -= 5; // weaker tendency
          break;
        default:
          break;
      }

      // Moonrise / Moonset proximity (each up to +10)
      String? mr = astro['moonrise']?.toString();
      String? ms = astro['moonset']?.toString();

      DateTime? mkTodayTime(String? hhmm) {
        if (hhmm == null || hhmm.isEmpty) return null;
        try {
          // ipgeolocation returns "HH:mm" (24h). Adjust if your provider differs.
          final p = DateFormat('HH:mm').parse(hhmm);
          return DateTime(t.year, t.month, t.day, p.hour, p.minute);
        } catch (_) {
          return null;
        }
      }

      for (final mTime in [mkTodayTime(mr), mkTodayTime(ms)]) {
        if (mTime != null) {
          final diff = (t.difference(mTime).inMinutes).abs();
          if (diff <= 90) score += (90 - diff) / 90 * 10;
        }
      }
    }

    // 4) Tide-driven current strength (+ up to ~15)
    double currentScoreForHour = 0.0;
    if (tideEvents.length >= 2) {
      // Find adjacent pair that bounds 't'
      for (int i = 0; i < tideEvents.length - 1; i++) {
        final t1 = tideEvents[i]['time'] as DateTime;
        final t2 = tideEvents[i + 1]['time'] as DateTime;
        final h1 = tideEvents[i]['height'] as double?;
        final h2 = tideEvents[i + 1]['height'] as double?;

        if (t.isAfter(t1) && t.isBefore(t2) && h1 != null && h2 != null) {
          final diffHeight = (h2 - h1).abs();
          final diffMinutes = (t2.difference(t1).inMinutes).abs();
          final slope = diffMinutes > 0 ? diffHeight / diffMinutes : 0.0;

          // Heuristic scale → 0..~15
          currentScoreForHour = (slope * 100.0).clamp(0, 15);
          score += currentScoreForHour;
          break;
        }
      }
    }

    // If spring tide + noticeable current, add a small synergy boost
    if (springBoost > 0 && currentScoreForHour > 5) {
      score += springBoost;
    }

    scored.add(HourInsight(t, score.clamp(0, 100)));
  }

  // Keep time order (your UI does grouping/ranking)
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
