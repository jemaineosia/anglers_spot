// lib/features/plan/view/planner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/environment_type.dart';
import '../providers/forecast_provider.dart';
import '../services/geocoding_service.dart';
import 'forecast_result_page.dart';

enum SearchMode { locationName, coordinates }

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTimeRange? _range;
  final _location = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  SearchMode _mode = SearchMode.locationName;
  EnvironmentType _environment = EnvironmentType.beach;

  bool _loading = false;

  @override
  void dispose() {
    _location.dispose();
    _lat.dispose();
    _lon.dispose();
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
    if (_range == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick dates first')));
      return;
    }

    setState(() => _loading = true);
    try {
      double lat, lon;
      String locationName;

      if (_mode == SearchMode.locationName) {
        if (_location.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a location name')),
          );
          return;
        }
        final svc = GeocodingService();
        final coords = await svc.fetchCoordinates(_location.text.trim());

        if (coords == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location not found')));
          return;
        }
        lat = coords['lat']!;
        lon = coords['lon']!;
        locationName = _location.text.trim();
      } else {
        if (_lat.text.trim().isEmpty || _lon.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter both latitude and longitude')),
          );
          return;
        }
        lat = double.tryParse(_lat.text.trim()) ?? 0;
        lon = double.tryParse(_lon.text.trim()) ?? 0;
        locationName = "${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}";
      }

      final params = ForecastParams(
        lat: lat,
        lon: lon,
        start: _range!.start,
        end: _range!.end,
        locationName: locationName,
        environment: _environment, // pass environment
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
      appBar: AppBar(title: const Text('Weather Forecast')),
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

          // Mode selector
          Row(
            children: [
              Expanded(
                child: RadioListTile<SearchMode>(
                  title: const Text("Location name"),
                  value: SearchMode.locationName,
                  groupValue: _mode,
                  onChanged: (SearchMode? val) =>
                      setState(() => _mode = val ?? SearchMode.locationName),
                ),
              ),
              Expanded(
                child: RadioListTile<SearchMode>(
                  title: const Text("Coordinates"),
                  value: SearchMode.coordinates,
                  groupValue: _mode,
                  onChanged: (SearchMode? val) =>
                      setState(() => _mode = val ?? SearchMode.coordinates),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location input or coordinates input
          if (_mode == SearchMode.locationName) ...[
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location (e.g. Bedok Jetty)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Use my current location'),
              onPressed: _useCurrentLocation,
            ),
          ] else ...[
            TextField(
              controller: _lat,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lon,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Environment selector
          const Text(
            "Fishing Environment",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RadioListTile<EnvironmentType>(
            title: const Text("Beach / Shoreline"),
            value: EnvironmentType.beach,
            groupValue: _environment,
            onChanged: (EnvironmentType? val) =>
                setState(() => _environment = val ?? EnvironmentType.beach),
          ),
          RadioListTile<EnvironmentType>(
            title: const Text("Rocks / Jetty / Pier"),
            value: EnvironmentType.rocks,
            groupValue: _environment,
            onChanged: (EnvironmentType? val) =>
                setState(() => _environment = val ?? EnvironmentType.rocks),
          ),
          RadioListTile<EnvironmentType>(
            title: const Text("Island"),
            value: EnvironmentType.island,
            groupValue: _environment,
            onChanged: (EnvironmentType? val) =>
                setState(() => _environment = val ?? EnvironmentType.island),
          ),
          RadioListTile<EnvironmentType>(
            title: const Text("Estuary / River / Lagoon"),
            value: EnvironmentType.estuary,
            groupValue: _environment,
            onChanged: (EnvironmentType? val) =>
                setState(() => _environment = val ?? EnvironmentType.estuary),
          ),
          RadioListTile<EnvironmentType>(
            title: const Text("Offshore / Open Sea"),
            value: EnvironmentType.offshore,
            groupValue: _environment,
            onChanged: (EnvironmentType? val) =>
                setState(() => _environment = val ?? EnvironmentType.offshore),
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
                : const Text('Get Forecast'),
          ),
        ],
      ),
    );
  }
}
