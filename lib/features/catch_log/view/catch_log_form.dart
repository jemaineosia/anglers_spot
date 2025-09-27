import 'dart:io';

import 'package:anglers_spot/features/catch_log/services/catch_log_storage.dart';
import 'package:anglers_spot/features/plan/services/geocoding_service.dart';
import 'package:anglers_spot/shared/widgets/map_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/catch_log.dart';
import '../providers/catch_log_provider.dart';

class CatchLogForm extends ConsumerStatefulWidget {
  const CatchLogForm({super.key});

  @override
  ConsumerState<CatchLogForm> createState() => _CatchLogFormState();
}

class _CatchLogFormState extends ConsumerState<CatchLogForm> {
  final _formKey = GlobalKey<FormState>();

  final _species = TextEditingController();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _bait = TextEditingController();
  final _notes = TextEditingController();
  final _locationName = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  String? _environment;
  File? _photo;

  @override
  void initState() {
    super.initState();

    _lat.addListener(_handleLatLonChange);
    _lon.addListener(_handleLatLonChange);
  }

  void _handleLatLonChange() {
    // If either is empty, clear both + location name
    if (_lat.text.trim().isEmpty || _lon.text.trim().isEmpty) {
      if (_lat.text.isNotEmpty || _lon.text.isNotEmpty) {
        setState(() {
          _lat.clear();
          _lon.clear();
          _locationName.clear();
        });
      }
    }

    // Always trigger rebuild so button updates
    setState(() {});
  }

  @override
  void dispose() {
    _species.dispose();
    _weight.dispose();
    _length.dispose();
    _bait.dispose();
    _notes.dispose();
    _locationName.dispose();
    _lat.removeListener(_handleLatLonChange);
    _lon.removeListener(_handleLatLonChange);
    _lat.dispose();
    _lon.dispose();
    super.dispose();
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

      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lon.text = pos.longitude.toStringAsFixed(6);
        _locationName.text = placeName ?? "Current Location";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location error: $e')));
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  bool get _isLocationValid {
    final latVal = double.tryParse(_lat.text.trim());
    final lonVal = double.tryParse(_lon.text.trim());
    return latVal != null && lonVal != null;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? photoUrl;
    if (_photo != null) {
      photoUrl = await CatchLogStorage().uploadPhoto(_photo!);
    }

    final log = CatchLog(
      id: "",
      userId: "",
      species: _species.text.trim(),
      weight: double.tryParse(_weight.text.trim()),
      length: double.tryParse(_length.text.trim()),
      bait: _bait.text.trim(),
      environment: _environment,
      notes: _notes.text.trim(),
      lat: double.tryParse(_lat.text.trim()),
      lon: double.tryParse(_lon.text.trim()),
      locationName: _locationName.text.trim().isEmpty
          ? null
          : _locationName.text.trim(),

      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    await ref.read(addCatchLogProvider(log).future);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Catch Log")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _species,
              decoration: const InputDecoration(labelText: "Species"),
              validator: (v) =>
                  v == null || v.isEmpty ? "Enter a species" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Weight (kg)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _length,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Length (cm)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bait,
              decoration: const InputDecoration(labelText: "Bait / Lure"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _environment,
              decoration: const InputDecoration(labelText: "Environment"),
              items: const [
                DropdownMenuItem(value: "beach", child: Text("Beach")),
                DropdownMenuItem(value: "rocks", child: Text("Rocks")),
                DropdownMenuItem(value: "island", child: Text("Island")),
                DropdownMenuItem(value: "estuary", child: Text("Estuary")),
                DropdownMenuItem(value: "offshore", child: Text("Offshore")),
              ],
              onChanged: (val) => setState(() => _environment = val),
              validator: (v) => v == null ? "Select environment" : null,
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _locationName,
              decoration: const InputDecoration(
                labelText: "Location Name",
                border: OutlineInputBorder(),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    decoration: const InputDecoration(labelText: "Latitude"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Required";
                      final val = double.tryParse(v);
                      if (val == null || val < -90 || val > 90)
                        return "Invalid";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lon,
                    decoration: const InputDecoration(labelText: "Longitude"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Required";
                      final val = double.tryParse(v);
                      if (val == null || val < -180 || val > 180)
                        return "Invalid";
                      return null;
                    },
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Pick on Map"),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPickerPage(),
                        ),
                      );
                      if (result != null && result is PickedLocation) {
                        setState(() {
                          _lat.text = result.lat.toStringAsFixed(6);
                          _lon.text = result.lon.toStringAsFixed(6);
                          _locationName.text =
                              result.placeName ?? "Pinned Location";
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text("Use My Location"),
                    onPressed: _useCurrentLocation,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Notes"),
            ),
            const SizedBox(height: 16),
            if (_photo != null)
              Image.file(_photo!, height: 150, fit: BoxFit.cover),
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Add Photo"),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLocationValid ? _submit : null,
              child: const Text("Save Log"),
            ),
          ],
        ),
      ),
    );
  }
}
