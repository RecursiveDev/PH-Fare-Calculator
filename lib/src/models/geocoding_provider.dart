enum GeocodingProvider {
  nominatim,
  locationIQ,
  geoapify;

  String get displayName {
    switch (this) {
      case GeocodingProvider.nominatim:
        return 'Nominatim (OpenStreetMap)';
      case GeocodingProvider.locationIQ:
        return 'LocationIQ';
      case GeocodingProvider.geoapify:
        return 'Geoapify';
    }
  }

  String get description {
    switch (this) {
      case GeocodingProvider.nominatim:
        return 'Free, no API key. Limit: 1 req/sec.';
      case GeocodingProvider.locationIQ:
        return 'Free tier: 5,000 req/day, 2 req/sec.';
      case GeocodingProvider.geoapify:
        return 'Free tier: 3,000 req/day, 5 req/sec.';
    }
  }

  bool get requiresApiKey =>
      this == GeocodingProvider.locationIQ ||
      this == GeocodingProvider.geoapify;
}
