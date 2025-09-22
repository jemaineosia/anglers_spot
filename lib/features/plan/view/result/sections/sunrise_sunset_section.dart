import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/section_card.dart';

class SunriseSunsetSection extends StatelessWidget {
  final Map<String, dynamic> payload;

  const SunriseSunsetSection({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final daily =
        (payload['daily'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dfh = DateFormat('EEE, MMM d');
    final tf = DateFormat('h:mm a');

    if (daily.isEmpty) return const SizedBox.shrink();

    return SectionCard(
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
    );
  }
}
