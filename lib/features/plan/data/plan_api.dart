import 'package:supabase_flutter/supabase_flutter.dart';

class PlanApi {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchForecast({
    required double lat,
    required double lon,
    required DateTime start,
    required DateTime end,
  }) async {
    final resp = await _client.functions.invoke(
      'plan-forecast',
      body: {
        'lat': lat,
        'lon': lon,
        'startDate': _d(start),
        'endDate': _d(end),
      },
    );

    // Check HTTP status first
    if (resp.status < 200 || resp.status >= 300) {
      throw Exception('Forecast failed: HTTP ${resp.status} ${resp.data}');
    }

    if (resp.data == null) {
      throw Exception('No data returned from forecast');
    }

    // Ensure response is Map
    if (resp.data is Map<String, dynamic>) {
      return resp.data as Map<String, dynamic>;
    }

    throw Exception('Unexpected response format: ${resp.data}');
  }

  String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
