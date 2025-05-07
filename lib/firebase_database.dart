// ignore_for_file: avoid_print, camel_case_types

import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:async';
import 'firebase_options.dart';
import 'registration.dart'; // Import the registration service

/// Class containing all Firestore collection names to ensure consistency
class FirestoreCollections {
  static const String users = "users";
  static const String appData =
      "appData"; // Legacy collection, kept for backward compatibility
  static const String products = "Products";
  static const String stores = "stores";
  static const String userLocations = "user_locations";
  static const String searchHistory = "search_history";
}

/// Main API class for Firebase operations
class Flutter_api {
  // Singleton instance
  static final Flutter_api _instance = Flutter_api._internal();

  // Factory constructor
  factory Flutter_api() => _instance;

  // Internal constructor
  Flutter_api._internal();

  // Reference to the registration service
  final UserRegistrationService _registrationService =
      UserRegistrationService();

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Local cache for user data
  final Map<String, dynamic> _userDataCache = {};
  final Map<String, dynamic> _productsCache = {};
  DateTime? _productsCacheTime;

  // Cache expiration duration
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Main initialization function
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      // Firebase is initialized in main.dart with Firebase.initializeApp()
      print("Firestore is ready to use");
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  // Clear all caches - useful when signing out
  void clearCaches() {
    _userDataCache.clear();
    _productsCache.clear();
    _productsCacheTime = null;
  }

  // Public method to check internet connectivity using the improved implementation
  Future<bool> checkInternetConnectivity() async {
    // Delegate to the registration service's implementation for consistency
    return _registrationService.checkInternetConnectivity();
  }

  // Check login with proper error handling
  Future<bool> check_login(String email, String password) async {
    try {
      // Check connectivity first
      if (!await checkInternetConnectivity()) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message:
              'No internet connection. Please check your network settings and try again.',
        );
      }

