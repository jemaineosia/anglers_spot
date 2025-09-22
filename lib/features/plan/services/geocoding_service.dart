// lib/features/plan/services/geocoding_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodingService {
  static const _apiKey = 'da4d5ca1d4b84e4294ad281dda55487f';
  static const _baseUrl = 'https://api.opencagedata.com/geocode/v1/json';

  // Forward geocoding: Place name -> lat/lon
  Future<Map<String, double>?> fetchCoordinates(String place) async {
    final url = Uri.parse("$_baseUrl?q=$place&key=$_apiKey&limit=1");

    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final geometry = data['results'][0]['geometry'];
        return {
          'lat': geometry['lat'] as double,
          'lon': geometry['lng'] as double,
        };
      }
    }
    return null;
  }

  // Reverse geocoding: Lat/Lon -> place name
  Future<String?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      "$_baseUrl?q=$lat,$lon&key=$_apiKey&limit=1&pretty=1",
    );

    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        return data['results'][0]['formatted'] as String;
      }
    }
    return null;
  }
}
