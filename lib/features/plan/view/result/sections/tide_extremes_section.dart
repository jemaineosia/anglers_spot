import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/section_card.dart';

class TideExtremesSection extends StatelessWidget {
  final Map<String, dynamic> payload;

  const TideExtremesSection({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final tides =
        (payload['tides'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final astronomy =
        (payload['astronomy'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (tides.isEmpty) return const SizedBox.shrink();

    final tf = DateFormat('h:mm a');

    // Compute base tide differences
    final List<double> diffs = [];
    for (int i = 0; i < tides.length - 1; i++) {
      final h1 = (tides[i]['height'] as num?)?.toDouble() ?? 0.0;
      final h2 = (tides[i + 1]['height'] as num?)?.toDouble() ?? 0.0;
      diffs.add((h2 - h1).abs());
    }
    diffs.sort();
    final medianDiff = diffs.isNotEmpty ? diffs[diffs.length ~/ 2] : 0.3;

    final strongThreshold = medianDiff * 1.2;
    final weakThreshold = medianDiff * 0.8;

    return SectionCard(
      title: "Tide Extremes",
      icon: LucideIcons.waves,
      children: [
        Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
          children: [
            for (int i = 0; i < tides.length; i += 2)
              TableRow(
                children: [
                  _buildTideCell(
                    tides,
                    i,
                    tf,
                    strongThreshold,
                    weakThreshold,
                    astronomy,
                  ),
                  if (i + 1 < tides.length)
                    _buildTideCell(
                      tides,
                      i + 1,
                      tf,
                      strongThreshold,
                      weakThreshold,
                      astronomy,
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTideCell(
    List<Map<String, dynamic>> tides,
    int index,
    DateFormat tf,
    double strongThreshold,
    double weakThreshold,
    List<Map<String, dynamic>> astronomy,
  ) {
    final tide = tides[index];
    final type = tide['type'];
    final time = tf.format(DateTime.parse(tide['time']));
    final height = (tide['height'] as num?)?.toDouble() ?? 0.0;

    // Tide difference
    double diff = 0.0;
    if (index < tides.length - 1) {
      final nextHeight =
          (tides[index + 1]['height'] as num?)?.toDouble() ?? 0.0;
      diff = (nextHeight - height).abs();
    }

    // Apply moon phase multiplier
    final moonPhase = astronomy.isNotEmpty
        ? astronomy.first['moon_phase'] ?? ""
        : "";
    double multiplier = 1.0;
    if (moonPhase.contains("New") || moonPhase.contains("Full")) {
      multiplier = 1.3; // stronger currents
    } else if (moonPhase.contains("Quarter")) {
      multiplier = 0.7; // weaker currents
    }

    final adjustedDiff = diff * multiplier;

    // Classification
    String currentLabel;
    Color currentColor;
    IconData currentIcon;

    if (adjustedDiff >= strongThreshold) {
      currentLabel = "🌊 Strong Current (Spring Tide)";
      currentColor = Colors.blue;
      currentIcon = LucideIcons.activity;
    } else if (adjustedDiff <= weakThreshold) {
      currentLabel = "💤 Weak Current (Neap Tide)";
      currentColor = Colors.grey;
      currentIcon = LucideIcons.moon;
    } else {
      currentLabel = "↔ Moderate Current";
      currentColor = Colors.teal;
      currentIcon = LucideIcons.waves;
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$type $time",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "${height.toStringAsFixed(2)} m",
            style: const TextStyle(color: Colors.blueGrey),
          ),
          Row(
            children: [
              Icon(currentIcon, size: 14, color: currentColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  currentLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: currentColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
