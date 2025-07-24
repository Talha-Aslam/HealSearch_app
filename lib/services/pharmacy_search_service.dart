import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../firebase_database.dart';
import 'pharmacy_cache_service.dart';
import 'firebase_debug_util.dart';

class PharmacySearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
<<<<<<< HEAD

  /// Search for nearby pharmacies and their medicine inventory
=======
  static bool _debugRun = false;

  /// Search for medicines from the products collection
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
  static Future<List<Map<String, dynamic>>> searchNearbyMedicines({
    required Position userPosition,
    String? searchQuery,
    String? pharmacyName,
  }) async {
    try {
<<<<<<< HEAD
      debugPrint(
          'Starting pharmacy search at: ${userPosition.latitude}, ${userPosition.longitude}');

      // Step 1: Get all pharmacies from the 'pharmacies' collection
      final pharmacyResults =
          await _getNearbyPharmacies(userPosition, pharmacyName);
      debugPrint('Found ${pharmacyResults.length} nearby pharmacies');

      if (pharmacyResults.isEmpty) {
        return [];
      }

      // Step 2: Get medicine inventory for these pharmacies
      final medicineResults = await _getMedicineInventoryForPharmacies(
          pharmacyResults, searchQuery);
      debugPrint('Found ${medicineResults.length} medicine results');

      // Step 3: Transform to match the current UI format
      final formattedResults =
          _formatResultsForUI(medicineResults, userPosition);
      debugPrint('Formatted ${formattedResults.length} results for UI');

      return formattedResults;
    } catch (e) {
      debugPrint('Error in pharmacy search: $e');
      rethrow;
    }
  }

  /// Get nearby pharmacies within search radius
  static Future<List<Pharmacy>> _getNearbyPharmacies(Position userPosition,
      [String? pharmacyName]) async {
    try {
      final pharmaciesSnapshot =
          await _firestore.collection('pharmacies').get();
      final nearbyPharmacies = <Pharmacy>[];

      for (final doc in pharmaciesSnapshot.docs) {
        try {
          final pharmacy = Pharmacy.fromFirestore(doc);

          // If pharmacy name is specified, filter by it
          if (pharmacyName != null && pharmacy.name != pharmacyName) {
            continue;
          }

          // Calculate distance
          final distance = Geolocator.distanceBetween(
                userPosition.latitude,
                userPosition.longitude,
                pharmacy.location.latitude,
                pharmacy.location.longitude,
              ) /
              1000; // Convert to kilometers

          // Include all pharmacies regardless of distance
          nearbyPharmacies.add(pharmacy);
          debugPrint(
              'Added pharmacy: ${pharmacy.name} at ${distance.toStringAsFixed(2)}km');
=======
      // Initialize pharmacy cache for better performance
      await PharmacyCacheService.initializeCache();

      // Run debug once to understand data structure
      if (!_debugRun) {
        _debugRun = true;
        await FirebaseDebugUtil.debugAll();
      }

      debugPrint('🔍 Starting medicine search from products collection');
      debugPrint(
          '🔍 Search query: ${searchQuery ?? "null (getting all products)"}');

      // Get all products from the 'products' collection
      Query query = _firestore.collection('products');

      final productsSnapshot = await query.get();
      debugPrint(
          '🔍 Found ${productsSnapshot.docs.length} total products in database');

      if (productsSnapshot.docs.isEmpty) {
        debugPrint(
            '⚠️ No products found in database - this might be the issue');
        return [];
      }

      final products = <Map<String, dynamic>>[];

      for (final doc in productsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('🔍 Processing product: ${data['name']} (ID: ${doc.id})');

          // Filter by search query if provided (client-side filtering)
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final productName = data['name']?.toString().toLowerCase() ?? '';
            if (!productName.contains(searchQuery.toLowerCase())) {
              debugPrint('  ❌ Skipped due to search filter: $productName');
              continue; // Skip if doesn't match search query
            }
          }

          // Check if product is not expired
          final expiryDate = data['expiry']?.toString() ?? '';
          if (_isProductExpired(expiryDate)) {
            debugPrint(
                '  ❌ Skipped expired product: ${data['name']} (expires: $expiryDate)');
            continue; // Skip expired products
          }

          // Check if product has sufficient quantity
          final quantity = data['quantity'] ?? 0;
          if (quantity <= 0) {
            debugPrint(
                '  ❌ Skipped out of stock product: ${data['name']} (quantity=$quantity)');
            continue; // Skip out of stock products
          }

          // Format product for UI
          final formattedProduct =
              await _formatProductForUI(data, doc.id, userPosition);
          products.add(formattedProduct);
          debugPrint('  ✅ Added product: ${formattedProduct['Name']}');
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
        } catch (e) {
          debugPrint('❌ Error parsing product document ${doc.id}: $e');
        }
      }

<<<<<<< HEAD
      return nearbyPharmacies;
=======
      debugPrint('🔍 Filtered to ${products.length} available products');

      // Sort by distance (closest first), with unknown distances at the end
      products.sort((a, b) {
        final distanceAStr = a["Distance"].toString();
        final distanceBStr = b["Distance"].toString();

        // Handle "Unknown" distances
        if (distanceAStr == "Unknown" && distanceBStr == "Unknown") {
          return 0; // Both unknown, sort by name or keep original order
        } else if (distanceAStr == "Unknown") {
          return 1; // A is unknown, B has distance, put A after B
        } else if (distanceBStr == "Unknown") {
          return -1; // B is unknown, A has distance, put A before B
        }

        // Both have numeric distances
        final distanceA = double.tryParse(distanceAStr) ?? double.infinity;
        final distanceB = double.tryParse(distanceBStr) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });

      debugPrint('🔍 Returning ${products.length} products sorted by distance');
      return products;
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
    } catch (e) {
      debugPrint('❌ Error in products search: $e');
      rethrow;
    }
  }

