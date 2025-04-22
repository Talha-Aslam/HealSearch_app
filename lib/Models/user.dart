// Firebase User

// ignore_for_file: avoid_print

import 'package:firedart/firedart.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:encrypt/encrypt.dart' as ee;
// config file (in lib folder)
import 'package:email_validator/email_validator.dart';
// import 'package:flutter_pw_validator/flutter_pw_validator.dart';

// ignore: constant_identifier_names
const api_key = "AIzaSyCjZK5ojHcJQh8Sr0sdMG0Nlnga4D94FME";
// ignore: constant_identifier_names
const project_id = "searchaholic-86248";

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
      Firestore.instance.collection("appData");

      await Firestore.instance.collection("appData").document(email).set({
        "location": GeoPoint(lat, lon),
      });
      print("Success");
      return Future<bool>.value(true);
    } catch (e) {
      return Future<bool>.value(false);
    }
  }

// --------------------------
// ---- GET LOCATION --------
// --------------------------
  Future<Document> getLocation() async {
    // Getting the User Location if exists
    // return the document if exists
    if (await Firestore.instance.collection("appData").document(email).exists) {
      var data = Firestore.instance.collection("appData").document(email).get();

      // printing location
      data.then((value) => {
            print(value),
            print(value["location"]),
            print(value["location"]["lat"]),
            print(value["location"]["lon"]),
          });

      return Future<Document>.value(data);
    } else {
      ("No Data Found");
      // ignore: null_argument_to_non_null_type
      return Future<Document>.value(null);
    }
  }

// --------------------------
// ---- REGISTER  -----------
// --------------------------
  Future<bool> register() async {
    // Registering the user

    if (await Firestore.instance.collection("appData").document(email).exists) {
      print("User Already Exists");
      return Future<bool>.value(false);
    } else {
      try {
        Firestore.instance.collection("appData");
        await Firestore.instance.collection("appData").document(email).set({
          "email": email,
          "password": password,
          "phNo": phNo,
        });
        print("Success");
        return Future<bool>.value(true);
      } catch (e) {
        return Future<bool>.value(false);
      }
    }
  }

// --------------------------
// ---- LOGIN  -----------
// --------------------------
  Future<bool> login() async {
    // Login the user

    if (await Firestore.instance.collection("appData").document(email).exists) {
      var data =
          await Firestore.instance.collection("appData").document(email).get();
      var password = decrypt(data["password"]);

      if (data["password"] == password) {
        print("Success");
        return Future<bool>.value(true);
      } else {
        print("Wrong Password");
        return Future<bool>.value(false);
      }
    } else {
      print("No Data Found");
      return Future<bool>.value(false);
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
