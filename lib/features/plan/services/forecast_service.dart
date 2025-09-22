import '../data/plan_api.dart';

Future<Map<String, dynamic>> getForecast({
  required double lat,
  required double lon,
  required DateTime start,
  required DateTime end,
}) async {
  final api = PlanApi();
  return api.fetchForecast(lat: lat, lon: lon, start: start, end: end);
}
