import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> payload;
  const ResultScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final hours = (payload['hourly'] as List).cast<Map<String, dynamic>>();
    final daily = (payload['daily'] as List).cast<Map<String, dynamic>>();
    final tides =
        (payload['tides'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final dfh = DateFormat('EEE, MMM d');
    final tf = DateFormat('h:mm a'); // 12-hour format with AM/PM

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location & Date
          _SectionCard(
            title: 'Trip Details',
            icon: LucideIcons.mapPin,
            children: [
              Text(
                "📍 Location: ${payload['locationName'] ?? '${payload['lat']}, ${payload['lon']}'}",
              ),
              Text("📅 Dates: ${payload['startDate']} → ${payload['endDate']}"),
            ],
          ),

          // Sunrise / Sunset
          if (daily.isNotEmpty)
            _SectionCard(
              title: "Sunrise & Sunset",
              icon: LucideIcons.sun,
              children: daily.map((d) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dfh.format(DateTime.parse(d['date']))),
                    Text(
                      "↑ ${tf.format(DateTime.parse(d['sunrise']))}  ↓ ${tf.format(DateTime.parse(d['sunset']))}",
                    ),
                  ],
                );
              }).toList(),
            ),

          // Tides
          if (tides.isNotEmpty)
            _SectionCard(
              title: "Tide Extremes",
              icon: LucideIcons.waves,
              children: [
                Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: Colors.grey.shade300),
                  ),
                  children: [
                    for (int i = 0; i < tides.length; i += 2)
                      TableRow(
                        children: [
                          _tideCell(tides[i], tf),
                          if (i + 1 < tides.length) _tideCell(tides[i + 1], tf),
                        ],
                      ),
                  ],
                ),
              ],
            ),

          // Best Fishing Windows (Grouped by Day)
          _SectionCard(
            title: "Best Fishing Windows",
            icon: LucideIcons.fish,
            children: _buildFishingWindowsGrouped(hours, daily, dfh, tf),
          ),
        ],
      ),
    );
  }

  /// Build Tide Cell
  Widget _tideCell(Map<String, dynamic> tide, DateFormat tf) {
    final type = tide['type'];
    final time = tf.format(DateTime.parse(tide['time']));
    final height = tide['height']?.toStringAsFixed(2) ?? "";
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            "$type $time",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (height.isNotEmpty)
            Text("$height m", style: const TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }

  /// Grouped Fishing Windows
  List<Widget> _buildFishingWindowsGrouped(
    List<Map<String, dynamic>> hours,
    List<Map<String, dynamic>> daily,
    DateFormat dfh,
    DateFormat tf,
  ) {
    final scored = _calculateBestWindows(hours, daily);

    // Group by day
    final grouped = <String, List<_HourScore>>{};
    for (final h in scored) {
      final key = dfh.format(h.time); // e.g., Fri, Sep 26
      grouped.putIfAbsent(key, () => []).add(h);
    }

    return grouped.entries.map((entry) {
      final date = entry.key;
      final slots = entry.value;

      return ExpansionTile(
        leading: const Icon(LucideIcons.calendar),
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${slots.length} windows"),
        children: slots.map((h) {
          final label = _scoreLabel(h.score);
          final color = _scoreColor(h.score);

          return ListTile(
            leading: const Icon(LucideIcons.clock),
            title: Text(tf.format(h.time)),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  h.score.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  /// Scoring logic
  List<_HourScore> _calculateBestWindows(
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

    List<_HourScore> scored = [];
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

      scored.add(_HourScore(t, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(12).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  String _scoreLabel(double score) {
    if (score >= 85) return "Best";
    if (score >= 70) return "Better";
    return "Good";
  }

  Color _scoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.blueGrey;
  }
}

/// Score Model
class _HourScore {
  final DateTime time;
  final double score;
  _HourScore(this.time, this.score);
}

/// Section Card Wrapper
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
