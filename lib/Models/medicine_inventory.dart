import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineInventory {
  final String id;
  final String pharmacyId;
  final String medicineName;
  final String category;
  final String manufacturer;
  final double price;
  final int quantity;
  final String unit; // e.g., "tablets", "ml", "capsules"
  final DateTime expiryDate;
  final bool requiresPrescription;
  final String? description;
  final GeoPoint location; // Pharmacy location for geo queries

  MedicineInventory({
    required this.id,
    required this.pharmacyId,
    required this.medicineName,
    required this.category,
    required this.manufacturer,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.requiresPrescription,
    this.description,
    required this.location,
  });

  factory MedicineInventory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicineInventory(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      medicineName: data['medicine_name'] ?? '',
      category: data['category'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requiresPrescription: data['requiresPrescription'] ?? false,
      description: data['description'],
      location: data['location'] ?? const GeoPoint(0, 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'medicine_name': medicineName,
      'category': category,
      'manufacturer': manufacturer,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'requiresPrescription': requiresPrescription,
      'description': description,
      'location': location,
    };
  }

  bool get isInStock => quantity > 0;
  bool get isExpired => expiryDate.isBefore(DateTime.now());
}
