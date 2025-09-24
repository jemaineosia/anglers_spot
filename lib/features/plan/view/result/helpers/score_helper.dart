import 'package:anglers_spot/core/models/environment_type.dart';
import 'package:anglers_spot/features/plan/view/result/helpers/moonphase_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HourInsight {
  final DateTime time;
  final double score;
  HourInsight(this.time, this.score);
}

List<HourInsight> calculateBestWindows(
  List<Map<String, dynamic>> hours,
  List<Map<String, dynamic>> daily,
  List<Map<String, dynamic>> astronomy,
  List<Map<String, dynamic>> tides, {
  required EnvironmentType env, // NEW
}) {
  final sunriseTimes = daily
      .map((d) => DateTime.tryParse(d['sunrise'] ?? ''))
      .whereType<DateTime>()
      .toList();

  final sunsetTimes = daily
      .map((d) => DateTime.tryParse(d['sunset'] ?? ''))
      .whereType<DateTime>()
      .toList();

  final Map<String, Map<String, dynamic>> astroByDate = {
    for (final a in astronomy)
      if (a['date'] != null) a['date'] as String: a,
  };

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

    // weather
    score += 40 * (1 - (wind.clamp(0, 30) / 30));
    score += 10 * (1 - (gust.clamp(0, 40) / 40));
    score += 30 * (1 - (precip.clamp(0, 100) / 100));
    score += 10 * (1 - ((cloud - 50).abs() / 50));

    // sunrise or sunset proximity
    for (final s in [...sunriseTimes, ...sunsetTimes]) {
      final diff = (t.difference(s).inMinutes).abs();
      if (diff <= 120) score += (120 - diff) / 120 * 20;
    }

    // moon phase and moonrise or moonset
    double springBoost = 0.0;
    final key =
        '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    final astro = astroByDate[key];

    if (astro != null) {
      final moonPhaseStr = (astro['moon_phase'] ?? 'UNKNOWN').toString();

      switch (normalizeMoonPhase(moonPhaseStr)) {
        case 'NEW_MOON':
        case 'FULL_MOON':
          score += 15;
          springBoost = 5;
          break;
        case 'QUARTER':
          score -= 5;
          break;
        default:
          break;
      }

      DateTime? mkTodayTime(String? hhmm) {
        if (hhmm == null || hhmm.isEmpty) return null;
        try {
          final p = DateFormat('HH:mm').parse(hhmm);
          return DateTime(t.year, t.month, t.day, p.hour, p.minute);
        } catch (_) {
          return null;
        }
      }

      for (final mTime in [
        mkTodayTime(astro['moonrise']?.toString()),
        mkTodayTime(astro['moonset']?.toString()),
      ]) {
        if (mTime != null) {
          final diff = (t.difference(mTime).inMinutes).abs();
          if (diff <= 90) score += (90 - diff) / 90 * 10;
        }
      }
    }

    // tide movement proxy
    double currentScoreForHour = 0.0;
    if (tideEvents.length >= 2) {
      for (int i = 0; i < tideEvents.length - 1; i++) {
        final t1 = tideEvents[i]['time'] as DateTime;
        final t2 = tideEvents[i + 1]['time'] as DateTime;
        final h1 = tideEvents[i]['height'] as double?;
        final h2 = tideEvents[i + 1]['height'] as double?;

        if (t.isAfter(t1) && t.isBefore(t2) && h1 != null && h2 != null) {
          final diffHeight = (h2 - h1).abs();
          final diffMinutes = (t2.difference(t1).inMinutes).abs();
          final slope = diffMinutes > 0 ? diffHeight / diffMinutes : 0.0;

          // base current score
          currentScoreForHour = (slope * 100.0).clamp(0, 15);

          // environment multiplier
          currentScoreForHour *= _envCurrentMultiplier(
            env: env,
            tideNow: _interpHeightAt(t, t1, h1, t2, h2),
            tidePrev: h1,
            tideNext: h2,
            slope: slope,
          );

          score += currentScoreForHour;
          break;
        }
      }
    }

    // small synergy if spring plus noticeable current
    if (springBoost > 0 && currentScoreForHour > 5) {
      score += springBoost;
    }

    scored.add(HourInsight(t, score.clamp(0, 100)));
  }

  scored.sort((a, b) => a.time.compareTo(b.time));
  return scored;
}

// environment tide or current emphasis
double _envCurrentMultiplier({
  required EnvironmentType env,
  required double tideNow,
  required double tidePrev,
  required double tideNext,
  required double slope,
}) {
  // slope is movement per minute
  final isSlack = slope < 0.001; // heuristic
  final isNearHigh = tideNow >= tidePrev && tideNow >= tideNext;
  final isNearLow = tideNow <= tidePrev && tideNow <= tideNext;
  final isMidMovement = !isSlack && !isNearHigh && !isNearLow;

  switch (env) {
    case EnvironmentType.beach:
      if (isSlack) return 0.8;
      if (isMidMovement) return 1.0;
      return 0.9; // exact highs or lows slightly less
    case EnvironmentType.rocks:
      if (isNearHigh) return 1.15;
      if (isSlack) return 0.9;
      return 1.0;
    case EnvironmentType.island:
      if (isMidMovement) return 1.25;
      if (isSlack || isNearHigh || isNearLow) return 0.8;
      return 1.0;
    case EnvironmentType.estuary:
      if (isMidMovement) return 1.05;
      return 0.9;
    case EnvironmentType.offshore:
      if (slope >= 0.01) return 1.1;
      return 0.9;
  }
}

// linear interpolation of tide height at time t
double _interpHeightAt(
  DateTime t,
  DateTime t1,
  double h1,
  DateTime t2,
  double h2,
) {
  final total = t2.difference(t1).inSeconds;
  if (total <= 0) return h1;
  final part = t.difference(t1).inSeconds.clamp(0, total);
  final f = part / total;
  return h1 + (h2 - h1) * f;
}

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
      rangeEnd = h.time;
    } else {
      ranges.add(WindowRange(rangeStart, rangeEnd, currentLabel));
      rangeStart = h.time;
      rangeEnd = h.time;
      currentLabel = label;
    }
  }

  ranges.add(WindowRange(rangeStart, rangeEnd, currentLabel));
  return ranges;
}
