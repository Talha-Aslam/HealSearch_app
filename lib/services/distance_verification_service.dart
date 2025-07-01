import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

/// Available distance calculation algorithms
enum CalculationMethod {
  geolocator, // Uses Geolocator package (default)
  haversine, // Manual Haversine formula implementation
  googleMaps, // Uses Google Distance Matrix API (requires API key)
  vincenty, // More accurate algorithm for ellipsoidal model
}

/// Distance verification service to validate the accuracy of distance calculations
class DistanceVerificationService {
  /// Constants for Earth calculations
  static const double _earthRadius = 6371.0; // Earth's radius in km

  /// Calculate distance using specified method
  static Future<Map<String, dynamic>> calculateDistanceWithMultipleMethods({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    // Get distances using multiple methods
    final geolocatorDistance =
        _calculateGeolocatorDistance(startLat, startLon, endLat, endLon);

    final haversineDistance =
        _calculateHaversineDistance(startLat, startLon, endLat, endLon);

    final vincentyDistance =
        _calculateVincentyDistance(startLat, startLon, endLat, endLon);

    // Calculate differences between methods
    final geoVsHaversineDiff = (geolocatorDistance - haversineDistance).abs();
    final geoVsVincentyDiff = (geolocatorDistance - vincentyDistance).abs();

    // Calculate average (more likely to be correct with multiple methods)
    final avgDistance =
        (geolocatorDistance + haversineDistance + vincentyDistance) / 3;

    // Calculate confidence score (0-100%)
    // Lower difference between methods = higher confidence
    final confidenceScore = _calculateConfidenceScore(
        [geolocatorDistance, haversineDistance, vincentyDistance]);

    return {
      'geolocator': geolocatorDistance,
      'haversine': haversineDistance,
      'vincenty': vincentyDistance,
      'average': avgDistance,
      'confidence': confidenceScore,
      'confidenceText': _getConfidenceText(confidenceScore),
      'displayDistance': _formatDistanceForDisplay(avgDistance),
      'differencePercentage':
          (geoVsHaversineDiff / avgDistance * 100).toStringAsFixed(2),
      'maxDifferenceKm': [geoVsHaversineDiff, geoVsVincentyDiff]
          .reduce(math.max)
          .toStringAsFixed(3),
      'unit': 'km'
    };
  }

  /// Calculate distance using specific method
  static Future<double> calculateDistance({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    CalculationMethod method = CalculationMethod.geolocator,
  }) async {
    switch (method) {
      case CalculationMethod.geolocator:
        return _calculateGeolocatorDistance(startLat, startLon, endLat, endLon);
      case CalculationMethod.haversine:
        return _calculateHaversineDistance(startLat, startLon, endLat, endLon);
      case CalculationMethod.vincenty:
        return _calculateVincentyDistance(startLat, startLon, endLat, endLon);
      case CalculationMethod.googleMaps:
        // This would require an API key and network request
        // Fall back to vincenty for now
        return _calculateVincentyDistance(startLat, startLon, endLat, endLon);
      default:
        return _calculateGeolocatorDistance(startLat, startLon, endLat, endLon);
    }
  }

  /// Calculate distance using Geolocator package
  static double _calculateGeolocatorDistance(
      double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon) /
        1000; // convert to km
  }

