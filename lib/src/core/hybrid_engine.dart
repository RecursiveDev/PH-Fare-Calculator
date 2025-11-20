import '../models/fare_formula.dart';
import '../services/osrm_api_service.dart';

class HybridEngine {
  final OsrmApiService _osrmApiService;

  HybridEngine(this._osrmApiService);

  /// Calculates the dynamic fare based on road distance and a specific fare formula.
  ///
  /// [originLat], [originLng]: Latitude and Longitude of the starting point.
  /// [destLat], [destLng]: Latitude and Longitude of the destination.
  /// [formula]: The pricing formula to apply (base fare, rate per km, etc.).
  /// [isProvincial]: Whether to apply provincial variance (20% increase).
  ///
  /// Returns the calculated fare as a [double].
  /// Throws an exception if route calculation fails.
  Future<double> calculateDynamicFare({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required FareFormula formula,
    bool isProvincial = false,
  }) async {
    try {
      // 1. Get road distance in meters from OSRM
      final distanceInMeters = await _osrmApiService.getRoute(
        originLat,
        originLng,
        destLat,
        destLng,
      );

      // 2. Convert to kilometers
      final distanceInKm = distanceInMeters / 1000.0;

      // 3. Apply Variance (1.15) as per PRD
      // Formula: (Road Distance x 1.15 Variance) * Rate + Base Fare
      final adjustedDistance = distanceInKm * 1.15;

      // 4. Calculate Total Fare
      double totalFare = formula.baseFare + (adjustedDistance * formula.perKmRate);

      // 4.1 Apply Provincial Variance if enabled
      if (isProvincial) {
        totalFare *= 1.20;
      }

      // 5. Apply Minimum Fare check if applicable
      if (formula.minimumFare != null && totalFare < formula.minimumFare!) {
        totalFare = formula.minimumFare!;
      }

      return totalFare;
    } catch (e) {
      // Re-throw the error to be handled by the UI or caller
      throw Exception('Failed to calculate dynamic fare: $e');
    }
  }
}