import 'package:anglers_spot/features/plan/view/result/helpers/score_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

    if (hours.isEmpty) return const SizedBox.shrink();

    final windows = calculateBestWindows(hours, daily);
    final grouped = _groupByDay(windows);

    final dfh = DateFormat('EEE, MMM d');
    final tf = DateFormat('h:mm a');

    return SectionCard(
      title: "Best Fishing Windows",
      icon: LucideIcons.fish,
      children: grouped.entries.map((entry) {
        final date = entry.key;
        final dayWindows = entry.value;

        return ExpansionTile(
          leading: const Icon(LucideIcons.calendar),
          title: Text(dfh.format(date)),
          subtitle: Text("${dayWindows.length} windows"),
          children: dayWindows.map((h) {
            final label = scoreLabel(h.score);
            final color = scoreColor(h.score);
            return ListTile(
              leading: const Icon(LucideIcons.clock),
              title: Text(tf.format(h.time)),
              trailing: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Map<DateTime, List<HourScore>> _groupByDay(List<HourScore> scored) {
    final map = <DateTime, List<HourScore>>{};
    for (final h in scored) {
      final day = DateTime(h.time.year, h.time.month, h.time.day);
      map.putIfAbsent(day, () => []).add(h);
    }
    return map;
  }
}
