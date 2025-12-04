import '../../models/route_result.dart';

/// Abstract interface for routing services that calculate distances between locations.
///
/// This interface allows for different routing service implementations to be swapped
/// out without affecting the core business logic of the fare calculation engine.
abstract class RoutingService {
  /// Calculates the route between two coordinate pairs.
  ///
  /// [originLat], [originLng]: Latitude and Longitude of the starting point.
  /// [destLat], [destLng]: Latitude and Longitude of the destination.
  ///
  /// Returns a RouteResult containing distance, duration (optional), and geometry.
  /// Throws an exception if the request fails or no route is found.
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  );
}
