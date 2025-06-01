import 'package:cloud_firestore/cloud_firestore.dart';
import 'pharmacy.dart';
import 'medicine_inventory.dart';

class MedicineSearchResult {
  final Pharmacy pharmacy;
  final MedicineInventory medicine;
  final double distance; // Distance in kilometers

  MedicineSearchResult({
    required this.pharmacy,
    required this.medicine,
    required this.distance,
  });

  // Helper getters for easy access
  String get pharmacyName => pharmacy.name;
  String get medicineName => medicine.medicineName;
  double get price => medicine.price;
  int get stockQuantity => medicine.quantity;
  String get address => pharmacy.address;
  String get phoneNumber => pharmacy.phoneNumber;
  bool get isPharmacyOpen => pharmacy.isOpen;
  bool get requiresPrescription => medicine.requiresPrescription;
  String get unit => medicine.unit;
  double get latitude => pharmacy.location.latitude;
  double get longitude => pharmacy.location.longitude;
  
  // Distance formatted to 2 decimal places
  String get formattedDistance => '${distance.toStringAsFixed(2)} km';
}
