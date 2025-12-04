import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/errors/failures.dart';
import '../../models/route_result.dart';
import 'routing_service.dart';

// @LazySingleton(as: RoutingService) // Disabled for privacy
class OsrmRoutingService implements RoutingService {
  static const String _baseUrl =
      'http://router.project-osrm.org/route/v1/driving';

  /// Fetches the route information between two coordinates.
  ///
  /// [originLat], [originLng]: Latitude and Longitude of the starting point.
  /// [destLat], [destLng]: Latitude and Longitude of the destination.
  ///
  /// Returns a RouteResult containing distance, duration, and geometry.
  /// Throws an exception if the request fails or no route is found.
  @override
  Future<RouteResult> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    // OSRM expects {longitude},{latitude}
    // Request geometries as geojson for easier parsing
    final requestUrl =
        '$_baseUrl/$originLng,$originLat;$destLng,$destLat?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num?)?.toDouble();

          // Parse geometry from GeoJSON format
          final List<LatLng> geometry = [];
          if (route['geometry'] != null &&
              route['geometry']['coordinates'] != null) {
            final coordinates = route['geometry']['coordinates'] as List;
            for (final coord in coordinates) {
              if (coord is List && coord.length >= 2) {
                // GeoJSON format is [longitude, latitude]
                geometry.add(
                  LatLng(
                    (coord[1] as num).toDouble(),
                    (coord[0] as num).toDouble(),
                  ),
                );
              }
            }
          }

          return RouteResult(
            distance: distance,
            duration: duration,
            geometry: geometry,
          );
        } else {
          throw ServerFailure(
            'No route found or OSRM returned error: ${data['code']}',
          );
        }
      } else {
        throw ServerFailure(
          'Failed to load route. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error fetching route: $e');
    }
  }
}
