import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/section_card.dart';
import '../widgets/tide_cell.dart';

class TideExtremesSection extends StatelessWidget {
  final Map<String, dynamic> payload;

  const TideExtremesSection({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final tides =
        (payload['tides'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tf = DateFormat('h:mm a');

    if (tides.isEmpty) return const SizedBox.shrink();

    return SectionCard(
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
                  TideCell(tide: tides[i], tf: tf),
                  if (i + 1 < tides.length)
                    TideCell(tide: tides[i + 1], tf: tf),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
