// ignore_for_file: avoid_print, camel_case_types, non_constant_identifier_names
// ignore_for_file: constant_identifier_names
// import 'dart:convert';
// import 'package:alert/Alert.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'firebase_options.dart';

const project_id = "healsearch-6565e";

class Flutter_api {
  // Main Function
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      // Firebase is initialized in main.dart with Firebase.initializeApp()
      print("Firestore is ready to use");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  // Check network connectivity
  Future<bool> _checkInternetConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    try {
      // Try to actually reach Firebase servers
      final result = await InternetAddress.lookup('firebase.google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // checking login of members
  Future<bool> check_login(String email, String password) async {
    try {
      // Check connectivity first
      if (!await _checkInternetConnectivity()) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'No internet connection. Please check your network settings and try again.',
        );
      }
      
      // Use Firebase Authentication but don't directly access user details
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Just check if the user exists, don't try to cast any internal Firebase objects
      return userCredential.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login error: ${e.message}");
      rethrow;
    } catch (e) {
      // Handle other errors, including PigeonUserDetails cast error
      debugPrint("Login error: $e");
      if (e.toString().contains('PigeonUserDetails')) {
        // Authentication likely succeeded but there's an issue with user data handling
        // Check if user is actually signed in despite the error
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          return true;
        }
      }
      return false;
    }
  }

  // Registration with enhanced retry logic
  Future<bool> register(
      String email, String storeName, String phNo, String password) async {
    // Maximum number of retry attempts
    const maxRetries = 3;
    
    // Check connectivity before attempting registration
    if (!await _checkInternetConnectivity()) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'No internet connection. Please check your network settings and try again.',
      );
    }
    
    // Initialize Firebase Auth instance with custom settings
    final auth = FirebaseAuth.instance;
    
    // Start retry loop
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("Registration attempt $attempt of $maxRetries");
        
        // Attempt to create the user
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(
          const Duration(seconds: 30), // Set a reasonable timeout
          onTimeout: () => throw FirebaseAuthException(
            code: 'timeout',
            message: 'Connection timed out. Please try again.',
          ),
        );
        
        // Make sure we have a valid UID before proceeding
        if (userCredential.user == null || userCredential.user!.uid.isEmpty) {
          throw Exception("Failed to get valid user ID from Firebase");
        }
        
        // If successful, add user data to Firestore as a simple Map (avoiding any PigeonUserDetails conversion)
        final userData = {
          'email': email,
          'name': storeName,
          'phNo': phNo,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance.collection("appData").doc(email).set(userData);
        
        print("Registration successful after $attempt attempts");
        return true;
      } on FirebaseAuthException catch (e) {
        print("Registration error on attempt $attempt: ${e.message}");
        
        // Don't retry for these specific errors
        if (e.code == 'email-already-in-use' || 
            e.code == 'invalid-email' || 
            e.code == 'weak-password') {
          rethrow; // No point retrying for these errors
        }
        
        // Network or reCAPTCHA related errors should trigger retry
        if (e.code == 'network-request-failed' || 
            e.message?.contains('network') == true ||
            e.message?.contains('recaptcha') == true ||
            e.message?.contains('timeout') == true) {
          
          if (attempt == maxRetries) {
            // This was our last attempt
            rethrow;
          }
          
          // Exponential backoff: wait longer between each retry
          final backoffSeconds = attempt * 2;
          print("Retrying in $backoffSeconds seconds...");
          await Future.delayed(Duration(seconds: backoffSeconds));
          continue; // Try again
        }
        
        // For any other errors, just rethrow
        rethrow;
      } catch (e) {
        // Handle any other errors
        print("Unexpected error during registration: $e");
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2));
      }
    }
    
    // Should never reach here due to rethrow, but to satisfy the compiler
    return false;
  }

  // Getting Current Location

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  // Getting the Address from the Location
  Future<String> getAddress(lat, lon) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    Placemark place = placemarks[0];
    String address = "${place.locality}, ${place.country}";
    return address;
  }

  Future<List> getAllProducts() async {
    // We have products collection which contains all the products against each storeid
    QuerySnapshot storeSnapshot = await FirebaseFirestore.instance.collection("Products").get();
    final allProducts = [];

    for (var store in storeSnapshot.docs) {
      DocumentSnapshot products = await store.reference.get();
      
      // Convert the data to a map and extract values
      Map<String, dynamic>? data = products.data() as Map<String, dynamic>?;
      if (data != null) {
        data.values.forEach((product) {
          allProducts.add(product);
        });
      }
    }
    
    return allProducts;
  }

  Future<void> searchQuery(
      String query, double latitude, double longitude) async {
    // Getting the products with productName and within 10 km radius

    QuerySnapshot storeSnapshot = await FirebaseFirestore.instance.collection("Products").get();

    for (var store in storeSnapshot.docs) {
      DocumentSnapshot products = await store.reference.get();
      
      // Convert the data to a map and extract values
      Map<String, dynamic>? data = products.data() as Map<String, dynamic>?;
      if (data != null) {
        data.values.forEach((product) {
          // Checking if the product name contains the query
          if (product['Name'].toString().toLowerCase().contains(query.toLowerCase())) {
            print(product['Name']);
          }
        });
      }
    }
  }

  Future<DocumentSnapshot> getStorePosition(String storeEmail) async {
    DocumentSnapshot storeDetails = await FirebaseFirestore.instance
        .collection(storeEmail)
        .doc("Store Details")
        .get();

    return storeDetails;
  }

  String getGoogleMapsLink(lattitude, longitude) {
    return "http://www.google.com/maps/place/$lattitude,$longitude";
  }
}
