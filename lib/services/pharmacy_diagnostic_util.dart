import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'pharmacy_cache_service.dart';

/// Utility class for diagnosing issues with pharmacy data
class PharmacyDiagnosticUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check for duplicate pharmacy coordinates
  static Future<Map<String, dynamic>> checkForDuplicateCoordinates() async {
    try {
      debugPrint('🔍 CHECKING FOR DUPLICATE PHARMACY COORDINATES');

      // Ensure cache is initialized
      await PharmacyCacheService.initializeCache();

      // Get cache statistics
      final cacheStats = PharmacyCacheService.getCacheStats();
      final locationCache =
          cacheStats['locationCache'] as Map<dynamic, dynamic>;

      // Track coordinate occurrences
      final Map<String, List<String>> coordinateToShopIds = {};

      // Analyze all locations in cache
      for (final entry in locationCache.entries) {
        final shopId = entry.key.toString();
        final location = entry.value as GeoPoint;

        // Create key for the location
        final locationKey =
            '${location.latitude.toStringAsFixed(6)},${location.longitude.toStringAsFixed(6)}';

        if (coordinateToShopIds.containsKey(locationKey)) {
          coordinateToShopIds[locationKey]!.add(shopId);
        } else {
          coordinateToShopIds[locationKey] = [shopId];
        }
      }

      // Find duplicates
      final duplicates = <String, List<String>>{};
      for (final entry in coordinateToShopIds.entries) {
        if (entry.value.length > 1) {
          duplicates[entry.key] = entry.value;
        }
      }

      // Print results
      if (duplicates.isEmpty) {
        debugPrint(
            '✅ No duplicate coordinates found! Each pharmacy has unique coordinates.');
      } else {
        debugPrint(
            '❌ FOUND ${duplicates.length} SETS OF DUPLICATE COORDINATES!');

        for (final entry in duplicates.entries) {
          final coordinate = entry.key;
          final shopIds = entry.value;

          debugPrint(
              '🔍 Coordinate [$coordinate] is used by ${shopIds.length} pharmacies:');
          for (final shopId in shopIds) {
            final name = await PharmacyCacheService.getPharmacyName(shopId);
            debugPrint('   - $shopId: $name');
          }
        }
      }

      return {
        'hasDuplicates': duplicates.isNotEmpty,
        'duplicateCount': duplicates.length,
        'totalUniqueCoordinates': coordinateToShopIds.length,
        'totalPharmacies': locationCache.length,
        'duplicateSets': duplicates,
      };
    } catch (e) {
      debugPrint('❌ Error checking for duplicate coordinates: $e');
      return {'error': e.toString()};
    }
  }

  /// Verify pharmacy data from all sources
  static Future<void> verifyPharmacyData() async {
    try {
      debugPrint('🔍 VERIFYING PHARMACY DATA INTEGRITY');

      // 1. Check Firestore directly
      final pharmaciesSnapshot =
          await _firestore.collection('pharmacies').get();
      debugPrint(
          'Found ${pharmaciesSnapshot.docs.length} pharmacies in Firestore');

      // Count pharmacies with location data
      int withLocation = 0;
      int withSameLocation = 0;
      final Set<String> uniqueCoordinates = {};

      for (final doc in pharmaciesSnapshot.docs) {
        final data = doc.data();
        if (data['location'] != null) {
          withLocation++;

          try {
            final location = data['location'] as GeoPoint;
            final coordKey = '${location.latitude},${location.longitude}';

            if (uniqueCoordinates.contains(coordKey)) {
              withSameLocation++;
            } else {
              uniqueCoordinates.add(coordKey);
            }
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }

      debugPrint('🔍 Direct Firestore check:');
      debugPrint('   - Pharmacies with location data: $withLocation');
      debugPrint('   - Unique coordinates found: ${uniqueCoordinates.length}');
      debugPrint('   - Duplicate coordinates: $withSameLocation');

      // 2. Check products collection for shopId references
      final productsSnapshot =
          await _firestore.collection('products').limit(20).get();
      final Set<String> shopIdSet = {};

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final shopId = data['shopId']?.toString() ?? '';
        if (shopId.isNotEmpty) {
          shopIdSet.add(shopId);
        }
      }

      debugPrint('🔍 Products collection check:');
      debugPrint(
          '   - Sample products checked: ${productsSnapshot.docs.length}');
      debugPrint('   - Unique shop IDs referenced: ${shopIdSet.length}');

      // 3. Verify each shop ID has a matching pharmacy
      int matchedIds = 0;
      int unmatchedIds = 0;
      for (final shopId in shopIdSet) {
        final doc = await _firestore.collection('pharmacies').doc(shopId).get();
        if (doc.exists) {
          matchedIds++;
        } else {
          unmatchedIds++;
          debugPrint(
              '⚠️ Product references shopId "$shopId" but no pharmacy document exists with this ID');
        }
      }

      debugPrint('🔍 Shop ID verification:');
      debugPrint('   - Shop IDs with matching pharmacy: $matchedIds');
      debugPrint('   - Shop IDs without matching pharmacy: $unmatchedIds');

      // 4. Check for duplicate coordinates
      await checkForDuplicateCoordinates();
    } catch (e) {
      debugPrint('❌ Error verifying pharmacy data: $e');
    }
  }

  /// Debug helper to list all pharmacies
  static Future<void> printAllPharmacies() async {
    try {
      final pharmaciesSnapshot =
          await _firestore.collection('pharmacies').get();
      debugPrint(
          '🏥 PHARMACY LISTING (${pharmaciesSnapshot.docs.length} total):');

      for (int i = 0; i < pharmaciesSnapshot.docs.length; i++) {
        final doc = pharmaciesSnapshot.docs[i];
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final shopId = data['shopId'] ?? doc.id;          String location = 'No location';
        if (data['location'] != null) {
          try {
            if (data['location'] is GeoPoint) {
              final loc = data['location'] as GeoPoint;
              location = '${loc.latitude}, ${loc.longitude}';
            }
            else if (data['location'] is Map) {
              final locationMap = data['location'] as Map;
              if (locationMap['latitude'] != null && locationMap['longitude'] != null) {
                location = '${locationMap['latitude']}, ${locationMap['longitude']}';
              } else {
                location = 'Incomplete map format';
              }
            }
            else {
              location = 'Unknown format: ${data['location']}';
            }
          } catch (e) {
            location = 'Invalid location format: $e';
          }
        } 
        else if (data['address'] != null && data['address'].toString().contains(',')) {
          // Check if address contains coordinates
          try {
            final addressStr = data['address'].toString();
            final parts = addressStr.split(',');
            if (parts.length == 2) {
              location = 'From address: ${parts[0].trim()}, ${parts[1].trim()}';
            } else {
              location = 'Address: ${data['address']}';
            }
          } catch (e) {
            location = 'Address parsing error: $e';
          }
        }

        debugPrint(
            '$i: $name (ID: ${doc.id}, ShopID: $shopId) - Location: $location');
      }
    } catch (e) {
      debugPrint('❌ Error listing pharmacies: $e');
    }
  }
}
