import 'package:flutter/material.dart';

class HourScore {
  final DateTime time;
  final double score;
  HourScore(this.time, this.score);
}

List<HourScore> calculateBestWindows(
  List<Map<String, dynamic>> hours,
  List<Map<String, dynamic>> daily,
) {
  final sunriseTimes = daily
      .map((d) => DateTime.tryParse(d['sunrise'] ?? ''))
      .whereType<DateTime>()
      .toList();
  final sunsetTimes = daily
      .map((d) => DateTime.tryParse(d['sunset'] ?? ''))
      .whereType<DateTime>()
      .toList();

  List<HourScore> scored = [];
  for (final h in hours) {
    final t = DateTime.parse(h['time']);
    final wind = (h['wind_kmh'] ?? 0).toDouble();
    final gust = (h['gust_kmh'] ?? wind).toDouble();
    final precip = (h['precip_prob'] ?? 0).toDouble();
    final cloud = (h['cloud'] ?? 50).toDouble();

    double score = 0;
    score += 40 * (1 - (wind.clamp(0, 30) / 30));
    score += 10 * (1 - (gust.clamp(0, 40) / 40));
    score += 30 * (1 - (precip.clamp(0, 100) / 100));
    score += 10 * (1 - ((cloud - 50).abs() / 50));

    for (var s in [...sunriseTimes, ...sunsetTimes]) {
      final diff = (t.difference(s).inMinutes).abs();
      if (diff <= 120) score += (120 - diff) / 120 * 20;
    }

    scored.add(HourScore(t, score));
  }

  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(6).toList()..sort((a, b) => a.time.compareTo(b.time));
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
