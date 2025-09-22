// lib/features/plan/view/planner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/forecast_provider.dart';
import '../services/geocoding_service.dart';
import 'forecast_result_page.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTimeRange? _range;
  final _location = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange:
          _range ??
          DateTimeRange(start: now, end: now.add(const Duration(days: 1))),
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _useCurrentLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final svc = GeocodingService();
      final placeName = await svc.reverseGeocode(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _location.text =
            placeName ??
            "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location error: $e')));
    }
  }

  Future<void> _generate() async {
    if (_range == null || _location.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick dates and enter a location')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final svc = GeocodingService();
      final coords = await svc.fetchCoordinates(_location.text.trim());

      if (coords == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location not found')));
        return;
      }

      final params = ForecastParams(
        lat: coords['lat']!,
        lon: coords['lon']!,
        start: _range!.start,
        end: _range!.end,
        locationName: _location.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ForecastResultPage(params: params)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _range == null
        ? 'Select dates'
        : '${_range!.start.toLocal().toString().split(' ').first} → '
              '${_range!.end.toLocal().toString().split(' ').first}';

    return Scaffold(
      appBar: AppBar(title: const Text('Plan a Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range
          ListTile(
            title: Text(dateText),
            trailing: const Icon(Icons.date_range),
            onTap: _pickDateRange,
          ),
          const SizedBox(height: 12),

          // Location input
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location (e.g. Bedok Jetty)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          // Use current location
          TextButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Use my current location'),
            onPressed: _useCurrentLocation,
          ),

          const SizedBox(height: 16),

          // Generate button
          FilledButton(
            onPressed: _loading ? null : _generate,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate Plan'),
          ),
        ],
      ),
    );
  }
}
