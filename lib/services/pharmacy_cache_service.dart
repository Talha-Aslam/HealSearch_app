import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service to cache pharmacy data for better performance and reliability
class PharmacyCacheService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, String> _pharmacyNameCache = {};
  static final Map<String, GeoPoint> _pharmacyLocationCache = {};
  static bool _cacheInitialized = false;

  /// Initialize the pharmacy cache by loading all pharmacies
  static Future<void> initializeCache() async {
    if (_cacheInitialized) return;

    try {
      debugPrint('🏥 Initializing pharmacy cache...');
      final pharmaciesSnapshot =
          await _firestore.collection('pharmacies').get();

      _pharmacyNameCache.clear();
      _pharmacyLocationCache.clear();

      // DIAGNOSTIC: Count of pharmacies with valid locations
      int totalPharmacies = pharmaciesSnapshot.docs.length;
      int validLocationCount = 0;
      int invalidLocationCount = 0;
      Set<String> uniqueLocations = {};

      debugPrint('🔬 PHARMACY DATA DIAGNOSTICS:');
      debugPrint('🔬 Found $totalPharmacies pharmacies in Firestore');

      for (final doc in pharmaciesSnapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? 'Unknown Pharmacy';

        // Print pharmacy details for debugging
        debugPrint('🔬 Pharmacy: $name (ID: ${doc.id})');
        debugPrint('🔬 Raw data: $data');

        // Cache with multiple possible keys to handle different formats
        _pharmacyNameCache[doc.id] =
            name; // Document ID        // Cache location data if available and valid
        if (data['location'] != null) {
          try {
            // Try to handle both GeoPoint and Map formats
            double lat = 0, lon = 0;
            bool validLocation = false;

            if (data['location'] is GeoPoint) {
              final location = data['location'] as GeoPoint;
              lat = location.latitude;
              lon = location.longitude;
              validLocation = (lat != 0 || lon != 0);
              debugPrint('📍 Found GeoPoint location: $lat, $lon');
            } else if (data['location'] is Map) {
              final locationMap = data['location'] as Map;
              if (locationMap['latitude'] != null &&
                  locationMap['longitude'] != null) {
                lat = double.parse(locationMap['latitude'].toString());
                lon = double.parse(locationMap['longitude'].toString());
                validLocation = (lat != 0 || lon != 0);
                debugPrint('📍 Found Map location: $lat, $lon');
              }
            }

            if (validLocation) {
              // Create a GeoPoint for caching
              final geoPoint = GeoPoint(lat, lon);
              _pharmacyLocationCache[doc.id] = geoPoint;

              // Track unique locations
              String locationKey = '$lat,$lon';
              uniqueLocations.add(locationKey);

              validLocationCount++;
              debugPrint('📍 Cached location for ${doc.id}: $lat, $lon');
            } else {
              invalidLocationCount++;
              debugPrint(
                  '⚠️ Skipped caching invalid/zero coordinates for ${doc.id}');
            }
          } catch (e) {
            debugPrint('❌ Error caching location for ${doc.id}: $e');
          }
        }
        // Try to get location from address field as fallback
        else if (data['address'] != null) {
          final addressValue = data['address'].toString();
          debugPrint(
              '🔍 Checking address field for coordinates: $addressValue');

          // Some records store coordinates in the address field
          if (addressValue.contains(',')) {
            try {
              final parts = addressValue.split(',');
              if (parts.length == 2) {
                double lat = double.parse(parts[0].trim());
                double lon = double.parse(parts[1].trim());

                // Only cache valid coordinates
                if (lat != 0 || lon != 0) {
                  final geoPoint = GeoPoint(lat, lon);
                  _pharmacyLocationCache[doc.id] = geoPoint;

                  // Also cache under shopId if available
                  if (data['shopId'] != null) {
                    final shopIdStr = data['shopId'].toString();
                    _pharmacyLocationCache[shopIdStr] = geoPoint;
                    debugPrint(
                        '📍 Cached location from address for shopId $shopIdStr: $lat, $lon');
                  }

                  String locationKey = '$lat,$lon';
                  uniqueLocations.add(locationKey);
                  validLocationCount++;
                  debugPrint(
                      '📍 Cached location from address for ${doc.id}: $lat, $lon');
                }
              }
            } catch (e) {
              debugPrint('❌ Could not parse coordinates from address: $e');
            }
          } else {
            debugPrint('⚠️ No location field found for pharmacy: ${doc.id}');
            invalidLocationCount++;
          }
        } else {
          debugPrint('⚠️ No location field found for pharmacy: ${doc.id}');
          invalidLocationCount++;
        } // Handle different shopId formats
        if (data['shopId'] != null) {
          final shopIdStr = data['shopId'].toString();
          _pharmacyNameCache[shopIdStr] = name;
          debugPrint('📝 Cached name for shop ID $shopIdStr: $name');

          // Cache location for shopId if available (any format)
          if (data['location'] != null) {
            try {
              // Try to handle both GeoPoint and Map formats
              double lat = 0, lon = 0;
              bool validLocation = false;

              if (data['location'] is GeoPoint) {
                final location = data['location'] as GeoPoint;
                lat = location.latitude;
                lon = location.longitude;
                validLocation = (lat != 0 || lon != 0);
              } else if (data['location'] is Map) {
                final locationMap = data['location'] as Map;
                if (locationMap['latitude'] != null &&
                    locationMap['longitude'] != null) {
                  lat = double.parse(locationMap['latitude'].toString());
                  lon = double.parse(locationMap['longitude'].toString());
                  validLocation = (lat != 0 || lon != 0);
                }
              }

              // If we found valid coordinates, cache them under both document ID and shopId
              if (validLocation) {
                final geoPoint = GeoPoint(lat, lon);
                _pharmacyLocationCache[doc.id] = geoPoint;
                _pharmacyLocationCache[shopIdStr] =
                    geoPoint; // Direct mapping from shopId to location
                debugPrint(
                    '📍 Cached location for shop ID $shopIdStr: $lat, $lon');
              }
            } catch (e) {
              debugPrint('❌ Error caching location for shop ID $shopIdStr: $e');
            }
          }
        }

        // Handle other possible ID fields
        if (data['id'] != null) {
          final idStr = data['id'].toString();
          _pharmacyNameCache[idStr] = name;
          debugPrint('📝 Cached name for ID field $idStr: $name');

          if (data['location'] != null) {
            try {
              final location = data['location'] as GeoPoint;
              if (location.latitude != 0 || location.longitude != 0) {
                _pharmacyLocationCache[idStr] = location;
                debugPrint(
                    '📍 Cached location for ID $idStr: ${location.latitude}, ${location.longitude}');
              }
            } catch (e) {
              debugPrint('❌ Error caching location for ID $idStr: $e');
            }
          }
        }

        // Handle specific patterns like SHOP0002 -> Shop ID: SHOP0002
        final shopIdPattern = RegExp(r'SHOP\d+');
        if (shopIdPattern.hasMatch(doc.id)) {
          _pharmacyNameCache[doc.id] = name;
          debugPrint('📝 Cached name for SHOP pattern ${doc.id}: $name');
        }

        // Special handling for your specific case
        if (doc.id.contains('SHOP') ||
            (data['shopId']?.toString().contains('SHOP') ?? false)) {
          final shopCode = data['shopId']?.toString() ?? doc.id;
          _pharmacyNameCache[shopCode] = name;
          _pharmacyNameCache['Shop ID: $shopCode'] =
              name; // Handle the format you showed
          debugPrint(
              '📝 Cached special SHOP format: $shopCode and Shop ID: $shopCode');
        }
      }

      // DIAGNOSTIC: Summarize cache state
      debugPrint('🔬 PHARMACY CACHE SUMMARY:');
      debugPrint('🔬 Total pharmacies: $totalPharmacies');
      debugPrint('🔬 Pharmacies with valid locations: $validLocationCount');
      debugPrint('🔬 Pharmacies with invalid locations: $invalidLocationCount');
      debugPrint('🔬 Unique locations in cache: ${uniqueLocations.length}');
      debugPrint('🔬 Location cache entries: ${_pharmacyLocationCache.length}');
      debugPrint('🔬 Name cache entries: ${_pharmacyNameCache.length}');

      // Warning for potential issues
      if (uniqueLocations.length < validLocationCount) {
        debugPrint(
            '⚠️ WARNING: There are duplicate locations in the database!');
        debugPrint(
            '⚠️ Only ${uniqueLocations.length} unique locations for $validLocationCount pharmacies');
      }

      if (uniqueLocations.length == 1 && validLocationCount > 1) {
        debugPrint(
            '❌ CRITICAL: All pharmacies have the same location coordinates!');
        debugPrint(
            '❌ This will cause all distance calculations to be identical');
      }

      _cacheInitialized = true;
      debugPrint(
          '✅ Pharmacy cache initialized with ${_pharmacyNameCache.length} entries');
    } catch (e) {
      debugPrint('❌ Error initializing pharmacy cache: $e');
    }
  }

  /// Get pharmacy name by shop ID with fallback strategies
  static Future<String> getPharmacyName(String shopId) async {
    if (shopId.isEmpty) return "Unknown Pharmacy";

    // Ensure cache is initialized
    await initializeCache();

    // Try cache first
    if (_pharmacyNameCache.containsKey(shopId)) {
      final name = _pharmacyNameCache[shopId]!;
      debugPrint('✅ Found pharmacy name in cache: $shopId -> $name');
      return name;
    }

    debugPrint('⚠️ Pharmacy not found in cache for shopId: $shopId');
    debugPrint('📊 Available cache keys: ${_pharmacyNameCache.keys.toList()}');

    // If not in cache, try direct Firebase queries with multiple strategies
    try {
      // Strategy 1: Direct document lookup
      final directDoc =
          await _firestore.collection('pharmacies').doc(shopId).get();
      if (directDoc.exists) {
        final name =
            directDoc.data()?['name']?.toString() ?? 'Unknown Pharmacy';
        _pharmacyNameCache[shopId] = name; // Cache for future use
        debugPrint('✅ Found pharmacy via direct lookup: $shopId -> $name');
        return name;
      }

      // Strategy 2: Query by shopId field
      final querySnapshot = await _firestore
          .collection('pharmacies')
          .where('shopId', isEqualTo: shopId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final name = querySnapshot.docs.first.data()['name']?.toString() ??
            'Unknown Pharmacy';
        _pharmacyNameCache[shopId] = name; // Cache for future use
        debugPrint('✅ Found pharmacy via shopId query: $shopId -> $name');
        return name;
      }

      // Strategy 3: Fuzzy matching for cases like SHOP0002 -> SHOP 0002
      final normalizedShopId =
          shopId.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      for (final entry in _pharmacyNameCache.entries) {
        final normalizedKey =
            entry.key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        if (normalizedKey == normalizedShopId) {
          debugPrint(
              '✅ Found pharmacy via fuzzy matching: $shopId -> ${entry.value}');
          _pharmacyNameCache[shopId] = entry.value; // Cache for future use
          return entry.value;
        }
      }
    } catch (e) {
      debugPrint('❌ Error querying pharmacy: $e');
    }

    // Return fallback
    debugPrint('❌ No pharmacy found for shopId: $shopId, using fallback');
    return "Shop ID: $shopId";
  }

  /// Get pharmacy location by shop ID
  static Future<GeoPoint?> getPharmacyLocation(String shopId) async {
    if (shopId.isEmpty) return null;

    // Ensure cache is initialized
    await initializeCache();

    // Try cache first
    if (_pharmacyLocationCache.containsKey(shopId)) {
      final location = _pharmacyLocationCache[shopId]!;
      debugPrint(
          '✅ Found pharmacy location in cache: $shopId -> ${location.latitude}, ${location.longitude}');
      return location;
    }

    debugPrint('⚠️ Pharmacy location not found in cache for shopId: $shopId');

    // If not in cache, try direct Firebase query
    try {
      final directDoc =
          await _firestore.collection('pharmacies').doc(shopId).get();
      if (directDoc.exists && directDoc.data()?['location'] != null) {
        final location = directDoc.data()?['location'] as GeoPoint;
        _pharmacyLocationCache[shopId] = location; // Cache for future use
        debugPrint(
            '✅ Found pharmacy location via direct lookup: $shopId -> ${location.latitude}, ${location.longitude}');
        return location;
      }
    } catch (e) {
      debugPrint('❌ Error querying pharmacy location: $e');
    }

    debugPrint('❌ No location found for shopId: $shopId');
    return null;
  }

  /// Clear cache (useful for testing or data refresh)
  static void clearCache() {
    _pharmacyNameCache.clear();
    _pharmacyLocationCache.clear();
    _cacheInitialized = false;
    debugPrint('🗑️ Pharmacy cache cleared');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'initialized': _cacheInitialized,
      'nameEntries': _pharmacyNameCache.length,
      'locationEntries': _pharmacyLocationCache.length,
      'nameKeys': _pharmacyNameCache.keys.toList(),
      'locationKeys': _pharmacyLocationCache.keys.toList(),
      'nameCache': Map.from(_pharmacyNameCache),
      'locationCache': Map.from(_pharmacyLocationCache),
    };
  }
}
