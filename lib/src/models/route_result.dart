import 'package:latlong2/latlong.dart';

/// Represents the result of a routing calculation.
///
/// Contains both the distance and the geometry (polyline points) of the route.
class RouteResult {
  /// The total distance of the route in meters.
  final double distance;

  /// The duration of the route in seconds (if available).
  final double? duration;

  /// The list of coordinates that form the route geometry (polyline).
  /// For services that don't provide geometry (like Haversine), this will be empty.
  final List<LatLng> geometry;

  RouteResult({required this.distance, this.duration, required this.geometry});

  /// Creates a RouteResult with empty geometry (for fallback services).
  RouteResult.withoutGeometry({required this.distance, this.duration})
    : geometry = [];
}
