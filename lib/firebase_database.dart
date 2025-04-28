// ignore_for_file: avoid_print, camel_case_types, non_constant_identifier_names
// ignore_for_file: constant_identifier_names
// import 'dart:convert';
// import 'package:alert/Alert.dart';

import 'package:firedart/firedart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

const api_key = "AIzaSyCjZK5ojHcJQh8Sr0sdMG0Nlnga4D94FME";
const project_id = "searchaholic-86248";
// const api_key = "AIzaSyBg4u6aeIDzvj4ZfPSnTGAzNBDR5sbui_U";
// const project_id = "searchaholic-3f04a";

class Flutter_api {
  // Main Function
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      Firestore.initialize(project_id); // Establishing connection with Firestore
      print("Firestore Initialized");
    } catch (e) {
      // If Firestore is already initialized, just print a message
      print("Firestore is already initialized");
    }
  }

  // checking login of members
  Future<bool> check_login(String email, String password) async {
    // Getting the User Collection
    final managers = Firestore.instance.collection("appData");

    final manager = managers.document(email);
    print(manager);

    // Getting the Data from the Document
    try {
      final data = await manager.get();
      if (data['password'] == password && data['email'] == email) {
        return Future<bool>.value(true);
      } else {
        return Future<bool>.value(false);
      }
    } catch (e) {
      return Future<bool>.value(false);
    }
  }

  // Registration
  Future<bool> register(
      String email, String storeName, String phNo, String password) async {
    // Splitting the Location

    // Checking if the email is already registered
    final managers = Firestore.instance.collection("appData");

    // Checking for the document with the email
    if (await managers.document(email).exists) {
      return Future<bool>.value(false);
    } else {
      // Creating a new document with the email
      final manager = managers.document(email);
      // Adding the data to the document
      await manager.set({
        'email': email,
        'name': storeName,
        'phNo': phNo,
        'password': password,
      });
      return Future<bool>.value(true);
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
  Future<String> getAddress(lat, lon) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    Placemark place = placemarks[0];
    String address = "${place.locality}, ${place.country}";
    return address;
  }

  Future<List> getAllProducts() async {
    // We have products collection which contains all the products againt each storeid
    final storeIds = await Firestore.instance.collection("Products").get();
    final allProducts = [];

    for (var store in storeIds) {
      final products = await store.reference.get();

      for (var product in products.map.values) {
        allProducts.add(product);
      }
    }
    return Future<List>.value(allProducts);
  }

  Future<void> searchQuery(
      String query, double latitude, double longitude) async {
    // Getting the products with productName and within 10 km radius

    // int radius = 10;

    final storeIds = await Firestore.instance.collection("Products").get();

    for (var store in storeIds) {
      final products = await store.reference.get();

      for (var product in products.map.values) {
        // Checking if the product name contains the query
        if (product['Name'].toString().contains(query)) {
          print(product['Name']);
        }
      }
    }
  }

  Future<Document> getStorePosition(String storeEmail) async {
    var StoreDetails = await Firestore.instance
        .collection(storeEmail)
        .document("Store Details")
        .get();

    return Future<Document>.value(StoreDetails["storeLocation"]);
  }

  String getGoogleMapsLink(lattitude, longitude) {
    return "http://www.google.com/maps/place/$lattitude,$longitude";
  }
}