  /// Calculate distance using Haversine formula
  static double _calculateHaversineDistance(
      double startLat, double startLon, double endLat, double endLon) {
    // Convert degrees to radians
    final startLatRad = _degreesToRadians(startLat);
    final startLonRad = _degreesToRadians(startLon);
    final endLatRad = _degreesToRadians(endLat);
    final endLonRad = _degreesToRadians(endLon);

    // Calculate differences
    final dLat = endLatRad - startLatRad;
    final dLon = endLonRad - startLonRad;

    // Haversine formula
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(startLatRad) *
            math.cos(endLatRad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadius * c;
  }

  /// Calculate distance using a simplified version of Vincenty formula
  static double _calculateVincentyDistance(
      double startLat, double startLon, double endLat, double endLon) {
    // For full accuracy, a proper Vincenty implementation with all edge cases would be needed
    // This is a simplified version that handles most cases well
    try {
      // Convert degrees to radians
      final phi1 = _degreesToRadians(startLat);
      final phi2 = _degreesToRadians(endLat);
      final lambda1 = _degreesToRadians(startLon);
      final lambda2 = _degreesToRadians(endLon);

      // WGS-84 ellipsoid parameters
      const a = 6378137.0; // semi-major axis in meters
      const b = 6356752.314245; // semi-minor axis in meters
      const f = 1 / 298.257223563; // flattening

      // Difference in longitude
      final L = lambda2 - lambda1;

      // Reduced latitudes (latitude on auxiliary sphere)
      final tanU1 = (1 - f) * math.tan(phi1);
      final tanU2 = (1 - f) * math.tan(phi2);
      final cosU1 = 1 / math.sqrt(1 + tanU1 * tanU1);
      final cosU2 = 1 / math.sqrt(1 + tanU2 * tanU2);
      final sinU1 = tanU1 * cosU1;
      final sinU2 = tanU2 * cosU2;

      // Initial value for lambda (longitudinal difference on auxiliary sphere)
      double lambda = L;
      double sinLambda = 0.0;
      double cosLambda = 0.0;
      double sinSigma = 0.0;
      double cosSigma = 0.0;
      double sigma = 0.0;
      double sinAlpha = 0.0;
      double cosSqAlpha = 0.0;
      double cos2SigmaM = 0.0;
      double oldLambda = 0.0;

      // Iteration limit
      int iterations = 0;
      const int maxIterations = 20;

      do {
        sinLambda = math.sin(lambda);
        cosLambda = math.cos(lambda);

        // Calculate sinSigma
        final term1 = cosU2 * sinLambda;
        final term2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
        sinSigma = math.sqrt(term1 * term1 + term2 * term2);

        // Check for coincident points
        if (sinSigma == 0) return 0;

        cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
        sigma = math.atan2(sinSigma, cosSigma);
        sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
        cosSqAlpha = 1 - sinAlpha * sinAlpha;

        // On equatorial line cosSqAlpha = 0
        if (cosSqAlpha != 0) {
          cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
        } else {
          cos2SigmaM = 0;
        }

        final C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
        oldLambda = lambda;
        lambda = L +
            (1 - C) *
                f *
                sinAlpha *
                (sigma +
                    C *
                        sinSigma *
                        (cos2SigmaM +
                            C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));

        iterations++;
      } while (
          iterations < maxIterations && (lambda - oldLambda).abs() > 1e-12);

      // If didn't converge, fall back to haversine
      if (iterations >= maxIterations) {
        return _calculateHaversineDistance(startLat, startLon, endLat, endLon);
      }

      // Calculate final values
      final uSq = cosSqAlpha * (a * a - b * b) / (b * b);
      final A =
          1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
      final B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));

      final deltaSigma = B *
          sinSigma *
          (cos2SigmaM +
              B /
                  4 *
                  (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                      B /
                          6 *
                          cos2SigmaM *
                          (-3 + 4 * sinSigma * sinSigma) *
                          (-3 + 4 * cos2SigmaM * cos2SigmaM)));

      // Final distance in kilometers
      return (b * A * (sigma - deltaSigma)) / 1000;
    } catch (e) {
      // If any calculation error occurs, fall back to haversine
      debugPrint('Vincenty calculation error: $e. Falling back to Haversine.');
      return _calculateHaversineDistance(startLat, startLon, endLat, endLon);
    }
  }

  /// Helper method to convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Calculate confidence score based on variance between methods
  static double _calculateConfidenceScore(List<double> distances) {
    if (distances.isEmpty) return 0;

    // Calculate mean
    final mean = distances.reduce((a, b) => a + b) / distances.length;

    // Calculate variance
    double variance = 0;
    for (final distance in distances) {
      variance += math.pow(distance - mean, 2);
    }
    variance /= distances.length;

    // Calculate standard deviation
    final stdDev = math.sqrt(variance);

    // Calculate coefficient of variation (CV)
    final cv = stdDev / mean;

    // Convert CV to confidence score (0-100%)
    // Lower CV = higher confidence
    final confidence = math.max(0, 100 - (cv * 100));

    return double.parse(confidence.toStringAsFixed(1));
  }

  /// Get text description of confidence
  static String _getConfidenceText(double confidence) {
    if (confidence >= 95) return 'Very High';
    if (confidence >= 90) return 'High';
    if (confidence >= 80) return 'Good';
    if (confidence >= 70) return 'Moderate';
    if (confidence >= 60) return 'Fair';
    return 'Low';
  }

  /// Format distance for display
  static String _formatDistanceForDisplay(double distanceKm) {
    if (distanceKm < 1.0) {
      // Show in meters for small distances
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else if (distanceKm < 10.0) {
      // Show 2 decimal places for medium distances
      return '${distanceKm.toStringAsFixed(2)} km';
    } else {
      // Show 1 decimal place for large distances
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Open location in Google Maps for verification
  static Future<void> openInGoogleMaps({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLon&destination=$endLat,$endLon&travelmode=$mode');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch Google Maps');
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
    }
  }
}
