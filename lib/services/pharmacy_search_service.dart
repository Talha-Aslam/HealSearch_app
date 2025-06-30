import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../firebase_database.dart';

class PharmacySearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search for medicines from the products collection
  static Future<List<Map<String, dynamic>>> searchNearbyMedicines({
    required Position userPosition,
    String? searchQuery,
  }) async {
    try {
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
              _formatProductForUI(data, doc.id, userPosition);
          products.add(formattedProduct);
          debugPrint('  ✅ Added product: ${formattedProduct['Name']}');
        } catch (e) {
          debugPrint('❌ Error parsing product document ${doc.id}: $e');
        }
      }

      debugPrint('🔍 Filtered to ${products.length} available products');

      // Sort by distance if we have location data, otherwise by name
      products.sort((a, b) {
        // For now, sort by name since we don't have shop location data
        // You can modify this when shop locations are available
        return a["Name"].toString().compareTo(b["Name"].toString());
      });

      debugPrint('🔍 Returning ${products.length} products to UI');
      return products;
    } catch (e) {
      debugPrint('❌ Error in products search: $e');
      rethrow;
    }
  }

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
  static Map<String, dynamic> _formatProductForUI(
      Map<String, dynamic> data, String docId, Position userPosition) {
    // Extract data from the product document
    final name = data['name']?.toString() ?? 'Unknown Product';
    final category = data['category']?.toString() ?? 'Medicine';
    final price = data['price'] ?? 0;
    final quantity = data['quantity'] ?? 0;
    final expiry = data['expiry']?.toString() ?? '';
    final shopId = data['shopId']?.toString() ?? '';
    final type = data['type']?.toString() ?? 'Public';
    final userEmail = data['userEmail']?.toString() ?? '';

    // For now, use default location since shop locations aren't in the schema
    // You can modify this when shop locations become available
    final defaultLat =
        userPosition.latitude + (0.01 * (docId.hashCode % 10 - 5));
    final defaultLon =
        userPosition.longitude + (0.01 * (docId.hashCode % 10 - 5));

    // Calculate a mock distance for now
    final distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          defaultLat,
          defaultLon,
        ) /
        1000; // Convert to kilometers

    return {
      "Name": name,
      "Category": category,
      "Description": "$category - Available in $type pharmacy",
      "Price": "Rs. ${price.toString()}",
      "Quantity": quantity,
      "StoreName": "Shop ID: $shopId",
      "StoreLocation": {
        "latitude": defaultLat,
        "longitude": defaultLon,
      },
      "Distance": distance.toStringAsFixed(2),
      "Expire": expiry,
      "Type": type,
      "ShopId": shopId,
      "UserEmail": userEmail,
      "id": docId,
    };
  }

  /// Search for specific medicine by name
  static Future<List<Map<String, dynamic>>> searchMedicineByName({
    required String medicineName,
    required Position userPosition,
  }) async {
    return searchNearbyMedicines(
      userPosition: userPosition,
      searchQuery: medicineName,
    );
  }

  /// Get medicine suggestions for autocomplete
  static Future<List<String>> getMedicineSuggestions({
    required String partialName,
    int limit = 10,
  }) async {
    try {
      final suggestions = <String>[];

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
            }
          }
        } catch (e) {
          debugPrint(
              'Error parsing product document for suggestions ${doc.id}: $e');
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
                _formatProductForUI(data, doc.id, userPosition);
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
