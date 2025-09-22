import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/section_card.dart';

class TripDetailsSection extends StatelessWidget {
  final Map<String, dynamic> payload;

  const TripDetailsSection({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Trip Details',
      icon: LucideIcons.mapPin,
      children: [
        Text(
          "📍 Location: ${payload['locationName'] ?? '${payload['lat']}, ${payload['lon']}'}",
        ),
        Text("📅 Dates: ${payload['startDate']} → ${payload['endDate']}"),
      ],
    );
  }
}
