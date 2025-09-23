import '../data/plan_api.dart';

class ForecastService {
  final PlanApi _api = PlanApi();

  Future<Map<String, dynamic>> getForecast({
    required double lat,
    required double lon,
    required DateTime start,
    required DateTime end,
  }) async {
    return await _api.fetchForecast(lat: lat, lon: lon, start: start, end: end);
  }
}