<<<<<<< HEAD
  /// Get medicine inventory for specific pharmacies
  static Future<List<Map<String, dynamic>>> _getMedicineInventoryForPharmacies(
      List<Pharmacy> pharmacies, String? searchQuery) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (final pharmacy in pharmacies) {
        // Query medicine inventory for this pharmacy
        Query query = _firestore
            .collection('medicine_inventory')
            .where('pharmacyId', isEqualTo: pharmacy.id);

        final inventorySnapshot = await query.get();

        for (final doc in inventorySnapshot.docs) {
          try {
            final inventory = MedicineInventory.fromFirestore(doc);

            // Filter by search query if provided
            if (searchQuery != null && searchQuery.isNotEmpty) {
              if (!inventory.medicineName
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase())) {
                continue; // Skip if doesn't match search query
              }
            }

            // Only include if in stock and not expired
            if (inventory.isInStock && !inventory.isExpired) {
              results.add({
                'pharmacy': pharmacy,
                'medicine': inventory,
              });
              debugPrint(
                  'Added medicine: ${inventory.medicineName} from ${pharmacy.name}');
            }
          } catch (e) {
            debugPrint(
                'Error parsing medicine inventory document ${doc.id}: $e');
=======
  /// Check if a product is expired
  static bool _isProductExpired(String expiryDate) {
    if (expiryDate.isEmpty) return false;

    try {
      DateTime expiry;
      final now = DateTime.now();

      // Handle different date formats that might be in the database
      if (expiryDate.contains('/')) {
        // Handle formats like "12/31/2025" or "31/12/2025"
        final parts = expiryDate.split('/');
        if (parts.length == 3) {
          // Assume format is MM/DD/YYYY or DD/MM/YYYY
          final year = int.parse(parts[2]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[0]);

          // Check if it's likely MM/DD format (month > 12 means it's DD/MM)
          if (month > 12) {
            expiry = DateTime(year, day, month);
          } else {
            expiry = DateTime(year, month, day);
          }
        } else {
          return false; // Invalid format
        }
      } else if (expiryDate.contains('-')) {
        // Handle formats like "2025-12-31"
        expiry = DateTime.parse(expiryDate);
      } else {
        // Try to parse as ISO format
        expiry = DateTime.parse(expiryDate);
      }

      // Compare dates (ignore time, only compare date)
      final today = DateTime(now.year, now.month, now.day);
      final expiryDateOnly = DateTime(expiry.year, expiry.month, expiry.day);

      final isExpired = expiryDateOnly.isBefore(today);

      if (isExpired) {
        debugPrint(
            '  📅 Product expired: $expiryDate (parsed as: $expiryDateOnly)');
      }

      return isExpired;
    } catch (e) {
      debugPrint('❌ Error parsing expiry date: $expiryDate, $e');
      // If we can't parse the date, assume it's not expired to be safe
      return false;
    }
  }

  /// Format product data for UI display
  static Future<Map<String, dynamic>> _formatProductForUI(
      Map<String, dynamic> data, String docId, Position userPosition) async {
    // Extract data from the product document
    final name = data['name']?.toString() ?? 'Unknown Product';
    final category = data['category']?.toString() ?? 'Medicine';
    final price = data['price'] ?? 0;
    final quantity = data['quantity'] ?? 0;
    final expiry = data['expiry']?.toString() ?? '';
    final shopId = data['shopId']?.toString() ?? '';
    final type = data['type']?.toString() ?? 'Public';
    final userEmail = data['userEmail']?.toString() ?? '';

    // DIAGNOSTIC: Print all product data to identify shopId format issues
    debugPrint('🔬 PRODUCT DATA DIAGNOSTICS:');
    debugPrint('🔬 Product name: $name (ID: $docId)');
    debugPrint('🔬 Raw shopId: "${data['shopId']}"');
    debugPrint('🔬 Parsed shopId: "$shopId"');
    debugPrint('🔬 Complete product data: $data');

    // Fetch pharmacy name and location using the cache service
    String pharmacyName = "Shop ID: $shopId"; // fallback
    // Use random offset for default coordinates to ensure unique distances
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 10000;
    double pharmacyLat =
        userPosition.latitude + 0.01 + random; // Random offset for testing
    double pharmacyLon =
        userPosition.longitude + 0.01 + random; // Random offset for testing
    double distance = 0.0;

    debugPrint('🔍 Fetching pharmacy data for shopId: "$shopId"');

    try {
      // Get pharmacy name
      pharmacyName = await PharmacyCacheService.getPharmacyName(shopId);
      debugPrint('✅ Found pharmacy name: $pharmacyName');

      // DIAGNOSTIC: Check pharmacy cache state to see if caching is working properly
      final cacheStats = PharmacyCacheService.getCacheStats();
      debugPrint('🔬 CACHE DIAGNOSTICS:');
      debugPrint('🔬 Name entries: ${cacheStats['nameEntries']}');
      debugPrint('🔬 Location entries: ${cacheStats['locationEntries']}');
      debugPrint('🔬 Location keys: ${cacheStats['locationKeys']}');
      debugPrint(
          '🔬 Is shopId in cache? ${cacheStats['locationKeys']?.contains(shopId)}');

      // Get pharmacy location from cache first, then fallback to direct query
      final cachedLocation =
          await PharmacyCacheService.getPharmacyLocation(shopId);
      if (cachedLocation != null) {
        pharmacyLat = cachedLocation.latitude;
        pharmacyLon = cachedLocation.longitude;
        debugPrint(
            '✅ Found pharmacy location from cache: $pharmacyLat, $pharmacyLon');
      } else if (shopId.isNotEmpty) {
        // Fallback to direct Firebase query if not in cache
        debugPrint(
            '⚠️ Location not found in cache, querying Firestore directly');

        // DIAGNOSTIC: Try all possible collection names and document paths
        // 1. Try direct doc ID lookup
        final pharmacyDoc =
            await _firestore.collection('pharmacies').doc(shopId).get();
        if (pharmacyDoc.exists) {
          final pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;
          debugPrint(
              '✅ Found pharmacy document by direct ID lookup: ${pharmacyDoc.id}');
          debugPrint('🔬 Raw pharmacy data: $pharmacyData');

          // Try to get location data with flexible parsing for different data structures
          if (pharmacyData['location'] != null) {
            try {
              // First try to parse as a GeoPoint (the proper Firestore way)
              if (pharmacyData['location'] is GeoPoint) {
                final location = pharmacyData['location'] as GeoPoint;
                if (location.latitude != 0 || location.longitude != 0) {
                  pharmacyLat = location.latitude;
                  pharmacyLon = location.longitude;
                  debugPrint(
                      '✅ Found pharmacy location from GeoPoint: $pharmacyLat, $pharmacyLon');
                }
              }
              // Then try to parse as a Map (your current format)
              else if (pharmacyData['location'] is Map) {
                final locationMap = pharmacyData['location'] as Map;
                if (locationMap['latitude'] != null &&
                    locationMap['longitude'] != null) {
                  pharmacyLat =
                      double.parse(locationMap['latitude'].toString());
                  pharmacyLon =
                      double.parse(locationMap['longitude'].toString());
                  debugPrint(
                      '✅ Found pharmacy location from Map: $pharmacyLat, $pharmacyLon');
                }
              } else {
                debugPrint(
                    '⚠️ Unknown location format: ${pharmacyData['location']}');
              }
            } catch (e) {
              debugPrint('❌ Error parsing location data: $e');
            }
          }
          // Try to get location from address field as fallback
          else if (pharmacyData['address'] != null) {
            final addressValue = pharmacyData['address'].toString();
            debugPrint(
                '⚠️ No location field found, checking address: $addressValue');

            // Try to parse address as coordinates (some of your records store it this way)
            if (addressValue.contains(',')) {
              try {
                final parts = addressValue.split(',');
                if (parts.length == 2) {
                  pharmacyLat = double.parse(parts[0].trim());
                  pharmacyLon = double.parse(parts[1].trim());
                  debugPrint(
                      '✅ Found coordinates in address field: $pharmacyLat, $pharmacyLon');
                }
              } catch (e) {
                debugPrint('❌ Could not parse coordinates from address: $e');
              }
            }
          }
        } else {
          // 2. Try querying by shopId field
          debugPrint(
              '⚠️ Pharmacy not found by direct ID, trying shopId field query');
          final querySnapshot = await _firestore
              .collection('pharmacies')
              .where('shopId', isEqualTo: shopId)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final pharmacyData = querySnapshot.docs.first.data();
            debugPrint(
                '✅ Found pharmacy by shopId field query: ${querySnapshot.docs.first.id}');
            debugPrint('🔬 Raw pharmacy data: $pharmacyData');

            if (pharmacyData['location'] != null) {
              try {
                final location = pharmacyData['location'] as GeoPoint;
                if (location.latitude != 0 || location.longitude != 0) {
                  pharmacyLat = location.latitude;
                  pharmacyLon = location.longitude;
                  debugPrint(
                      '✅ Found pharmacy location from shopId query: $pharmacyLat, $pharmacyLon');
                }
              } catch (e) {
                debugPrint('❌ Error parsing location from shopId query: $e');
              }
            }
          } else {
            debugPrint(
                '❌ Pharmacy not found by any method for shopId: $shopId');
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
          }
        }
      }

<<<<<<< HEAD
      return results;
=======
      // Calculate actual distance
      debugPrint('🔍 Distance calculation inputs:');
      debugPrint(
          '  User position: ${userPosition.latitude}, ${userPosition.longitude}');
      debugPrint('  Pharmacy position: $pharmacyLat, $pharmacyLon');

      // Check if coordinates are the same or invalid
      bool hasValidCoordinates = true;
      if ((userPosition.latitude == pharmacyLat &&
          userPosition.longitude == pharmacyLon)) {
        debugPrint('⚠️ WARNING: User and pharmacy coordinates are identical!');
        hasValidCoordinates = false;
      } else if (pharmacyLat == 0 && pharmacyLon == 0) {
        debugPrint('⚠️ WARNING: Pharmacy has zero coordinates [0,0]');
        hasValidCoordinates = false;
      }

      // Only calculate distance if we have valid coordinates
      if (hasValidCoordinates) {
        distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              pharmacyLat,
              pharmacyLon,
            ) /
            1000; // Convert to kilometers
      } else {
        // Use a placeholder distance that makes it clear there's an issue
        distance = -1; // Will be displayed as "Unknown"
      }

      debugPrint('✅ Calculated distance: ${distance.toStringAsFixed(2)} km');

      // DIAGNOSTIC: Store the calculation trace
      debugPrint('🔬 DISTANCE TRACE:');
      debugPrint('🔬 Product: $name (ID: $docId)');
      debugPrint('🔬 Shop ID: $shopId');
      debugPrint('🔬 Pharmacy name: $pharmacyName');
      debugPrint(
          '🔬 User location: [${userPosition.latitude}, ${userPosition.longitude}]');
      debugPrint('🔬 Pharmacy location: [$pharmacyLat, $pharmacyLon]');
      debugPrint('🔬 Distance: ${distance.toStringAsFixed(2)} km');
      debugPrint('🔬 Has valid coordinates: $hasValidCoordinates');
      debugPrint('🔬 ------------------------------------------------');
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
    } catch (e) {
      debugPrint('❌ Error fetching pharmacy data for shop ID $shopId: $e');
      // Keep the fallback values
    }

    // IMPORTANT: Add a unique identifier to each product's location to ensure distances vary
    // This will help identify if the issue is with the data or the calculation
    final uniqueProductId = "p_${docId.hashCode}";

    final result = {
      "Name": name,
      "Category": category,
      "Description": "$category - Available in $type pharmacy",
      "Price": "Rs. ${price.toString()}",
      "PriceValue": price, // Store the numeric price value for sorting
      "Quantity": quantity,
      "StoreName": pharmacyName,
      "StoreLocation": {
        "latitude": pharmacyLat,
        "longitude": pharmacyLon,
      },
      "Distance": distance > 0 ? distance.toStringAsFixed(2) : "Unknown",
      "Expire": expiry,
      "Type": type,
      "ShopId": shopId,
      "UserEmail": userEmail,
      "id": docId,
      "uniqueId": uniqueProductId, // Add unique ID for tracking
    };

    // DIAGNOSTIC: Print formatted product
    debugPrint('🔬 FORMATTED PRODUCT:');
    debugPrint('🔬 Name: ${result["Name"]}');
    debugPrint('🔬 StoreName: ${result["StoreName"]}');
    debugPrint('🔬 Location: ${result["StoreLocation"]}');
    debugPrint('🔬 Distance: ${result["Distance"]}');
    debugPrint('🔬 ShopId: ${result["ShopId"]}');
    debugPrint('🔬 ------------------------------------------------');

    return result;
  }

