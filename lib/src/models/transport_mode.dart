enum TransportMode {
  jeepney,
  bus,
  taxi,
  train,
  ferry,
  tricycle,
  uvExpress;

  /// Get the category for grouping transport modes
  String get category {
    switch (this) {
      case TransportMode.jeepney:
      case TransportMode.bus:
      case TransportMode.taxi:
      case TransportMode.tricycle:
      case TransportMode.uvExpress:
        return 'road';
      case TransportMode.train:
        return 'rail';
      case TransportMode.ferry:
        return 'water';
    }
  }

  /// Get the default visibility state for this transport mode
  bool get isVisible => true;

  String get displayName {
    switch (this) {
      case TransportMode.jeepney:
        return 'Jeepney';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.taxi:
        return 'Taxi';
      case TransportMode.train:
        return 'Train';
      case TransportMode.ferry:
        return 'Ferry';
      case TransportMode.tricycle:
        return 'Tricycle';
      case TransportMode.uvExpress:
        return 'UV Express';
    }
  }

  /// Get a tourist-friendly description of the transport mode
  String get description {
    switch (this) {
      case TransportMode.jeepney:
        return 'Iconic colorful open-air vehicle, the most popular form of public transport in the Philippines. Great for short to medium distances.';
      case TransportMode.bus:
        return 'Large public buses for longer routes. Choose between traditional (non-aircon), aircon, or premium/deluxe options.';
      case TransportMode.taxi:
        return 'Metered taxis available throughout Metro Manila. White taxis for general use, yellow for airport service. Also includes app-based rides.';
      case TransportMode.train:
        return 'Metro Manila\'s rapid transit system including LRT (Light Rail Transit), MRT (Metro Rail Transit), and PNR (Philippine National Railways).';
      case TransportMode.ferry:
        return 'Water transport connecting islands and coastal areas. Essential for inter-island travel in the Philippines.';
      case TransportMode.tricycle:
        return 'Motorcycle with sidecar, perfect for short distances and narrow streets. Fares are often negotiable.';
      case TransportMode.uvExpress:
        return 'Modern air-conditioned vans operating on fixed routes. Faster than jeepneys with comfortable seating.';
    }
  }

  static TransportMode fromString(String mode) {
    return TransportMode.values.firstWhere(
      (e) => e.displayName.toLowerCase() == mode.toLowerCase(),
      orElse: () => TransportMode.jeepney, // Default fallback
    );
  }
}