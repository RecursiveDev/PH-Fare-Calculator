import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../../models/geocoding_provider.dart';
import '../../models/location.dart';
import '../../core/errors/failures.dart';
import '../../services/settings_service.dart';
import '../offline/offline_mode_service.dart';
import 'geocoding_cache_service.dart';

abstract class GeocodingService {
  Future<List<Location>> getLocations(String query);
  Future<Location> getCurrentLocationAddress();
  Future<Location> getAddressFromLatLng(double latitude, double longitude);
}

@LazySingleton(as: GeocodingService)
class OpenStreetMapGeocodingService implements GeocodingService {
  final http.Client _client;
  final GeocodingCacheService _cacheService;
  final OfflineModeService _offlineModeService;

  static const String _userAgent = 'Pasahe/2.4.0 (com.pasahe)';

  /// Tracks the last request time per provider to enforce their rate limits.
  final Map<GeocodingProvider, DateTime> _lastRequestTime = {};

  OpenStreetMapGeocodingService(
    this._cacheService,
    this._offlineModeService,
  ) : _client = http.Client();

  GeocodingProvider get _provider =>
      SettingsService.geocodingProviderNotifier.value;

  /// Enforces per-provider rate limits by delaying if needed.
  Future<void> _throttle() async {
    const intervals = {
      GeocodingProvider.nominatim: Duration(milliseconds: 1100),
      GeocodingProvider.locationIQ: Duration(milliseconds: 520), // 2 req/sec
      GeocodingProvider.geoapify: Duration(milliseconds: 210),   // 5 req/sec
    };
    final minInterval = intervals[_provider]!;
    final last = _lastRequestTime[_provider];
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minInterval) {
        await Future.delayed(minInterval - elapsed);
      }
    }
    _lastRequestTime[_provider] = DateTime.now();
  }

  // ── URL builders ────────────────────────────────────────────────────────────

  Uri _buildSearchUrl(String query) {
    switch (_provider) {
      case GeocodingProvider.nominatim:
        return Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&addressdetails=1&limit=5&countrycodes=ph',
        );
      case GeocodingProvider.locationIQ:
        return Uri.parse(
          'https://us1.locationiq.com/v1/search'
          '?key=${AppConstants.locationIQApiKey}'
          '&q=${Uri.encodeComponent(query)}'
          '&format=json&addressdetails=1&limit=5&countrycodes=ph',
        );
      case GeocodingProvider.geoapify:
        return Uri.parse(
          'https://api.geoapify.com/v1/geocode/search'
          '?text=${Uri.encodeComponent(query)}'
          '&filter=countrycode:ph'
          '&limit=5'
          '&apiKey=${AppConstants.geoapifyApiKey}',
        );
    }
  }

  Uri _buildReverseUrl(double lat, double lon) {
    switch (_provider) {
      case GeocodingProvider.nominatim:
        return Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=$lat&lon=$lon&format=json&addressdetails=1',
        );
      case GeocodingProvider.locationIQ:
        return Uri.parse(
          'https://us1.locationiq.com/v1/reverse'
          '?key=${AppConstants.locationIQApiKey}'
          '&lat=$lat&lon=$lon&format=json&addressdetails=1',
        );
      case GeocodingProvider.geoapify:
        return Uri.parse(
          'https://api.geoapify.com/v1/geocode/reverse'
          '?lat=$lat&lon=$lon'
          '&apiKey=${AppConstants.geoapifyApiKey}',
        );
    }
  }

  Map<String, String> get _headers => {'User-Agent': _userAgent};

  // ── Response parsers ────────────────────────────────────────────────────────

  /// Parses a forward-geocoding response for the active provider.
  List<Location> _parseSearchResponse(String body) {
    switch (_provider) {
      case GeocodingProvider.nominatim:
      case GeocodingProvider.locationIQ:
        // Both return Nominatim-compatible JSON arrays.
        final List<dynamic> data = json.decode(body);
        return data.map((j) => Location.fromJson(j)).toList();

      case GeocodingProvider.geoapify:
        // Returns GeoJSON FeatureCollection.
        final Map<String, dynamic> data = json.decode(body);
        final features = data['features'] as List<dynamic>? ?? [];
        return features.map((f) {
          final props = f['properties'] as Map<String, dynamic>;
          final coords = (f['geometry'] as Map<String, dynamic>)['coordinates']
              as List<dynamic>;
          return Location(
            name: props['formatted'] as String? ?? 'Unknown Location',
            latitude: (coords[1] as num).toDouble(),
            longitude: (coords[0] as num).toDouble(),
          );
        }).toList();
    }
  }

  /// Parses a reverse-geocoding response for the active provider.
  Location _parseReverseResponse(String body, double lat, double lon) {
    switch (_provider) {
      case GeocodingProvider.nominatim:
      case GeocodingProvider.locationIQ:
        final Map<String, dynamic> data = json.decode(body);
        final address = data['address'] as Map<String, dynamic>?;
        String displayName =
            data['display_name'] as String? ?? 'Unknown Location';
        if (address != null) {
          final road = address['road'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String? ??
              address['municipality'] as String?;
          if (road != null && city != null) {
            displayName = '$road, $city';
          } else if (suburb != null && city != null) {
            displayName = '$suburb, $city';
          } else if (city != null) {
            displayName = city;
          }
        }
        return Location(name: displayName, latitude: lat, longitude: lon);

      case GeocodingProvider.geoapify:
        final Map<String, dynamic> data = json.decode(body);
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isEmpty) {
          return Location(
            name: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
            latitude: lat,
            longitude: lon,
          );
        }
        final props =
            (features.first as Map<String, dynamic>)['properties']
                as Map<String, dynamic>;
        return Location(
          name: props['formatted'] as String? ?? 'Unknown Location',
          latitude: lat,
          longitude: lon,
        );
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  @override
  Future<List<Location>> getLocations(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final coordsLocation = _parseCoordinates(trimmedQuery);
    if (coordsLocation != null) return [coordsLocation];

    final cacheKey = '${_provider.name}:${trimmedQuery.toLowerCase()}';
    final cachedResults = await _cacheService.getCachedResults(cacheKey);

    if (_offlineModeService.isCurrentlyOffline) {
      if (cachedResults != null && cachedResults.isNotEmpty) {
        return cachedResults;
      }
      throw const NetworkFailure(
        'Offline: Search results not cached for this location.',
      );
    }

    if (cachedResults != null && cachedResults.isNotEmpty) {
      return cachedResults;
    }

    _validateApiKey();

    try {
      await _throttle();
      final response = await _client.get(_buildSearchUrl(trimmedQuery),
          headers: _headers);

      if (response.statusCode == 200) {
        final results = _parseSearchResponse(response.body);
        if (results.isEmpty) throw LocationNotFoundFailure();
        await _cacheService.cacheResults(cacheKey, results);
        return results;
      } else if (response.statusCode == 429) {
        throw const RateLimitFailure();
      } else {
        throw ServerFailure(
            'Geocoding search failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure();
    }
  }

  @override
  Future<Location> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    final cacheKey =
        '${_provider.name}:${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    final cachedResults = await _cacheService.getCachedResults(cacheKey);
    if (cachedResults != null && cachedResults.isNotEmpty) {
      return cachedResults.first;
    }

    if (_offlineModeService.isCurrentlyOffline) {
      return Location(
        name: '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
        latitude: latitude,
        longitude: longitude,
      );
    }

    _validateApiKey();

    try {
      await _throttle();
      final response = await _client.get(
          _buildReverseUrl(latitude, longitude),
          headers: _headers);

      if (response.statusCode == 429) {
        throw const RateLimitFailure();
      } else if (response.statusCode == 200) {
        final location =
            _parseReverseResponse(response.body, latitude, longitude);
        await _cacheService.cacheResults(cacheKey, [location]);
        return location;
      } else {
        throw ServerFailure(
            'Reverse geocoding failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure();
    }
  }

  @override
  Future<Location> getCurrentLocationAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw LocationServiceDisabledFailure();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionDeniedFailure();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedForeverFailure();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      return await getAddressFromLatLng(
          position.latitude, position.longitude);
    } on LocationServiceDisabledFailure {
      rethrow;
    } on LocationPermissionDeniedFailure {
      rethrow;
    } on LocationPermissionDeniedForeverFailure {
      rethrow;
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Throws if the current provider requires an API key that hasn't been set.
  void _validateApiKey() {
    if (_provider == GeocodingProvider.locationIQ &&
        AppConstants.locationIQApiKey == 'YOUR_LOCATIONIQ_API_KEY') {
      throw const ServerFailure(
          'LocationIQ API key not set. Add it in AppConstants.');
    }
    if (_provider == GeocodingProvider.geoapify &&
        AppConstants.geoapifyApiKey == 'YOUR_GEOAPIFY_API_KEY') {
      throw const ServerFailure(
          'Geoapify API key not set. Add it in AppConstants.');
    }
  }

  Location? _parseCoordinates(String query) {
    final parts = query.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat != null &&
          lon != null &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180) {
        return Location(
          name: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
          latitude: lat,
          longitude: lon,
        );
      }
    }
    return null;
  }
}