<<<<<<< HEAD
  /// Format results to match the current UI structure
  static List<Map<String, dynamic>> _formatResultsForUI(
      List<Map<String, dynamic>> medicineResults, Position userPosition) {
    final formattedResults = <Map<String, dynamic>>[];

    for (final result in medicineResults) {
      final Pharmacy pharmacy = result['pharmacy'];
      final MedicineInventory medicine = result['medicine'];

      // Calculate distance
      final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            pharmacy.location.latitude,
            pharmacy.location.longitude,
          ) /
          1000; // Convert to kilometers

      // Format to match current UI expectations
      final formattedResult = {
        "Name": medicine.medicineName,
        "Description": medicine.description ??
            "${medicine.category} - ${medicine.manufacturer}",
        "StoreLocation": {
          "latitude": pharmacy.location.latitude,
          "longitude": pharmacy.location.longitude
        },
        "StoreName": pharmacy.name,
        "Price": "Rs. ${medicine.price.toStringAsFixed(0)}",
        "Quantity": medicine.quantity,
        "Distance": distance.toStringAsFixed(2),
        "Category": medicine.category,
        "Manufacturer": medicine.manufacturer,
        "Unit": medicine.unit,
        "RequiresPrescription": medicine.requiresPrescription,
        "PharmacyPhone": pharmacy.phoneNumber,
        "PharmacyAddress": pharmacy.address,
        "IsPharmacyOpen": pharmacy.isOpen,
        "ExpiryDate": medicine.expiryDate,
      };

      formattedResults.add(formattedResult);
    }

    // Sort by distance (closest first)
    formattedResults.sort((a, b) =>
        double.parse(a["Distance"]).compareTo(double.parse(b["Distance"])));

    return formattedResults;
  }

  /// Search for specific medicine by name across all nearby pharmacies
