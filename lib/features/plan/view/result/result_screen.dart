import 'package:anglers_spot/features/plan/view/result/sections/sunrise_sunset_section.dart';
import 'package:anglers_spot/features/plan/view/result/sections/tide_extremes_section.dart';
import 'package:flutter/material.dart';

import 'sections/fishing_windows_section.dart';
import 'sections/trip_details_section.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> payload;
  const ResultScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forecast Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TripDetailsSection(payload: payload),
          SunriseSunsetSection(payload: payload),
          TideExtremesSection(payload: payload),
          FishingWindowsSection(payload: payload),
        ],
      ),
    );
  }
}
