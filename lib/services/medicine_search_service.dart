import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../Models/pharmacy.dart';
import '../Models/medicine_inventory.dart';
import '../Models/medicine_search_result.dart';
import 'location_service.dart';

class MedicineSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GeoFlutterFire _geo = GeoFlutterFire();
    // Collection references
  static const String _medicineInventoryCollection = 'medicine_inventory';
  static const String _pharmaciesCollection = 'pharmacies';
  
  // Search radius in kilometers (removed limit - search all available pharmacies)
  static const double _searchRadiusKm = 1000.0; // Very large radius to include all pharmacies

  /// Search for medicines near the user's location
  static Future<List<MedicineSearchResult>> searchMedicinesNearby({
    required String medicineName,
    Position? userPosition,
  }) async {
    try {
      debugPrint('Starting medicine search for: $medicineName');
      
      // Get user location if not provided
      userPosition ??= await LocationService.getCurrentPosition();
      if (userPosition == null) {
        throw Exception('Unable to get user location');
      }

      debugPrint('User location: ${userPosition.latitude}, ${userPosition.longitude}');

      // Create GeoFirePoint for user location
      final userGeoPoint = _geo.point(
        latitude: userPosition.latitude,
        longitude: userPosition.longitude,
      );

      // Query medicine inventory within radius
      final inventoryResults = await _queryMedicineInventory(
        userGeoPoint: userGeoPoint,
        medicineName: medicineName,
      );

      debugPrint('Found ${inventoryResults.length} medicine inventory matches');

      if (inventoryResults.isEmpty) {
        return [];
      }

      // Get pharmacy details and calculate distances
      final searchResults = await _buildSearchResults(
        inventoryResults: inventoryResults,
        userPosition: userPosition,
      );

      // Sort by distance (closest first)
      searchResults.sort((a, b) => a.distance.compareTo(b.distance));

      debugPrint('Returning ${searchResults.length} search results');
      return searchResults;

    } catch (e) {
      debugPrint('Error in medicine search: $e');
      rethrow;
    }
  }

  /// Query medicine inventory using GeoFlutterFire
  static Future<List<MedicineInventory>> _queryMedicineInventory({
    required GeoFirePoint userGeoPoint,
    required String medicineName,
  }) async {
    try {
      // Create geo query
      final query = _geo.collection(
        collectionRef: _firestore.collection(_medicineInventoryCollection),
      ).within(
        center: userGeoPoint,
        radius: _searchRadiusKm,
        field: 'location',
        strictMode: true,
      );

      // Execute query and get documents
      final querySnapshot = await query.first;
      
      debugPrint('GeoQuery returned ${querySnapshot.length} documents');

      // Filter results by medicine name and stock
      final filteredResults = <MedicineInventory>[];
      
      for (final doc in querySnapshot) {
        try {
          final inventory = MedicineInventory.fromFirestore(doc);
          
          // Check if medicine name matches (case-insensitive) and is in stock
          if (_matchesMedicineName(inventory.medicineName, medicineName) &&
              inventory.isInStock &&
              !inventory.isExpired) {
            filteredResults.add(inventory);
            debugPrint('Added medicine: ${inventory.medicineName} at pharmacy: ${inventory.pharmacyId}');
          }
        } catch (e) {
          debugPrint('Error parsing inventory document ${doc.id}: $e');
        }
      }

      return filteredResults;
    } catch (e) {
      debugPrint('Error querying medicine inventory: $e');
      rethrow;
    }
  }

  /// Build search results with pharmacy details and distances
  static Future<List<MedicineSearchResult>> _buildSearchResults({
    required List<MedicineInventory> inventoryResults,
    required Position userPosition,
  }) async {
    final searchResults = <MedicineSearchResult>[];
    final pharmacyCache = <String, Pharmacy>{};

    for (final inventory in inventoryResults) {
      try {
        // Get pharmacy details (use cache to avoid duplicate queries)
        Pharmacy? pharmacy = pharmacyCache[inventory.pharmacyId];
        if (pharmacy == null) {
          final pharmacyDoc = await _firestore
              .collection(_pharmaciesCollection)
              .doc(inventory.pharmacyId)
              .get();
          
          if (pharmacyDoc.exists) {
            pharmacy = Pharmacy.fromFirestore(pharmacyDoc);
            pharmacyCache[inventory.pharmacyId] = pharmacy;
          } else {
            debugPrint('Pharmacy not found: ${inventory.pharmacyId}');
            continue;
          }
        }        // Calculate distance
        final distance = LocationService.calculateDistance(
          startLatitude: userPosition.latitude,
          startLongitude: userPosition.longitude,
          endLatitude: pharmacy.location.latitude,
          endLongitude: pharmacy.location.longitude,
        );

        // Include all pharmacies regardless of distance
        searchResults.add(MedicineSearchResult(
          pharmacy: pharmacy,
          medicine: inventory,
          distance: distance,
        ));

      } catch (e) {
        debugPrint('Error building search result for inventory ${inventory.id}: $e');
      }
    }

    return searchResults;
  }

  /// Check if medicine name matches search term (case-insensitive, partial match)
  static bool _matchesMedicineName(String medicineName, String searchTerm) {
    final medicine = medicineName.toLowerCase().trim();
    final search = searchTerm.toLowerCase().trim();
    
    // Exact match or contains search term
    return medicine == search || medicine.contains(search);
  }

  /// Search medicines with additional filters
  static Future<List<MedicineSearchResult>> searchMedicinesWithFilters({
    required String medicineName,
    Position? userPosition,
    double? maxPrice,
    bool? requiresPrescription,
    String? category,
    bool openPharmaciesOnly = false,
  }) async {
    try {
      // Get basic search results
      final results = await searchMedicinesNearby(
        medicineName: medicineName,
        userPosition: userPosition,
      );

      // Apply additional filters
      return results.where((result) {
        // Price filter
        if (maxPrice != null && result.medicine.price > maxPrice) {
          return false;
        }

        // Prescription filter
        if (requiresPrescription != null &&
            result.medicine.requiresPrescription != requiresPrescription) {
          return false;
        }

        // Category filter
        if (category != null &&
            !result.medicine.category.toLowerCase().contains(category.toLowerCase())) {
          return false;
        }

        // Open pharmacy filter
        if (openPharmaciesOnly && !result.pharmacy.isOpen) {
          return false;
        }

        return true;
      }).toList();

    } catch (e) {
      debugPrint('Error in filtered medicine search: $e');
      rethrow;
    }
  }

  /// Get medicine suggestions based on partial name
  static Future<List<String>> getMedicineSuggestions({
    required String partialName,
    int limit = 10,
  }) async {
    try {
      if (partialName.length < 2) return [];

      final query = await _firestore
          .collection(_medicineInventoryCollection)
          .where('medicine_name', isGreaterThanOrEqualTo: partialName)
          .where('medicine_name', isLessThan: partialName + 'z')
          .where('quantity', isGreaterThan: 0)
          .limit(limit)
          .get();

      final suggestions = <String>{};
      for (final doc in query.docs) {
        final data = doc.data();
        final medicineName = data['medicine_name'] as String?;
        if (medicineName != null) {
          suggestions.add(medicineName);
        }
      }

      return suggestions.toList()..sort();
    } catch (e) {
      debugPrint('Error getting medicine suggestions: $e');
      return [];
    }
  }
}