=======
  /// Search for specific medicine by name
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
  static Future<List<Map<String, dynamic>>> searchMedicineByName({
    required String medicineName,
    required Position userPosition,
  }) async {
<<<<<<< HEAD
    try {
      debugPrint('Searching for medicine: $medicineName');

      // Get nearby pharmacies first
      final nearbyPharmacies = await _getNearbyPharmacies(userPosition);

      if (nearbyPharmacies.isEmpty) {
        return [];
      }

      // Search for specific medicine in these pharmacies
      final results = <Map<String, dynamic>>[];

      for (final pharmacy in nearbyPharmacies) {
        // Query medicine inventory for this specific medicine
        final inventorySnapshot = await _firestore
            .collection('medicine_inventory')
            .where('pharmacyId', isEqualTo: pharmacy.id)
            .get();

        for (final doc in inventorySnapshot.docs) {
          try {
            final inventory = MedicineInventory.fromFirestore(doc);

            // Check if medicine name matches (case-insensitive)
            if (inventory.medicineName
                    .toLowerCase()
                    .contains(medicineName.toLowerCase()) &&
                inventory.isInStock &&
                !inventory.isExpired) {
              results.add({
                'pharmacy': pharmacy,
                'medicine': inventory,
              });
            }
          } catch (e) {
            debugPrint('Error parsing medicine document ${doc.id}: $e');
          }
        }
      }

      // Format results for UI
      return _formatResultsForUI(results, userPosition);
    } catch (e) {
      debugPrint('Error searching medicine by name: $e');
      rethrow;
    }
=======
    return searchNearbyMedicines(
      userPosition: userPosition,
      searchQuery: medicineName,
    );
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
  }

  /// Get medicine suggestions for autocomplete
  static Future<List<String>> getMedicineSuggestions({
    required String partialName,
    int limit = 10,
  }) async {
    try {
      final suggestions = <String>[];

<<<<<<< HEAD
      // Query medicine inventory for suggestions
      final inventorySnapshot = await _firestore
          .collection('medicine_inventory')
          .limit(100) // Limit to prevent large queries
          .get();

      for (final doc in inventorySnapshot.docs) {
        try {
          final inventory = MedicineInventory.fromFirestore(doc);

          if (inventory.medicineName
                  .toLowerCase()
                  .contains(partialName.toLowerCase()) &&
              !suggestions.contains(inventory.medicineName)) {
            suggestions.add(inventory.medicineName);

            if (suggestions.length >= limit) {
              break;
=======
      // Query products collection for suggestions
      final productsSnapshot = await _firestore
          .collection('products')
          .limit(100) // Limit to prevent large queries
          .get();

      for (final doc in productsSnapshot.docs) {
        try {
          final data = doc.data();

          if (data['name']
                      ?.toString()
                      .toLowerCase()
                      .contains(partialName.toLowerCase()) ==
                  true &&
              !suggestions.contains(data['name']?.toString() ?? '')) {
            final productName = data['name']?.toString() ?? '';
            if (productName.isNotEmpty) {
              suggestions.add(productName);

              if (suggestions.length >= limit) {
                break;
              }
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
            }
          }
        } catch (e) {
          debugPrint(
<<<<<<< HEAD
              'Error parsing medicine document for suggestions ${doc.id}: $e');
=======
              'Error parsing product document for suggestions ${doc.id}: $e');
>>>>>>> 57821a0e8d23377841ce4a2e51195446a0302345
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('Error getting medicine suggestions: $e');
      return [];
    }
  }

  /// Get products by category
  static Future<List<Map<String, dynamic>>> getProductsByCategory({
    required String category,
    required Position userPosition,
  }) async {
    try {
      debugPrint('Getting products by category: $category');

      final productsSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();

      final products = <Map<String, dynamic>>[];

      for (final doc in productsSnapshot.docs) {
        try {
          final data = doc.data();

          // Check if product is not expired and in stock
          final expiryDate = data['expiry']?.toString() ?? '';
          final quantity = data['quantity'] ?? 0;

          if (!_isProductExpired(expiryDate) && quantity > 0) {
            final formattedProduct =
                await _formatProductForUI(data, doc.id, userPosition);
            products.add(formattedProduct);
          }
        } catch (e) {
          debugPrint('Error parsing product document ${doc.id}: $e');
        }
      }

      // Sort by name
      products
          .sort((a, b) => a["Name"].toString().compareTo(b["Name"].toString()));

      return products;
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      rethrow;
    }
  }
}
