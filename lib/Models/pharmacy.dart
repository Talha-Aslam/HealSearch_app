import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String phoneNumber;
  final List<String> operatingHours;
  final bool isOpen;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.phoneNumber,
    required this.operatingHours,
    required this.isOpen,
  });

  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pharmacy(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      phoneNumber: data['phoneNumber'] ?? '',
      operatingHours: List<String>.from(data['operatingHours'] ?? []),
      isOpen: data['isOpen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'phoneNumber': phoneNumber,
      'operatingHours': operatingHours,
      'isOpen': isOpen,
    };
  }
}
