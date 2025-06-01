import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:flutter/material.dart';

/// Utility class for setting up Firestore collections with sample data
/// This is useful for testing and development purposes
class FirestoreSetupHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GeoFlutterFire _geo = GeoFlutterFire();

  /// Create sample pharmacy data
  static Future<void> createSamplePharmacies() async {
    try {
      final pharmaciesCollection = _firestore.collection('pharmacies');
      
      // Sample pharmacies with locations (you can adjust these coordinates)
      final samplePharmacies = [
        {
          'name': 'HealthCare Pharmacy',
          'address': '123 Main Street, Lahore, Pakistan',
          'location': const GeoPoint(31.5204, 74.3587), // Lahore coordinates
          'phoneNumber': '+92 42 1234567',
          'operatingHours': [
            'Monday: 8:00 AM - 10:00 PM',
            'Tuesday: 8:00 AM - 10:00 PM',
            'Wednesday: 8:00 AM - 10:00 PM',
            'Thursday: 8:00 AM - 10:00 PM',
            'Friday: 8:00 AM - 10:00 PM',
            'Saturday: 9:00 AM - 9:00 PM',
            'Sunday: 10:00 AM - 8:00 PM',
          ],
          'isOpen': true,
        },
        {
          'name': 'MediCare Plus',
          'address': '456 Liberty Market, Gulberg, Lahore',
          'location': const GeoPoint(31.5250, 74.3500),
          'phoneNumber': '+92 42 2345678',
          'operatingHours': [
            'Monday: 9:00 AM - 11:00 PM',
            'Tuesday: 9:00 AM - 11:00 PM',
            'Wednesday: 9:00 AM - 11:00 PM',
            'Thursday: 9:00 AM - 11:00 PM',
            'Friday: 9:00 AM - 11:00 PM',
            'Saturday: 9:00 AM - 11:00 PM',
            'Sunday: 10:00 AM - 10:00 PM',
          ],
          'isOpen': true,
        },
        {
          'name': 'City Pharmacy',
          'address': '789 Mall Road, Lahore',
          'location': const GeoPoint(31.5400, 74.3200),
          'phoneNumber': '+92 42 3456789',
          'operatingHours': [
            'Monday: 8:30 AM - 9:30 PM',
            'Tuesday: 8:30 AM - 9:30 PM',
            'Wednesday: 8:30 AM - 9:30 PM',
            'Thursday: 8:30 AM - 9:30 PM',
            'Friday: 8:30 AM - 9:30 PM',
            'Saturday: 9:00 AM - 9:00 PM',
            'Sunday: Closed',
          ],
          'isOpen': false,
        },
      ];

      for (int i = 0; i < samplePharmacies.length; i++) {
        await pharmaciesCollection.doc('pharmacy_$i').set(samplePharmacies[i]);
      }

      debugPrint('Sample pharmacies created successfully');
    } catch (e) {
      debugPrint('Error creating sample pharmacies: $e');
    }
  }

  /// Create sample medicine inventory data
  static Future<void> createSampleMedicineInventory() async {
    try {
      final inventoryCollection = _firestore.collection('medicine_inventory');
      
      // Get pharmacy IDs (assuming they were created with the pattern pharmacy_0, pharmacy_1, etc.)
      final pharmacyIds = ['pharmacy_0', 'pharmacy_1', 'pharmacy_2'];
      
      // Sample medicines with different pharmacies
      final sampleMedicines = [
        // Pharmacy 0 medicines
        {
          'pharmacyId': pharmacyIds[0],
          'medicine_name': 'Paracetamol 500mg',
          'category': 'Pain Relief',
          'manufacturer': 'GSK',
          'price': 25.50,
          'quantity': 150,
          'unit': 'tablets',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
          'requiresPrescription': false,
          'description': 'Pain reliever and fever reducer',
          'location': const GeoPoint(31.5204, 74.3587),
        },
        {
          'pharmacyId': pharmacyIds[0],
          'medicine_name': 'Amoxicillin 250mg',
          'category': 'Antibiotics',
          'manufacturer': 'Pfizer',
          'price': 120.00,
          'quantity': 50,
          'unit': 'capsules',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 300))),
          'requiresPrescription': true,
          'description': 'Antibiotic for bacterial infections',
          'location': const GeoPoint(31.5204, 74.3587),
        },
        {
          'pharmacyId': pharmacyIds[0],
          'medicine_name': 'Ibuprofen 400mg',
          'category': 'Pain Relief',
          'manufacturer': 'Abbott',
          'price': 45.75,
          'quantity': 75,
          'unit': 'tablets',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 400))),
          'requiresPrescription': false,
          'description': 'Anti-inflammatory pain reliever',
          'location': const GeoPoint(31.5204, 74.3587),
        },
        
        // Pharmacy 1 medicines
        {
          'pharmacyId': pharmacyIds[1],
          'medicine_name': 'Paracetamol 500mg',
          'category': 'Pain Relief',
          'manufacturer': 'GSK',
          'price': 22.00,
          'quantity': 200,
          'unit': 'tablets',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 330))),
          'requiresPrescription': false,
          'description': 'Pain reliever and fever reducer',
          'location': const GeoPoint(31.5250, 74.3500),
        },
        {
          'pharmacyId': pharmacyIds[1],
          'medicine_name': 'Cetirizine 10mg',
          'category': 'Allergy',
          'manufacturer': 'Johnson & Johnson',
          'price': 85.50,
          'quantity': 30,
          'unit': 'tablets',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 450))),
          'requiresPrescription': false,
          'description': 'Antihistamine for allergies',
          'location': const GeoPoint(31.5250, 74.3500),
        },
        {
          'pharmacyId': pharmacyIds[1],
          'medicine_name': 'Cough Syrup',
          'category': 'Cough & Cold',
          'manufacturer': 'Bayer',
          'price': 95.00,
          'quantity': 25,
          'unit': 'bottles',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 280))),
          'requiresPrescription': false,
          'description': 'Relief from cough and cold symptoms',
          'location': const GeoPoint(31.5250, 74.3500),
        },
        
        // Pharmacy 2 medicines
        {
          'pharmacyId': pharmacyIds[2],
          'medicine_name': 'Aspirin 81mg',
          'category': 'Cardiovascular',
          'manufacturer': 'Bayer',
          'price': 35.25,
          'quantity': 100,
          'unit': 'tablets',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 500))),
          'requiresPrescription': false,
          'description': 'Low-dose aspirin for heart health',
          'location': const GeoPoint(31.5400, 74.3200),
        },
        {
          'pharmacyId': pharmacyIds[2],
          'medicine_name': 'Vitamin D3',
          'category': 'Vitamins',
          'manufacturer': 'Nature Made',
          'price': 180.00,
          'quantity': 40,
          'unit': 'tablets',
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 600))),
          'requiresPrescription': false,
          'description': 'Vitamin D supplement',
          'location': const GeoPoint(31.5400, 74.3200),
        },
      ];

      // Create geo data for each medicine
      for (int i = 0; i < sampleMedicines.length; i++) {
        final medicine = sampleMedicines[i];
        final location = medicine['location'] as GeoPoint;
        
        // Create GeoFirePoint for the location
        final geoPoint = _geo.point(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        
        // Add geo data to the medicine document
        final medicineWithGeo = {
          ...medicine,
          'location': geoPoint.data, // This adds the required geo fields
        };
        
        await inventoryCollection.doc('medicine_$i').set(medicineWithGeo);
      }

      debugPrint('Sample medicine inventory created successfully');
    } catch (e) {
      debugPrint('Error creating sample medicine inventory: $e');
    }
  }

  /// Setup all sample data
  static Future<void> setupSampleData() async {
    try {
      debugPrint('Setting up sample data...');
      
      // Create pharmacies first
      await createSamplePharmacies();
      
      // Wait a bit to ensure pharmacies are created
      await Future.delayed(const Duration(seconds: 2));
      
      // Then create medicine inventory
      await createSampleMedicineInventory();
      
      debugPrint('Sample data setup completed!');
    } catch (e) {
      debugPrint('Error setting up sample data: $e');
    }
  }

  /// Clear all sample data (useful for testing)
  static Future<void> clearSampleData() async {
    try {
      // Delete all documents in pharmacies collection
      final pharmaciesSnapshot = await _firestore.collection('pharmacies').get();
      for (final doc in pharmaciesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all documents in medicine_inventory collection
      final inventorySnapshot = await _firestore.collection('medicine_inventory').get();
      for (final doc in inventorySnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Sample data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing sample data: $e');
    }
  }

  /// Get collection statistics
  static Future<void> printCollectionStats() async {
    try {
      final pharmaciesCount = await _firestore.collection('pharmacies').get();
      final inventoryCount = await _firestore.collection('medicine_inventory').get();
      
      debugPrint('Collection Statistics:');
      debugPrint('Pharmacies: ${pharmaciesCount.docs.length}');
      debugPrint('Medicine Inventory: ${inventoryCount.docs.length}');
    } catch (e) {
      debugPrint('Error getting collection stats: $e');
    }
  }
}
