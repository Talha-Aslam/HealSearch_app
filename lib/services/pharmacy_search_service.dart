import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../Models/pharmacy.dart';
import '../Models/medicine_inventory.dart';
import '../firebase_database.dart';

class PharmacySearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search for nearby pharmacies and their medicine inventory
  static Future<List<Map<String, dynamic>>> searchNearbyMedicines({
    required Position userPosition,
    String? searchQuery,
    String? pharmacyName,
  }) async {
    try {
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
        } catch (e) {
          debugPrint('Error parsing pharmacy document ${doc.id}: $e');
        }
      }

      return nearbyPharmacies;
    } catch (e) {
      debugPrint('Error querying nearby pharmacies: $e');
      rethrow;
    }
  }

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
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error querying medicine inventory: $e');
      rethrow;
    }
  }

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
  static Future<List<Map<String, dynamic>>> searchMedicineByName({
    required String medicineName,
    required Position userPosition,
  }) async {
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
  }

  /// Get medicine suggestions for autocomplete
  static Future<List<String>> getMedicineSuggestions({
    required String partialName,
    int limit = 10,
  }) async {
    try {
      final suggestions = <String>[];

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
            }
          }
        } catch (e) {
          debugPrint(
              'Error parsing medicine document for suggestions ${doc.id}: $e');
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('Error getting medicine suggestions: $e');
      return [];
    }
  }
}
