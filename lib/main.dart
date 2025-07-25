import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:healsearch_app/app_state_manager.dart';
import 'package:healsearch_app/services/pharmacy_diagnostic_util.dart';
import 'firebase_options.dart';
import 'dart:isolate';
import 'dart:async';

const bool isLoggedIn = false;

// Hold references to services to prevent garbage collection
final List<Object> _services = [];

// Function to initialize services in the background
Future<void> _initializeServices() async {
  try {
    // Initialize Firebase specifically for mobile platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Only mobile-specific configurations from here
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Add global error handling for Firebase Auth
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // When we have a user, make sure we can safely access their UID
        try {
          final uid = user.uid;
          debugPrint('User is signed in with UID: $uid');

          // Preemptively initialize app data to avoid issues later
          try {
            // Try to force a data fetch in advance to catch any issues
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get()
                .then((doc) {
              if (doc.exists) {
                debugPrint('Successfully pre-loaded user data');

                // Ensure all required fields exist
                final data = doc.data();
                if (data != null &&
                    (!data.containsKey('phoneNumber') ||
                        !data.containsKey('name'))) {
                  // Add missing fields if needed
                  Map<String, dynamic> updates = {};
                  if (!data.containsKey('phoneNumber') &&
                      data.containsKey('phNo')) {
                    updates['phoneNumber'] = data['phNo'];
                  }
                  if (!data.containsKey('name') && user.displayName != null) {
                    updates['name'] = user.displayName;
                  }

                  // Update the document if we have fields to update
                  if (updates.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update(updates)
                        .then((_) =>
                            debugPrint('Updated missing user data fields'))
                        .catchError(
                            (e) => debugPrint('Error updating user data: $e'));
                  }
                }
              }
            }).catchError((e) {
              // Just log errors, don't throw
              debugPrint('Pre-load user data warning: $e');
            });
          } catch (e) {
            // Ignore any errors here
          }
        } catch (e) {
          // Handle PigeonUserDetails and other common errors
          if (e.toString().contains('PigeonUserDetails') ||
              e.toString().contains('List<Object?>') ||
              e.toString().contains('invalid-credential')) {
            debugPrint('Caught Firebase User error safely: $e');

            // Try to recover by refreshing the Firebase Auth instance
            try {
              FirebaseAuth.instance.signOut().then((_) {
                debugPrint('Signed out to reset Firebase Auth state');
              });
            } catch (signOutError) {
              debugPrint('Error during recovery sign-out: $signOutError');
            }
          } else {
            debugPrint('Unknown Firebase Auth error: $e');
          }
        }
      }
    });

    // Initialize connectivity monitoring with error handling
    try {
      final connectivity = Connectivity();
      _services.add(connectivity);
      final connectivityResult = await connectivity.checkConnectivity();
      debugPrint('Initial connectivity status: $connectivityResult');

      // Add a connectivity listener for debugging
      connectivity.onConnectivityChanged.listen((result) {
        debugPrint('Connectivity changed: $result');

        // If connection restored, try to validate Firebase connection
        if (result != ConnectivityResult.none) {
          _validateFirebaseConnection();
        }
      });
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
    }
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

// Helper function to validate Firebase connection
Future<void> _validateFirebaseConnection() async {
  try {
    // Test Firebase connection by making a simple query
    await FirebaseFirestore.instance
        .collection('app_status')
        .doc('connectivity_test')
        .set({'timestamp': FieldValue.serverTimestamp(), 'status': 'online'});
    debugPrint('Firebase connection validated successfully');
  } catch (e) {
    debugPrint('Firebase connection test failed: $e');

    // Try to reinitialize Firebase if needed
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (reinitError) {
      // Just log, don't throw
      debugPrint('Error reinitializing Firebase: $reinitError');
    }
  }
}

// Helper function to safely get Firebase user UID, handling PigeonUserDetails errors
String? safeGetFirebaseUid() {
  try {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  } catch (e) {
    // Handle specific error types
    if (e.toString().contains('PigeonUserDetails')) {
      debugPrint('PigeonUserDetails error accessing Firebase user');

      // Try refreshing the Auth state by signing out and in again
      try {
        FirebaseAuth.instance.signOut();
      } catch (_) {
        // Ignore error
      }
    } else {
      debugPrint('Error accessing Firebase user: $e');
    }
    return null;
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred device orientations to optimize performance
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Initialize services with error catching
  try {
    await _initializeServices();

    // Run diagnostic util for main function
    try {
      // Run diagnostics after a short delay to ensure Firebase is fully initialized
      debugPrint('🔍 Running pharmacy data diagnostics on startup...');
      await Future.delayed(
          const Duration(seconds: 2)); // Wait for Firebase to initialize fully

      // Run the diagnostic utility
      await PharmacyDiagnosticUtil.verifyPharmacyData();
    } catch (diagError) {
      debugPrint('⚠️ Diagnostic initialization error: $diagError');
    }
  } catch (e) {
    debugPrint('Error during service initialization: $e');
    // Continue app startup despite errors
  }

  // Enable error handling for platform channel errors (helps with OpenGL errors)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    // Filter out OpenGL ES API errors which are not critical
    if (details.exception.toString().contains('OpenGL ES API')) {
      debugPrint('Non-critical OpenGL error: ${details.exception}');
    } else {
      // Log other errors as they might be more important
      debugPrint('FlutterError: ${details.exception}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Filter out OpenGL errors and other non-critical issues
    if (error.toString().contains('OpenGL ES API') ||
        error.toString().contains('RecaptchaCallWrapper')) {
      debugPrint('Non-critical Platform error: $error');
    } else {
      debugPrint('PlatformDispatcher error: $error');
    }
    return true;
  };

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Enhanced color palette for the app
    const primaryColor = Color(0xFFE94057);
    const lightBackgroundColor = Color(0xFFF7F7F7);
    const darkBackgroundColor = Color(0xFF121212);
    const cardColorLight = Colors.white;
    const cardColorDark = Color(0xFF1E1E1E);
    const accentColor = Color(0xFF8A2387);

    return MaterialApp(
      title: 'HealSearch',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: accentColor,
          background: lightBackgroundColor,
          surface: cardColorLight,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: lightBackgroundColor,
        cardColor: cardColorLight,
        cardTheme: const CardTheme(
          color: cardColorLight,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        useMaterial3: true,
        // Improve rendering performance
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Prevent theme flash during startup
        appBarTheme: const AppBarTheme(
          backgroundColor: cardColorLight,
          foregroundColor: primaryColor,
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: cardColorLight,
          scrimColor: Colors.black54,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          secondary: accentColor,
          background: darkBackgroundColor,
          surface: cardColorDark,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: darkBackgroundColor,
        cardColor: cardColorDark,
        cardTheme: const CardTheme(
          color: cardColorDark,
          elevation: 2,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Prevent theme flash during startup in dark mode
        appBarTheme: const AppBarTheme(
          backgroundColor: cardColorDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: cardColorDark,
          scrimColor: Colors.black54,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const AppStateManager(),
    );
  }
}
