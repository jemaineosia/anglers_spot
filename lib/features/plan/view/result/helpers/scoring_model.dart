import 'dart:math';

/// A scored fishing window.
class FishingWindow {
  final DateTime time;
  final double score;
  final String label;
  final int tideBonus;
  final int moonBonus;

  FishingWindow({
    required this.time,
    required this.score,
    required this.label,
    this.tideBonus = 0,
    this.moonBonus = 0,
  });
}

/// Main function to calculate fishing scores.
List<FishingWindow> calculateFishingScores({
  required List<Map<String, dynamic>> hours,
  required List<Map<String, dynamic>> daily,
  required List<Map<String, dynamic>> tides,
  required List<Map<String, dynamic>> astronomy,
}) {
  // Parse sunrise/sunset for weighting
  final sunriseTimes = daily
      .map((d) => DateTime.tryParse(d['sunrise'] ?? ''))
      .whereType<DateTime>()
      .toList();
  final sunsetTimes = daily
      .map((d) => DateTime.tryParse(d['sunset'] ?? ''))
      .whereType<DateTime>()
      .toList();

  // Moon phase lookup (0=new, 0.5=full)
  final moonPhases = astronomy
      .map((a) => (a['moon_phase'] as num?)?.toDouble())
      .whereType<double>()
      .toList();

  // Compute scores for each hour
  return hours.map((h) {
    final t = DateTime.parse(h['time']);
    final wind = (h['wind_kmh'] ?? 0).toDouble();
    final gust = (h['gust_kmh'] ?? wind).toDouble();
    final precip = (h['precip_prob'] ?? 0).toDouble();
    final cloud = (h['cloud'] ?? 50).toDouble();

    double score = 0;

    // Weather
    score += 40 * (1 - (wind.clamp(0, 30) / 30));
    score += 10 * (1 - (gust.clamp(0, 40) / 40));
    score += 30 * (1 - (precip.clamp(0, 100) / 100));
    score += 10 * (1 - ((cloud - 50).abs() / 50));

    // Sunrise / Sunset bonus (within 2h)
    for (var s in [...sunriseTimes, ...sunsetTimes]) {
      final diff = (t.difference(s).inMinutes).abs();
      if (diff <= 120) score += (120 - diff) / 120 * 20;
    }

    // Tide strength (difference between highs/lows around this hour)
    int tideBonus = 0;
    if (tides.isNotEmpty) {
      // Look for closest two tide events
      final nearest = tides
          .map(
            (e) => {
              'time': DateTime.tryParse(e['time'] ?? ''),
              'height': e['height'] as num?,
            },
          )
          .where((e) => e['time'] != null)
          .toList();

      if (nearest.length >= 2) {
        nearest.sort(
          (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
        );
        for (int i = 0; i < nearest.length - 1; i++) {
          final h1 = (nearest[i]['height'] as num?)?.toDouble();
          final h2 = (nearest[i + 1]['height'] as num?)?.toDouble();
          if (h1 != null && h2 != null) {
            final diff = (h2 - h1).abs();
            if (diff > 1.5)
              tideBonus = 15;
            else if (diff > 0.8)
              tideBonus = 10;
            else
              tideBonus = 3;
          }
        }
      }
    }
    score += tideBonus;

    // Moon phase bonus
    int moonBonus = 0;
    if (moonPhases.isNotEmpty) {
      final phase = moonPhases.first; // assume first for now
      if (phase == 0.0 || phase == 0.5) {
        moonBonus = 15;
      } else if (phase > 0.25 && phase < 0.75) {
        moonBonus = 10;
      } else {
        moonBonus = 5;
      }
    }
    score += moonBonus;

    // Normalize
    score = min(score, 100);

    return FishingWindow(
      time: t,
      score: score,
      label: scoreLabel(score),
      tideBonus: tideBonus,
      moonBonus: moonBonus,
    );
  }).toList();
}

/// Label scores into categories
String scoreLabel(double score) {
  if (score >= 80) return "Excellent";
  if (score >= 60) return "Good";
  if (score >= 40) return "Fair";
  return "Poor";
}
