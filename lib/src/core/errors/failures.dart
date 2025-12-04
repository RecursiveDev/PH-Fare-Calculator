abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Please check your internet connection.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred.']);
}

class LocationNotFoundFailure extends Failure {
  const LocationNotFoundFailure([super.message = 'Location not found.']);
}

class ConfigSyncFailure extends Failure {
  const ConfigSyncFailure([super.message = 'Configuration sync failed.']);
}

class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure([
    super.message =
        'Location services are disabled. Please enable them in your device settings.',
  ]);
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([
    super.message =
        'Location permission denied. Please grant location access to use this feature.',
  ]);
}

class LocationPermissionDeniedForeverFailure extends Failure {
  const LocationPermissionDeniedForeverFailure([
    super.message =
        'Location permission permanently denied. Please enable it in app settings.',
  ]);
}
