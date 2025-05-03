// Firebase User

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:encrypt/encrypt.dart' as ee;
import 'package:email_validator/email_validator.dart';
import '../firebase_database.dart';

// ignore: constant_identifier_names
const api_key = "AIzaSyCjZK5ojHcJQh8Sr0sdMG0Nlnga4D94FME";
// ignore: constant_identifier_names
const project_id = "healsearch-6565e";

class User {
  // Instance Variables
  String email;
  String password;
  String phNo;
  String? uid; // Adding UID for reference

  final key = "%D*G-JaNdRgUkXp2";
  
  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Constructor
  User({required this.email, this.password = "", this.phNo = "", this.uid});

  // -----------------------
  // ----- SET LOCATION ----
  // -----------------------
  Future<bool> setLocation(double lat, double lon) async {
    // set user location
    // return true if success
    // return false if failed
    print("Setting user location");

    try {
      // Get the current user, either from parameter or from Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser == null && uid == null) {
        print("No user is logged in and no UID provided");
        return false;
      }
      
      final userUid = uid ?? currentUser!.uid;
      
      final locationData = {
        "location": GeoPoint(lat, lon),
        "updatedAt": FieldValue.serverTimestamp(),
      };
      
      // Get address information for the location
      try {
        // Use Firebase API to get address
        Flutter_api api = Flutter_api();
        final address = await api.getAddress(lat, lon);
        locationData["address"] = address;
      } catch (e) {
        print("Could not fetch address for location: $e");
        // Continue anyway, the location coordinates are more important
      }
      
      // Use a batch for atomic updates
      WriteBatch batch = _firestore.batch();
      
      // Update in users collection
      batch.update(
        _firestore.collection(FirestoreCollections.users).doc(userUid),
        locationData
      );
      
      // Update in legacy collection
      batch.update(
        _firestore.collection(FirestoreCollections.appData).doc(email),
        locationData
      );
      
      await batch.commit();
      
      print("Location updated successfully");
      return true;
    } catch (e) {
      print("Error setting location: $e");
      return false;
    }
  }

  // --------------------------
  // ---- GET LOCATION --------
  // --------------------------
  Future<Map<String, dynamic>?> getLocation() async {
    // Getting the User Location if exists
    try {
      // Try to get location from users collection first
      if (uid != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get();
            
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('location')) {
            return {
              'location': userData['location'],
              'address': userData['address'] ?? 'Unknown location'
            };
          }
        }
      }
      
      // Fall back to legacy collection if needed
      DocumentSnapshot legacyDoc = await _firestore
          .collection(FirestoreCollections.appData)
          .doc(email)
          .get();
          
      if (legacyDoc.exists) {
        Map<String, dynamic> data = legacyDoc.data() as Map<String, dynamic>;
        if (data.containsKey('location')) {
          GeoPoint geoPoint = data['location'];
          print("Location found: ${geoPoint.latitude}, ${geoPoint.longitude}");
          return {
            'location': data['location'],
            'address': data['address'] ?? 'Unknown location'
          };
        }
      }
      
      print("No location data found for user");
      return null;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // --------------------------
  // ---- REGISTER  -----------
  // --------------------------
  Future<bool> register() async {
    // Use the improved registration method from Flutter_api
    try {
      Flutter_api api = Flutter_api();
      final success = await api.register(email, "", phNo, password);
      
      if (success) {
        // Update the UID property with the current user's UID
        final currentUser = api.getCurrentUser();
        if (currentUser != null) {
          uid = currentUser.uid;
        }
      }
      
      return success;
    } catch (e) {
      print("Registration error: $e");
      return false;
    }
  }

  // --------------------------
  // ---- LOGIN  -----------
  // --------------------------
  Future<bool> login() async {
    // Use the improved login method from Flutter_api
    try {
      Flutter_api api = Flutter_api();
      final success = await api.check_login(email, password);
      
      if (success) {
        // Update the UID property with the current user's UID
        final currentUser = api.getCurrentUser();
        if (currentUser != null) {
          uid = currentUser.uid;
        }
      }
      
      return success;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  // -------------------------
  // --- PASSWORD ENCRYPTION--
  // -------------------------
  String encrypt(String plainText) {
    // Encrypting the password
    final newKey = ee.Key.fromUtf8(key); // 16 bytes for AES-128
    final iv = ee.IV.fromLength(16);

    final encrypter = ee.Encrypter(ee.AES(newKey));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    // Decrypting the password
    final newKey = ee.Key.fromUtf8(key);
    final iv = ee.IV.fromLength(16);

    final encrypter = ee.Encrypter(ee.AES(newKey));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    return decrypted;
  }

  // -------------------------
  // -------- VALIDATION -----
  // -------------------------
  // Email Validation
  bool validateEmail() {
    return EmailValidator.validate(email);
  }

  // Password Validation
  bool validatePassword(String password, [int minLength = 6]) {
    if (password.isEmpty) {
      return false;
    }
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasMinLength = password.length >= minLength;

    return hasDigits & hasUppercase & hasLowercase & hasMinLength;
  }
  
  // Get user data from Firebase
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      Flutter_api api = Flutter_api();
      return await api.getUserData();
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Flutter_api api = Flutter_api();
      return await api.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        additionalData: additionalData,
      );
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      Flutter_api api = Flutter_api();
      await api.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
