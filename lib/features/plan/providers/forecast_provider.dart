import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/forecast_service.dart';

class ForecastParams {
  final double lat;
  final double lon;
  final DateTime start;
  final DateTime end;
  final String locationName;

  const ForecastParams({
    required this.lat,
    required this.lon,
    required this.start,
    required this.end,
    required this.locationName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastParams &&
          lat == other.lat &&
          lon == other.lon &&
          start == other.start &&
          end == other.end &&
          locationName == other.locationName;

  @override
  int get hashCode => Object.hash(lat, lon, start, end, locationName);
}

final forecastProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ForecastParams>((ref, params) async {
      final forecast = await getForecast(
        lat: params.lat,
        lon: params.lon,
        start: params.start,
        end: params.end,
      );

      // Attach the location name into the payload so ResultScreen can show it
      return {...forecast, 'locationName': params.locationName};
    });
