import 'dart:math';
import 'package:injectable/injectable.dart';

import '../../models/route_result.dart';
import 'routing_service.dart';

@LazySingleton(as: RoutingService)
class HaversineRoutingService implements RoutingService {
  static const double _earthRadius = 6371000; // Radius in meters

  /// Calculates the straight-line distance (Haversine formula) in meters.
  /// Returns a RouteResult with distance but no geometry (empty list).
  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final dLat = _toRadians(destLat - originLat);
    final dLng = _toRadians(destLng - originLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(originLat)) *
            cos(_toRadians(destLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = _earthRadius * c;

    // Haversine doesn't provide route geometry, return empty list
    return RouteResult.withoutGeometry(distance: distance);
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
