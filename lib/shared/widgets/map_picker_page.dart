import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickedLocation {
  final double lat;
  final double lon;
  final String? placeName;

  PickedLocation(this.lat, this.lon, this.placeName);
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _selected;
  String? _placeName;
  bool _isMapReady = false;

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _placeName = [
            p.name,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((e) => e != null && e.isNotEmpty).join(", ");
        });
      }
    } catch (e) {
      debugPrint("Reverse geocode failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        actions: [
          if (_selected != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(
                  context,
                  PickedLocation(
                    _selected!.latitude,
                    _selected!.longitude,
                    _placeName,
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(1.3521, 103.8198), // Singapore center
              zoom: 11,
            ),
            onTap: (pos) {
              setState(() => _selected = pos);
              _reverseGeocode(pos);
            },
            markers: _selected != null
                ? {Marker(markerId: const MarkerId("sel"), position: _selected!)}
                : {},
            onMapCreated: (controller) {
              setState(() => _isMapReady = true);
            },
          ),
          if (!_isMapReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: _selected != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _placeName ?? "Loading place name...",
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}