      // Implement retry logic with proper backoff
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries) {
        try {
          // Try to sign in, handling reCAPTCHA issues
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // If successful, update the last login time and return true
          if (userCredential.user != null) {
            final uid = userCredential.user!.uid;

            // Update the last login time in Firestore using a transaction
            try {
              await _firestore.runTransaction((transaction) async {
                DocumentReference userRef =
                    _firestore.collection(FirestoreCollections.users).doc(uid);
                transaction.update(userRef, {
                  'lastLogin': FieldValue.serverTimestamp(),
                  'isActive': true
                });
              });

              // Update legacy collection for backward compatibility
              try {
                await _firestore
                    .collection(FirestoreCollections.appData)
                    .doc(email)
                    .update({
                  'lastLogin': FieldValue.serverTimestamp(),
                });
              } catch (e) {
                // Ignore errors with legacy collection
              }
            } catch (e) {
              // If updating the timestamp fails, we still want to consider the login successful
              // but we should log the error
              debugPrint("Failed to update last login time: $e");
            }

            // Clear and pre-populate the user data cache
            await getUserData(forceRefresh: true);

            return true;
          }
          return false;
        } on FirebaseAuthException catch (e) {
          debugPrint(
              "Login attempt $retryCount failed: ${e.code} - ${e.message}");

          // Handle specific error cases
          if (e.code == 'invalid-credential' ||
              e.toString().contains('RecaptchaCallWrapper') ||
              e.message?.contains('RecaptchaAction') == true) {
            // For reCAPTCHA issues, we'll retry with backoff
            if (retryCount < maxRetries) {
              retryCount++;
              // Exponential backoff: wait longer between retries
              await Future.delayed(Duration(seconds: retryCount * 2));
              continue;
            }

            // If we've exhausted retries, try a forced sign-out then sign-in
            if (retryCount == maxRetries) {
              await _auth.signOut();
              // Wait before trying again
              await Future.delayed(const Duration(seconds: 1));
              retryCount++;
              continue;
            }
          }

          // For any other error, or if we've tried all our options, rethrow
          rethrow;
        }
      }

      // If we get here, all retries failed
      throw FirebaseAuthException(
        code: 'auth-retry-failed',
        message:
            'Authentication failed after multiple attempts. Please try again later.',
      );
    } catch (e) {
      // Handle other errors
      debugPrint("Login error: $e");

      // Check if user is actually signed in despite the error
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return true;
      }

      return false;
    }
  }

  // Use the new UserRegistrationService for registration
  Future<bool> register(
      String email, String name, String phoneNumber, String password) async {
    try {
      final result = await _registrationService.register(
          email, name, phoneNumber, password);

      // Check the success status from the map and return a boolean
      return result['success'] == true;
    } catch (e) {
      // Just forward any exceptions
      rethrow;
    }
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
  Future<String> getAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.locality ?? ''}, ${place.country ?? ''}";
        return address.trim().isEmpty ? "Unknown location" : address;
      }
      return "Unknown location";
    } catch (e) {
      print("Error getting address: $e");
      return "Error getting address";
    }
  }

  // Save user location to Firestore
  Future<bool> saveUserLocation(String email, double lat, double lon,
      {String? address}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final locationData = {
        'location': GeoPoint(lat, lon),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (address != null) {
        locationData['address'] = address;
      } else {
        // Try to get address if not provided
        try {
          locationData['address'] = await getAddress(lat, lon);
        } catch (_) {
          // Ignore errors getting address
        }
      }

      // Save to both collections for compatibility
      WriteBatch batch = _firestore.batch();

      // Save to user document
      batch.update(
          _firestore.collection(FirestoreCollections.users).doc(user.uid),
          locationData);

      // Save to legacy appData collection
      batch.update(
          _firestore.collection(FirestoreCollections.appData).doc(email),
          locationData);

      await batch.commit();

      // Update cache
      if (_userDataCache.containsKey(user.uid)) {
        _userDataCache[user.uid]?['location'] = locationData['location'];
        _userDataCache[user.uid]?['address'] = locationData['address'];
      }

      return true;
    } catch (e) {
      print("Error saving location: $e");
      return false;
    }
  }

  // Get all products with caching
  Future<List<Map<String, dynamic>>> getAllProducts(
      {bool forceRefresh = false}) async {
    // Check if we have a valid cache
    final now = DateTime.now();
    if (!forceRefresh &&
        _productsCacheTime != null &&
        _productsCache.isNotEmpty &&
        now.difference(_productsCacheTime!) < _cacheDuration) {
      // Return cached data
      return _productsCache.values.toList().cast<Map<String, dynamic>>();
    }

    try {
      final allProducts = <Map<String, dynamic>>[];

      // Get all products from the Products collection
      QuerySnapshot storeSnapshot =
          await _firestore.collection(FirestoreCollections.products).get();

      for (var doc in storeSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          // Add document ID to data for reference
          data['documentId'] = doc.id;

          // If data contains sub-maps of products, extract them
          if (data.values.any((v) => v is Map)) {
            data.values.whereType<Map>().forEach((product) {
              if (product is Map<String, dynamic>) {
                // Add store ID reference
                product['storeId'] = doc.id;
                allProducts.add(product);
              }
            });
          } else {
            // If the document itself is a product
            allProducts.add(data);
          }
        }
      }

      // Update the cache
      _productsCache.clear();
      for (var i = 0; i < allProducts.length; i++) {
        final product = allProducts[i];
        _productsCache['product_$i'] = product;
      }
      _productsCacheTime = now;

      return allProducts;
    } catch (e) {
      print("Error getting products: $e");

      // If we have cached data, return it as fallback
      if (_productsCache.isNotEmpty) {
        return _productsCache.values.toList().cast<Map<String, dynamic>>();
      }

      return [];
    }
  }

  // Search for products by name and location
  Future<List<Map<String, dynamic>>> searchProducts(String query,
      {double? latitude, double? longitude, double radiusKm = 10}) async {
    try {
      // Get all products first (uses cache when available)
      final allProducts = await getAllProducts();

      if (query.isEmpty) {
        return allProducts;
      }

      // Filter by product name
      final filteredByName = allProducts.where((product) {
        final name = product['Name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();

      // If location search is not requested, return name-filtered results
      if (latitude == null || longitude == null) {
        return filteredByName;
      }

      // For location filtering
      final userLocation = GeoPoint(latitude, longitude);

      // Filter by proximity if location data is available
      return filteredByName.where((product) {
        // Check if product has location data
        final hasLocation =
            product.containsKey('location') && product['location'] is GeoPoint;
        if (!hasLocation) return false;

        // Calculate distance
        final GeoPoint productLocation = product['location'];
        final lat1 = userLocation.latitude;
        final lon1 = userLocation.longitude;
        final lat2 = productLocation.latitude;
        final lon2 = productLocation.longitude;

        // Approximate distance calculation using Haversine formula
        const earthRadiusKm = 6371.0;
        final dLat = _degreesToRadians(lat2 - lat1);
        final dLon = _degreesToRadians(lon2 - lon1);

        final a = (sin(dLat / 2) * sin(dLat / 2)) +
            (cos(_degreesToRadians(lat1)) *
                cos(_degreesToRadians(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2));
        final c = 2 * atan2(sqrt(a), sqrt(1 - a));
        final distance = earthRadiusKm * c;

        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      print("Error searching products: $e");
      return [];
    }
  }

  // Helper method for distance calculation
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get store details
  Future<Map<String, dynamic>?> getStoreDetails(String storeId) async {
    try {
      DocumentSnapshot storeDoc = await _firestore
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .get();

      if (storeDoc.exists) {
        final data = storeDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          // Add document ID
          data['id'] = storeDoc.id;
          return data;
        }
      }

      // Try legacy format for backward compatibility
      DocumentSnapshot legacyDoc =
          await _firestore.collection(storeId).doc("Store Details").get();

      if (legacyDoc.exists) {
        final data = legacyDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          data['id'] = storeId;
          return data;
        }
      }

      return null;
    } catch (e) {
      print("Error getting store details: $e");
      return null;
    }
  }

  // Get Google Maps link from coordinates
  String getGoogleMapsLink(double latitude, double longitude) {
    return "https://www.google.com/maps/place/$latitude,$longitude";
  }

  // Get user data from Firestore with caching
  Future<Map<String, dynamic>?> getUserData({bool forceRefresh = false}) async {
    try {
      // Check if a user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("No user is currently logged in");
        return null;
      }

      // Check cache first unless forced refresh
      if (!forceRefresh && _userDataCache.containsKey(user.uid)) {
        return Map<String, dynamic>.from(_userDataCache[user.uid]);
      }

      try {
        // Get the user document from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .get();

        Map<String, dynamic>? userData;

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
        } else {
          debugPrint("User document does not exist in Firestore");

          // Try to get data from the legacy appData collection
          if (user.email != null) {
            try {
              DocumentSnapshot legacyDoc = await _firestore
                  .collection(FirestoreCollections.appData)
                  .doc(user.email)
                  .get();

              if (legacyDoc.exists) {
                userData = legacyDoc.data() as Map<String, dynamic>;

                // If found in legacy collection, create in new collection
                try {
                  await _firestore
                      .collection(FirestoreCollections.users)
                      .doc(user.uid)
                      .set({
                    ...userData,
                    'uid': user.uid,
                    'migratedFromLegacy': true,
                    'migrationTime': FieldValue.serverTimestamp(),
                  });
                } catch (e) {
                  debugPrint("Error migrating legacy user data: $e");
                }
              }
            } catch (e) {
              debugPrint("Error fetching from legacy collection: $e");
              // Continue execution - we'll return null if needed
            }
          }
        }

        // Update cache if data was found
        if (userData != null) {
          // Create a clean map to avoid casting issues
          Map<String, dynamic> cleanedMap = {};

          // First, remove the problematic PigeonUserDetails field if it exists
          userData.remove('PigeonUserDetails');

          // Then process remaining fields
          userData.forEach((key, value) {
            // Skip any fields with PigeonUserDetails in the name
            if (key.contains('PigeonUserDetails')) {
              return;
            }

            // Handle Lists - avoid issues with Lists that might cause casting problems
            if (value is List) {
              try {
                // Skip any lists that might contain PigeonUserDetails
                if (value.isNotEmpty &&
                    value.first.toString().contains('PigeonUserDetails')) {
                  return;
                }
                // Try to safely convert the list to a standard List<dynamic>
                final safeList = List<dynamic>.from(value);
                cleanedMap[key] = safeList;
              } catch (e) {
                // If conversion fails, skip this field
                debugPrint("Skipping list field $key due to casting error: $e");
              }
            } else if (value is Map) {
              // Handle nested maps safely
              try {
                cleanedMap[key] = Map<String, dynamic>.from(value);
              } catch (e) {
                // If casting fails, skip this field
                debugPrint("Skipping map field $key due to casting error: $e");
              }
            } else {
              // For primitive types like String, num, bool, and null
              cleanedMap[key] = value;
            }
          });

          _userDataCache[user.uid] = cleanedMap;
          return cleanedMap;
        }

        return userData;
      } catch (e) {
        // If there's any error with Firestore, try to get basic user info from Firebase Auth
        debugPrint(
            "Error getting user data from Firestore, falling back to Auth data: $e");

        // Create a minimal user profile from Authentication data
        if (!_userDataCache.containsKey(user.uid)) {
          _userDataCache[user.uid] = {
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? 'User',
            'fallbackData': true,
          };
        }

        return Map<String, dynamic>.from(_userDataCache[user.uid]);
      }
    } catch (e) {
      debugPrint("Error retrieving user data: $e");
      return null;
    }
  }

  // Update user profile data
  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? profileImage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Check if a user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("No user is currently logged in");
        return false;
      }

      // Create the update data map
      Map<String, dynamic> updateData = {};

      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        updateData['phoneNumber'] = phoneNumber;
      if (profileImage != null && profileImage.isNotEmpty)
        updateData['profileImage'] = profileImage;

      // Add any additional data fields
      if (additionalData != null && additionalData.isNotEmpty) {
        updateData.addAll(additionalData);
      }

      // Add update timestamp
      updateData['lastUpdated'] = FieldValue.serverTimestamp();
      updateData['profileComplete'] = true;

      // Only proceed if there is data to update
      if (updateData.isEmpty) {
        return false;
      }

      // Use a batch for atomic updates
      WriteBatch batch = _firestore.batch();

      // Update in users collection
      batch.update(
          _firestore.collection(FirestoreCollections.users).doc(user.uid),
          updateData);

      // Update in legacy collection if email is available
      if (user.email != null) {
        batch.update(
            _firestore.collection(FirestoreCollections.appData).doc(user.email),
            updateData);
      }

      await batch.commit();

      // Update cache
      if (_userDataCache.containsKey(user.uid)) {
        updateData.forEach((key, value) {
          _userDataCache[user.uid][key] = value;
        });
      }

      return true;
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      return false;
    }
  }

  // Add a product to Firestore
  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      // Check if a user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("No user is currently logged in");
        return false;
      }

      // Make sure productData has an ID
      if (!productData.containsKey('id')) {
        productData['id'] =
            _firestore.collection(FirestoreCollections.products).doc().id;
      }

      // Add metadata
      productData['createdBy'] = user.uid;
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      // Add product to Firestore
      await _firestore
          .collection(FirestoreCollections.products)
          .doc(productData['id'])
          .set(productData);

      // Invalidate products cache
      _productsCacheTime = null;

      return true;
    } catch (e) {
      debugPrint("Error adding product: $e");
      return false;
    }
  }

  // Update a product in Firestore
  Future<bool> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    try {
      // Check if a user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("No user is currently logged in");
        return false;
      }

      // Add metadata
      updates['updatedBy'] = user.uid;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      // Update product in Firestore
      await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .update(updates);

      // Invalidate products cache
      _productsCacheTime = null;

      return true;
    } catch (e) {
      debugPrint("Error updating product: $e");
      return false;
    }
  }

  // Delete a product from Firestore
  Future<bool> deleteProduct(String productId) async {
    try {
      // Check if a user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("No user is currently logged in");
        return false;
      }

      // Delete product from Firestore
      await _firestore
          .collection(FirestoreCollections.products)
          .doc(productId)
          .delete();

      // Invalidate products cache
      _productsCacheTime = null;

      return true;
    } catch (e) {
      debugPrint("Error deleting product: $e");
      return false;
    }
  }

  // Sign out and clear caches
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      clearCaches();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Google Sign-In method
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Check connectivity first
      if (!await checkInternetConnectivity()) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message:
              'No internet connection. Please check your network settings and try again.',
        );
      }

      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in flow
      if (googleUser == null) {
        return null;
      }

      try {
        // Obtain auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Failed to retrieve user after Google sign-in',
          );
        }

        // Instead of dealing with UserCredential (which causes PigeonUserDetails issues),
        // return a simple Map with the user information
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'User',
          'phoneNumber': user.phoneNumber ?? '',
          'profileImage': user.photoURL,
          'authProvider': 'google',
          'success': true,
        };

        // Check if this is a new user (first time sign-in)
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        try {
          if (isNewUser) {
            // Create a new user document in Firestore for new users
            await _firestore
                .collection(FirestoreCollections.users)
                .doc(user.uid)
                .set({
              ...userData,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'isActive': true,
            });

            // Also create entry in legacy collection for backward compatibility
            if (user.email != null) {
              try {
                await _firestore
                    .collection(FirestoreCollections.appData)
                    .doc(user.email)
                    .set({
                  'email': user.email,
                  'name': user.displayName ?? 'User',
                  'profileImage': user.photoURL,
                  'phoneNumber': user.phoneNumber ?? '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastLogin': FieldValue.serverTimestamp(),
                  'authProvider': 'google',
                });
              } catch (e) {
                // Ignore errors with legacy collection
                debugPrint("Error creating legacy user document: $e");
              }
            }
          } else {
            // Update login timestamp for existing users
            try {
              await _firestore
                  .collection(FirestoreCollections.users)
                  .doc(user.uid)
                  .update({
                'lastLogin': FieldValue.serverTimestamp(),
                'isActive': true
              });

              // Update legacy collection
              if (user.email != null) {
                try {
                  await _firestore
                      .collection(FirestoreCollections.appData)
                      .doc(user.email)
                      .update({
                    'lastLogin': FieldValue.serverTimestamp(),
                  });
                } catch (e) {
                  // Ignore errors with legacy collection
                }
              }
            } catch (e) {
              debugPrint("Failed to update last login time: $e");
            }
          }
        } catch (e) {
          debugPrint("Error updating user data in Firestore: $e");
          // Continue with the sign-in process despite Firestore errors
        }

        // Create basic user cache entry
        _userDataCache[user.uid] = userData;

        return userData;
      } catch (e) {
        // If we got an error during authentication, sign out of Google
        await _googleSignIn.signOut();
        debugPrint("Error in Google authentication: $e");

        if (e.toString().contains('PigeonUserDetails')) {
          // Special handling for PigeonUserDetails error -
          // The user is actually signed in despite this error
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            final userData = {
              'uid': currentUser.uid,
              'email': currentUser.email,
              'name': currentUser.displayName ?? 'User',
              'phoneNumber': currentUser.phoneNumber ?? '',
              'profileImage': currentUser.photoURL,
              'authProvider': 'google',
              'success': true,
            };

            // Add to cache
            _userDataCache[currentUser.uid] = userData;

            return userData;
          }
        }
        rethrow;
      }
    } catch (e) {
      debugPrint("Google sign-in error: $e");

      // Check if we still managed to sign in despite the error
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.providerData
              .any((info) => info.providerId == 'google.com')) {
        // User is signed in with Google, so consider this a success
        return {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'name': currentUser.displayName ?? 'User',
          'phoneNumber': currentUser.phoneNumber ?? '',
          'profileImage': currentUser.photoURL,
          'authProvider': 'google',
          'success': true,
        };
      }

      // Re-throw exception but with more user-friendly message
      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'google-signin-failed',
          message: 'Failed to sign in with Google. Please try again.',
        );
      }
    }
  }
}
