import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/safe_call.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_loader.dart';
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

final forecastServiceProvider = Provider((ref) => ForecastService());

final forecastProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ForecastParams>((ref, params) async {
      AppLoader.show(message: "Fetching forecast...");

      final result = await safeCall(() async {
        final service = ref.read(forecastServiceProvider);
        return await service.getForecast(
          lat: params.lat,
          lon: params.lon,
          start: params.start,
          end: params.end,
        );
      });

      AppLoader.hide();

      if (result == null) {
        throw Exception(
          "Failed to load forecast",
        ); // let error branch handle it
      }

      AppDialog.showSnackBar(
        message: "Forecast loaded successfully",
        type: DialogType.success,
      );

      return {...result, 'locationName': params.locationName};
    });
