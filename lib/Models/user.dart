// Firebase User

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:encrypt/encrypt.dart' as ee;
// config file (in lib folder)
import 'package:email_validator/email_validator.dart';
// import 'package:flutter_pw_validator/flutter_pw_validator.dart';

// ignore: constant_identifier_names
const api_key = "AIzaSyCjZK5ojHcJQh8Sr0sdMG0Nlnga4D94FME";
// ignore: constant_identifier_names
const project_id = "healsearch-6565e";

class User {
  // Instance Variables
  String email;
  String password;
  String phNo;

  final key = "%D*G-JaNdRgUkXp2";

  // Constructor
  User({required this.email, this.password = "", this.phNo = ""});

  // -----------------------
  // ----- SET LOCATION ----
  // -----------------------
  Future<bool> setLocation(double lat, double lon) async {
    // set user location
    // return true if success
    // return false if failed
    print("Function Called");

    try {
      await FirebaseFirestore.instance.collection("appData").doc(email).update({
        "location": GeoPoint(lat, lon),
      });
      print("Success");
      return true;
    } catch (e) {
      print("Error setting location: $e");
      return false;
    }
  }

// --------------------------
// ---- GET LOCATION --------
// --------------------------
  Future<DocumentSnapshot?> getLocation() async {
    // Getting the User Location if exists
    // return the document if exists
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("appData")
          .doc(email)
          .get();
          
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('location')) {
          // printing location
          print(data);
          print(data["location"]);
          GeoPoint geoPoint = data["location"];
          print(geoPoint.latitude);
          print(geoPoint.longitude);
        }
        return doc;
      } else {
        print("No Data Found");
        return null;
      }
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

// --------------------------
// ---- REGISTER  -----------
// --------------------------
  Future<bool> register() async {
    // Registering the user
    try {
      // First check if the user already exists
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("appData")
          .doc(email)
          .get();
          
      if (doc.exists) {
        print("User Already Exists");
        return false;
      }
      
      // Create user with Firebase Auth
      await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Then save additional user data in Firestore
      await FirebaseFirestore.instance.collection("appData").doc(email).set({
        "email": email,
        "password": encrypt(password),
        "phNo": phNo,
      });
      
      print("Registration Success");
      return true;
    } catch (e) {
      print("Registration Error: $e");
      return false;
    }
  }

// --------------------------
// ---- LOGIN  -----------
// --------------------------
  Future<bool> login() async {
    // Login the user using Firebase Auth
    try {
      await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Login Success");
      return true;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

// -------------------------
// --- PASSWORD ENCRYPTION--
// -------------------------

  String encrypt(String plainText) {
    // Encrypting the password
    // return the encrypted password
    final newKey =
        ee.Key.fromUtf8(key); // 32 bytes for AES-256, 16 bytes for AES-128
    final iv = ee.IV.fromLength(16);

    print(newKey);

    final encrypter = ee.Encrypter(ee.AES(newKey));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    // Decrypting the password
    // return the decrypted password
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
    // Validate the email
    // return true if valid
    // return false if invalid
    if (EmailValidator.validate(email)) {
      return true;
    } else {
      return false;
    }
  }

// Password Validation
  bool validatePassword(String password, [int minLength = 6]) {
    if (password.isEmpty) {
      return false;
    }
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= minLength;

    return hasDigits &
        hasUppercase &
        hasLowercase &
        // hasSpecialCharacters &
        hasMinLength;
  }
}
