import 'package:injectable/injectable.dart';
import '../models/transport_mode.dart';
import '../models/fare_result.dart';

enum SortCriteria { priceAsc, priceDesc, durationAsc, durationDesc }

@lazySingleton
class FareComparisonService {
  /// Analyzes a route based on distance and location to recommend transport modes.
  ///
  /// [distanceInMeters]: The total distance of the route in meters.
  /// [isMetroManila]: Whether the route is within Metro Manila (simplistic check for now).
  ///
  /// Returns a list of recommended [TransportMode]s.
  List<TransportMode> recommendModes({
    required double distanceInMeters,
    bool isMetroManila = true,
  }) {
    final List<TransportMode> recommendedModes = [];
    final distanceInKm = distanceInMeters / 1000.0;

    // Short distance (< 5km): Jeepney, Tricycle
    if (distanceInKm < 5.0) {
      recommendedModes.add(TransportMode.jeepney);
      recommendedModes.add(TransportMode.tricycle);
      // Taxi is always an option
      recommendedModes.add(TransportMode.taxi);
    }
    // Medium distance (5km - 20km): Bus, UV Express, Taxi, Jeepney (if < 10km)
    else if (distanceInKm >= 5.0 && distanceInKm < 20.0) {
      recommendedModes.add(TransportMode.bus);
      recommendedModes.add(TransportMode.uvExpress);
      recommendedModes.add(TransportMode.taxi);
      if (distanceInKm < 10.0) {
        recommendedModes.add(TransportMode.jeepney);
      }
    }
    // Long distance (>= 20km): Bus, UV Express
    else {
      recommendedModes.add(TransportMode.bus);
      recommendedModes.add(TransportMode.uvExpress);
      // Taxi is less likely but possible (expensive)
      recommendedModes.add(TransportMode.taxi);
    }

    // Metro Manila specific logic
    if (isMetroManila) {
      // Trains are mostly relevant in Metro Manila
      if (distanceInKm > 2.0) {
        recommendedModes.add(TransportMode.train);
      }
      // Ferries (Pasig River) - very specific, added as option if in MM
      recommendedModes.add(TransportMode.ferry);
    } else {
      // Provincial logic (can be expanded later)
      // Remove train if strictly not in MM (though some trains exist outside, e.g. PNR south)
      // For now, keep it simple.
    }

    // Deduplicate just in case
    return recommendedModes.toSet().toList();
  }

  /// Sorts a list of fare results based on the specified criteria.
  ///
  /// [results]: The list of FareResult objects to sort.
  /// [criteria]: The sorting criteria (price or duration, ascending or descending).
  ///
  /// Returns a new sorted list of FareResult objects.
  List<FareResult> sortFares(List<FareResult> results, SortCriteria criteria) {
    final sortedResults = List<FareResult>.from(results);

    switch (criteria) {
      case SortCriteria.priceAsc:
        sortedResults.sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case SortCriteria.priceDesc:
        sortedResults.sort((a, b) => b.totalFare.compareTo(a.totalFare));
        break;
      case SortCriteria.durationAsc:
        // Note: Duration sorting would require duration data in FareResult
        // For now, we'll use the same logic as price or throw
        throw UnimplementedError(
          'Duration sorting requires duration data in FareResult',
        );
      case SortCriteria.durationDesc:
        // Note: Duration sorting would require duration data in FareResult
        throw UnimplementedError(
          'Duration sorting requires duration data in FareResult',
        );
    }

    return sortedResults;
  }

  /// Compares multiple transport modes and returns fare results.
  ///
  /// This method is a convenience wrapper that can be used to compare
  /// fares across different transport modes with passenger count support.
  ///
  /// Note: The actual fare calculation should be done by HybridEngine.
  /// This method primarily provides a consistent interface for fare comparison.
  Future<List<FareResult>> compareFares({
    required List<FareResult> fareResults,
    int passengerCount = 1,
  }) async {
    // This method currently just returns the results as-is since the actual
    // calculation with passengerCount happens in HybridEngine.
    // It's here to provide a future extension point for more complex comparison logic.
    return fareResults;
  }
}
