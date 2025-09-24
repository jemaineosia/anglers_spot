import 'package:anglers_spot/core/models/environment_type.dart';
import 'package:anglers_spot/features/plan/view/result/helpers/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../helpers/score_helper.dart';
import '../widgets/section_card.dart';

class FishingWindowsSection extends StatelessWidget {
  final Map<String, dynamic> payload;

  const FishingWindowsSection({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final hours =
        (payload['hourly'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final daily =
        (payload['daily'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final astronomy =
        (payload['astronomy'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tides =
        (payload['tides'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (hours.isEmpty) return const SizedBox.shrink();

    final env = payload['environment'] as EnvironmentType; // or from params
    final windows = calculateBestWindows(
      hours,
      daily,
      astronomy,
      tides,
      env: env,
    ).where((h) => scoreLabel(h.score) != "Good").toList();

    final grouped = groupConsecutiveWindows(windows);

    if (windows.isEmpty) {
      return SectionCard(
        title: "Best Fishing Windows",
        icon: LucideIcons.fish,
        children: const [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "No optimal fishing windows available during this period. "
              "Check tide, moon, or weather updates.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    // group by day
    final dfDay = DateFormat('EEE, MMM d');
    final groupedByDay = <String, List<dynamic>>{};
    for (final w in grouped) {
      final dayKey = dfDay.format(w.start);
      groupedByDay.putIfAbsent(dayKey, () => []).add(w);
    }

    return SectionCard(
      title: "Best Fishing Windows",
      icon: LucideIcons.fish,
      children: groupedByDay.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 8,
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.grey.shade50,
            collapsedBackgroundColor: Colors.grey.shade100,
            title: Text(
              entry.key,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            leading: const Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.teal,
            ),
            trailing: const Icon(Icons.expand_more, color: Colors.teal),
            children: entry.value.map((w) {
              final tf = DateFormat('h:mm a');
              final timeText = w.start == w.end
                  ? tf.format(w.start)
                  : "${tf.format(w.start)} - ${tf.format(w.end)}";

              return ListTile(
                leading: Icon(
                  fishingTimeIcon(
                    w.start,
                    sunrise: _findSunriseForDay(daily, w.start),
                    sunset: _findSunsetForDay(daily, w.start),
                  ),
                  color: Colors.teal,
                ),
                title: Text(timeText),
                trailing: Chip(
                  label: Text(
                    w.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: (w.label == "Best")
                      ? Colors.green
                      : (w.label == "Better")
                      ? Colors.orange
                      : Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

DateTime? _findSunriseForDay(List<Map<String, dynamic>> daily, DateTime day) {
  final entry = daily.firstWhere(
    (d) => DateTime.parse(d['date']).day == day.day,
    orElse: () => {},
  );
  return entry.isNotEmpty ? DateTime.tryParse(entry['sunrise'] ?? '') : null;
}

DateTime? _findSunsetForDay(List<Map<String, dynamic>> daily, DateTime day) {
  final entry = daily.firstWhere(
    (d) => DateTime.parse(d['date']).day == day.day,
    orElse: () => {},
  );
  return entry.isNotEmpty ? DateTime.tryParse(entry['sunset'] ?? '') : null;
}
