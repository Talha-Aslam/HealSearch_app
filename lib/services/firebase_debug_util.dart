import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'distance_verification_service.dart';
import 'pharmacy_cache_service.dart';

/// Debug utility to inspect Firebase data structure
class FirebaseDebugUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug all pharmacies in the database
  static Future<void> debugPharmacies() async {
    try {
      debugPrint('🐛 === DEBUGGING PHARMACIES COLLECTION ===');
      final snapshot = await _firestore.collection('pharmacies').get();
      debugPrint('📊 Total pharmacies found: ${snapshot.docs.length}');

      int pharmaciesWithLocation = 0;
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        debugPrint('🏥 Pharmacy $i:');
        debugPrint('   Document ID: ${doc.id}');
        debugPrint('   Name: ${data['name']}');
        debugPrint('   ShopId: ${data['shopId']}');

        // Check for location data
        if (data['location'] != null) {
          pharmaciesWithLocation++;
          final location = data['location'] as GeoPoint;
          debugPrint(
              '   Location: ${location.latitude}, ${location.longitude}');
        } else {
          debugPrint('   ⚠️ No location data');
        }

        debugPrint('   All data: $data');
        debugPrint('');
      }
      debugPrint('📊 Pharmacies with location: $pharmaciesWithLocation');
      debugPrint(
          '📊 Pharmacies without location: ${snapshot.docs.length - pharmaciesWithLocation}');
      debugPrint('🐛 === END PHARMACIES DEBUG ===');
    } catch (e) {
      debugPrint('❌ Error debugging pharmacies: $e');
    }
  }

  /// Debug sample products to see their shopId values
  static Future<void> debugProducts({int limit = 5}) async {
    try {
      debugPrint('🐛 === DEBUGGING PRODUCTS COLLECTION ===');
      final snapshot =
          await _firestore.collection('products').limit(limit).get();
      debugPrint('📊 Sample products found: ${snapshot.docs.length}');

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        debugPrint('💊 Product $i:');
        debugPrint('   Document ID: ${doc.id}');
        debugPrint('   Name: ${data['name']}');
        debugPrint('   ShopId: ${data['shopId']}');
        debugPrint('   All data: $data');
        debugPrint('');
      }
      debugPrint('🐛 === END PRODUCTS DEBUG ===');
    } catch (e) {
      debugPrint('❌ Error debugging products: $e');
    }
  }

  /// Debug pharmacy cache state
  static Future<void> debugCacheState() async {
    try {
      debugPrint('🔍 === DEBUGGING PHARMACY CACHE ===');

      await PharmacyCacheService.initializeCache();
      final stats = PharmacyCacheService.getCacheStats();

      debugPrint('📊 Cache initialized: ${stats['initialized']}');
      debugPrint('📊 Name entries: ${stats['nameEntries']}');
      debugPrint('📊 Location entries: ${stats['locationEntries']}');

      debugPrint('🔍 === END CACHE DEBUG ===');
    } catch (e) {
      debugPrint('❌ Error debugging cache: $e');
    }
  }

  /// Run complete debugging
  static Future<void> debugAll() async {
    await debugPharmacies();
    await debugProducts();
    await debugCacheState();
  }

  /// Verify distance calculation between two points
  static Future<Map<String, dynamic>> verifyDistanceCalculation({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    try {
      debugPrint('🔍 === VERIFYING DISTANCE CALCULATION ===');
      debugPrint('📍 Start: $startLat, $startLon');
      debugPrint('📍 End: $endLat, $endLon');

      // Calculate distance using multiple methods
      final results = await DistanceVerificationService
          .calculateDistanceWithMultipleMethods(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
      );

      debugPrint('📏 Geolocator distance: ${results['geolocator']} km');
      debugPrint('📏 Haversine distance: ${results['haversine']} km');
      debugPrint('📏 Vincenty distance: ${results['vincenty']} km');
      debugPrint('📏 Average distance: ${results['average']} km');
      debugPrint(
          '📏 Confidence score: ${results['confidence']} (${results['confidenceText']})');
      debugPrint('📏 Max difference: ${results['maxDifferenceKm']} km');
      debugPrint('🔍 === END VERIFICATION ===');

      return results;
    } catch (e) {
      debugPrint('❌ Error verifying distance calculation: $e');
      return {'error': e.toString()};
    }
  }

  /// Test distance calculation with current user location
  static Future<Map<String, dynamic>> testDistanceToPharmacy({
    required String pharmacyId,
  }) async {
    try {
      debugPrint('🔍 === TESTING DISTANCE TO PHARMACY $pharmacyId ===');

      // Get pharmacy location
      final doc =
          await _firestore.collection('pharmacies').doc(pharmacyId).get();
      if (!doc.exists) {
        debugPrint('⚠️ Pharmacy not found');
        return {'error': 'Pharmacy not found'};
      }

      final data = doc.data()!;
      if (data['location'] == null) {
        debugPrint('⚠️ Pharmacy has no location data');
        return {'error': 'Pharmacy has no location data'};
      }

      final location = data['location'] as GeoPoint;
      debugPrint(
          '📍 Pharmacy location: ${location.latitude}, ${location.longitude}');

      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      debugPrint(
          '📍 User location: ${position.latitude}, ${position.longitude}');

      // Verify distance
      final result = await verifyDistanceCalculation(
        startLat: position.latitude,
        startLon: position.longitude,
        endLat: location.latitude,
        endLon: location.longitude,
      );

      return {
        ...result,
        'pharmacyName': data['name'] ?? 'Unknown Pharmacy',
        'pharmacyId': pharmacyId,
      };
    } catch (e) {
      debugPrint('❌ Error testing distance to pharmacy: $e');
      return {'error': e.toString()};
    }
  }
}
