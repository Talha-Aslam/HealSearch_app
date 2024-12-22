import 'package:flutter/material.dart';

import 'package:my_project/splash_screen.dart';
import 'package:firedart/firedart.dart';

// ignore: constant_identifier_names
const api_key = "AIzaSyCjZK5ojHcJQh8Sr0sdMG0Nlnga4D94FME";
// ignore: constant_identifier_names
const project_id = "searchaholic-86248";
const bool isLoggedIn = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firestore.initialize(project_id); // Establishing connection with Firestore
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Search A Holic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Splash(),
    );
  }
}
