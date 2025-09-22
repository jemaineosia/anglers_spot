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
    final dfh = DateFormat('EEE, MMM d');
    final tf = DateFormat('h:mm a');

    if (hours.isEmpty) return const SizedBox.shrink();

    // Filter only future windows
    final windows = calculateBestWindows(
      hours,
      daily,
    ).where((h) => h.time.isAfter(DateTime.now())).toList();

    return SectionCard(
      title: "Best Fishing Windows",
      icon: LucideIcons.fish,
      children: windows.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No good fishing windows available right now.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "This may be due to poor conditions (bad weather, rough seas, or typhoon nearby).",
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ]
          : windows.map((h) {
              final label = scoreLabel(h.score);
              final color = scoreColor(h.score);
              return ListTile(
                leading: const Icon(LucideIcons.clock),
                title: Text("${dfh.format(h.time)} • ${tf.format(h.time)}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      h.score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}
