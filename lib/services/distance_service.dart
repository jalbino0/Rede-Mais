import 'dart:math' as math;

class DistanceService {
  DistanceService._();

  static const double defaultRadiusKm = 3;

  static double calculateDistanceKm({
    required double latitude1,
    required double longitude1,
    required double latitude2,
    required double longitude2,
  }) {
    const earthRadiusKm = 6371.0;

    final latitudeDifference = _degreesToRadians(
      latitude2 - latitude1,
    );

    final longitudeDifference = _degreesToRadians(
      longitude2 - longitude1,
    );

    final latitude1Radians = _degreesToRadians(
      latitude1,
    );

    final latitude2Radians = _degreesToRadians(
      latitude2,
    );

    final a =
        math.sin(latitudeDifference / 2) *
            math.sin(latitudeDifference / 2) +
        math.cos(latitude1Radians) *
            math.cos(latitude2Radians) *
            math.sin(longitudeDifference / 2) *
            math.sin(longitudeDifference / 2);

    final c = 2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(1 - a),
        );

    return earthRadiusKm * c;
  }

  static bool isWithinRadius({
    required double userLatitude,
    required double userLongitude,
    required double requestLatitude,
    required double requestLongitude,
    double radiusKm = defaultRadiusKm,
  }) {
    if (!_hasValidCoordinates(
      latitude: userLatitude,
      longitude: userLongitude,
    )) {
      return false;
    }

    if (!_hasValidCoordinates(
      latitude: requestLatitude,
      longitude: requestLongitude,
    )) {
      return false;
    }

    final distance = calculateDistanceKm(
      latitude1: userLatitude,
      longitude1: userLongitude,
      latitude2: requestLatitude,
      longitude2: requestLongitude,
    );

    return distance <= radiusKm;
  }

  static bool _hasValidCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite) {
      return false;
    }

    if (latitude < -90 ||
        latitude > 90) {
      return false;
    }

    if (longitude < -180 ||
        longitude > 180) {
      return false;
    }

    if (latitude == 0 &&
        longitude == 0) {
      return false;
    }

    return true;
  }

  static double _degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180;
  }
}