import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Debug utility to inspect Firebase data structure
class FirebaseDebugUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug all pharmacies in the database
  static Future<void> debugPharmacies() async {
    try {
      debugPrint('🐛 === DEBUGGING PHARMACIES COLLECTION ===');
      final snapshot = await _firestore.collection('pharmacies').get();
      debugPrint('📊 Total pharmacies found: ${snapshot.docs.length}');

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        debugPrint('🏥 Pharmacy $i:');
        debugPrint('   Document ID: ${doc.id}');
        debugPrint('   Name: ${data['name']}');
        debugPrint('   ShopId: ${data['shopId']}');
        debugPrint('   All data: $data');
        debugPrint('');
      }
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

  /// Run complete debugging
  static Future<void> debugAll() async {
    await debugPharmacies();
    await debugProducts();
  }
}
