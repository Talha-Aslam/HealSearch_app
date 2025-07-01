import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service to cache pharmacy data for better performance and reliability
class PharmacyCacheService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, String> _pharmacyNameCache = {};
  static bool _cacheInitialized = false;

  /// Initialize the pharmacy cache by loading all pharmacies
  static Future<void> initializeCache() async {
    if (_cacheInitialized) return;

    try {
      debugPrint('🏥 Initializing pharmacy cache...');
      final pharmaciesSnapshot =
          await _firestore.collection('pharmacies').get();

      _pharmacyNameCache.clear();

      for (final doc in pharmaciesSnapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? 'Unknown Pharmacy';

        // Cache with multiple possible keys to handle different formats
        _pharmacyNameCache[doc.id] = name; // Document ID

        // Handle different shopId formats
        if (data['shopId'] != null) {
          _pharmacyNameCache[data['shopId'].toString()] = name;
        }

        // Handle other possible ID fields
        if (data['id'] != null) {
          _pharmacyNameCache[data['id'].toString()] = name;
        }

        // Handle specific patterns like SHOP0002 -> Shop ID: SHOP0002
        final shopIdPattern = RegExp(r'SHOP\d+');
        if (shopIdPattern.hasMatch(doc.id)) {
          _pharmacyNameCache[doc.id] = name;
        }

        // Special handling for your specific case
        if (doc.id.contains('SHOP') ||
            (data['shopId']?.toString().contains('SHOP') ?? false)) {
          final shopCode = data['shopId']?.toString() ?? doc.id;
          _pharmacyNameCache[shopCode] = name;
          _pharmacyNameCache['Shop ID: $shopCode'] =
              name; // Handle the format you showed
        }

        debugPrint('🏥 Cached pharmacy: ${doc.id} -> $name');
        debugPrint('   Data: $data');
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

  /// Clear cache (useful for testing or data refresh)
  static void clearCache() {
    _pharmacyNameCache.clear();
    _cacheInitialized = false;
    debugPrint('🗑️ Pharmacy cache cleared');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'initialized': _cacheInitialized,
      'entries': _pharmacyNameCache.length,
      'keys': _pharmacyNameCache.keys.toList(),
      'cache': Map.from(_pharmacyNameCache),
    };
  }
}
