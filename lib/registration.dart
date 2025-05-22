import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:email_validator/email_validator.dart' as email_validator;
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'firebase_database.dart';

// -----------------------
// SERVICES
// -----------------------

/// Class to handle user registration processes separate from UI
class UserRegistrationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection names for consistency
  static const String usersCollection = "users";
  static const String appDataCollection = "appData";

  // Improved network connectivity check with multiple fallbacks
  Future<bool> checkInternetConnectivity() async {
    try {
      // Step 1: Check device connectivity status first (fastest)
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Step 2: Try a fast ping to Google's DNS server first (most reliable and fastest)
      try {
        final result = await InternetAddress.lookup('8.8.8.8')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // Continue to next check
      }

      // Step 3: Try a domain name lookup as fallback (handles DNS issues better)
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // Continue to final check
      }

      // Step 4: Final attempt with Firebase domain
      try {
        final result = await InternetAddress.lookup('firebase.google.com')
            .timeout(const Duration(seconds: 7));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print("Successfully connected to Firebase");
          return true;
        }
      } catch (e) {
        print("Firebase check failed: $e");
        // All checks failed, but device reports connectivity
      }

      // If we get here, we have device connectivity but can't reach internet
      print("Device shows connectivity but can't reach internet");
      return connectivityResult != ConnectivityResult.none;
    } on TimeoutException {
      print("Connectivity check timed out");
      return false;
    } on SocketException catch (e) {
      print("Socket error during connectivity check: $e");
      return false;
    } catch (e) {
      print("Unexpected error checking connectivity: $e");
      // Default to assuming connection is available if checks throw uncaught exceptions
      // This prevents false negatives from blocking registration
      return true;
    }
  }

  // Simpler, more reliable way to check if an email exists in Firebase Auth
  Future<bool> isEmailInFirebaseAuth(String email) async {
    try {
      // A more reliable way to check if email exists
      final methods = await _auth
          .fetchSignInMethodsForEmail(email.trim())
          .timeout(const Duration(seconds: 10));

      if (methods.isNotEmpty) {
        debugPrint("Email exists in Firebase Auth: $email (Methods: $methods)");
        return true;
      }

      debugPrint("Email not found in Firebase Auth: $email");
      return false;
    } catch (e) {
      // Log the error but don't block registration
      debugPrint("Error checking email in Firebase Auth: $e");
      return false;
    }
  }

  // Check if an email exists in Firestore
  Future<bool> isEmailInFirestore(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Check in appData collection where email is the document ID
      final legacyDoc = await _firestore
          .collection(appDataCollection)
          .doc(normalizedEmail)
          .get()
          .timeout(const Duration(seconds: 8));

      if (legacyDoc.exists) {
        debugPrint("Email exists in Firestore appData: $email");
        return true;
      }

      // Check in users collection by querying on email field
      final userQuery = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));

      if (userQuery.docs.isNotEmpty) {
        debugPrint("Email exists in Firestore users collection: $email");
        return true;
      }

      debugPrint("Email not found in Firestore: $email");
      return false;
    } catch (e) {
      debugPrint("Error checking email in Firestore: $e");
      return false;
    }
  }

  // Create a new account with complete error handling for PigeonUserDetails error
  Future<Map<String, dynamic>> createUserAccount(
      String email, String password, String name, String phoneNumber) async {
    final normalizedEmail = email.trim().toLowerCase();
    User? user;
    String? uid;
    bool accountCreated = false;
    String? errorMessage;

    try {
      // Step 1: First check if the email already exists in Auth
      final emailExists = await isEmailInFirebaseAuth(normalizedEmail);
      if (emailExists) {
        return {
          'success': false,
          'error': 'email-already-in-use',
          'message': 'The email address is already in use by another account.'
        };
      }

      // Step 2: Also check Firestore to be safe
      final firestoreHasEmail = await isEmailInFirestore(normalizedEmail);
      if (firestoreHasEmail) {
        return {
          'success': false,
          'error': 'email-already-in-use',
          'message': 'This email is already registered in our database.'
        };
      }

      // Step 3: Try to create the user
      debugPrint("Creating Firebase Auth account for: $normalizedEmail");

      try {
        // Try to create the user with Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        // Try to extract the user and UID immediately
        try {
          user = userCredential.user;
          uid = user?.uid;

          if (uid != null && uid.isNotEmpty) {
            debugPrint("User created successfully with UID: $uid");
            accountCreated = true;
          } else {
            throw Exception("Failed to get UID from userCredential");
          }
        } catch (uidError) {
          // This is likely the PigeonUserDetails error
          debugPrint(
              "Cannot access userCredential.user (PigeonUserDetails error): $uidError");

          // The account might still have been created, check current user
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email == normalizedEmail) {
            user = currentUser;
            uid = currentUser.uid;
            debugPrint(
                "Retrieved user from FirebaseAuth.instance.currentUser: $uid");
            accountCreated = true;
          } else {
            // Wait a moment and try again
            await Future.delayed(const Duration(milliseconds: 1000));
            final delayedUser = _auth.currentUser;
            if (delayedUser != null && delayedUser.email == normalizedEmail) {
              user = delayedUser;
              uid = delayedUser.uid;
              debugPrint("Retrieved user after delay: $uid");
              accountCreated = true;
            } else {
              throw Exception(
                  "Cannot retrieve user after PigeonUserDetails error");
            }
          }
        }
      } catch (authError) {
        if (authError is FirebaseAuthException) {
          if (authError.code == 'email-already-in-use') {
            return {
              'success': false,
              'error': 'email-already-in-use',
              'message':
                  'The email address is already in use by another account.'
            };
          }
          errorMessage = "[${authError.code}] ${authError.message}";
        } else {
          // Check if this is the PigeonUserDetails error
          if (authError.toString().contains("PigeonUserDetails") ||
              authError.toString().contains("List<Object?>") ||
              authError.toString().contains("is not a subtype")) {
            debugPrint(
                "PigeonUserDetails error detected, checking if account was created");

            // The account might still have been created despite the error
            // Wait a bit longer since this is a special case
            await Future.delayed(const Duration(milliseconds: 1500));

            final currentUser = _auth.currentUser;
            if (currentUser != null && currentUser.email == normalizedEmail) {
              user = currentUser;
              uid = currentUser.uid;
              debugPrint("Found user after PigeonUserDetails error: $uid");
              accountCreated = true;
            } else {
              // Try signing in to check if the account exists
              try {
                final signInResult = await _auth.signInWithEmailAndPassword(
                    email: normalizedEmail, password: password);

                if (signInResult.user != null) {
                  user = signInResult.user;
                  uid = user?.uid;
                  debugPrint(
                      "Successfully signed in after failed creation: $uid");
                  accountCreated = true;
                }
              } catch (signInError) {
                if (signInError is FirebaseAuthException) {
                  if (signInError.code == 'user-not-found') {
                    // Account wasn't created
                    debugPrint(
                        "Account wasn't created after PigeonUserDetails error");
                  } else if (signInError.code == 'wrong-password') {
                    // Account exists but password is wrong (unlikely but possible)
                    debugPrint(
                        "Account exists but sign-in failed: ${signInError.code}");
                    return {
                      'success': false,
                      'error': 'email-already-in-use',
                      'message':
                          'The email address is already in use by another account.'
                    };
                  } else {
                    // For other sign-in errors, assume account exists
                    debugPrint(
                        "Account may exist but sign-in failed: ${signInError.code}");
                    return {
                      'success': false,
                      'error': 'email-already-in-use',
                      'message': 'This email might already be registered.'
                    };
                  }
                }
              }
            }

            if (!accountCreated) {
              errorMessage =
                  "Account creation failed with PigeonUserDetails error";
            }
          } else {
            errorMessage = authError.toString();
          }
        }
      }

      // Step 4: If we've created the account, save user data to Firestore
      if (accountCreated && uid != null) {
        try {
          debugPrint("Saving user data to Firestore for UID: $uid");

          // Timestamp for consistency across collections
          final now = FieldValue.serverTimestamp();

          // Create user data with consistent field names
          final userData = <String, dynamic>{
            'uid': uid,
            'email': normalizedEmail,
            'name': name,
            'phoneNumber': phoneNumber, // Standardized field name
            'phNo': phoneNumber, // Legacy field name
            'createdAt': now,
            'lastLogin': now,
            'profileComplete': false,
            'isActive': true,
            'accountType': 'user',
            'registrationCompleted': true,
            'registrationDate': now,
            'deviceType': 'mobile',
            'platform': Platform.isIOS ? 'ios' : 'android',
          };

          // Use batch write for consistency
          final batch = _firestore.batch();

          // Set document reference paths for cross-referencing
          final userRef = _firestore.collection(usersCollection).doc(uid);
          final legacyRef =
              _firestore.collection(appDataCollection).doc(normalizedEmail);

          // Primary record in users collection (with UID as document ID)
          batch.set(userRef, userData);

          // Legacy record in appData collection (with email as document ID)
          // Include all the same fields for maximum compatibility
          final legacyData = Map<String, dynamic>.from(userData);
          legacyData['primaryRecordPath'] =
              userRef.path; // Add reference to primary record
          batch.set(legacyRef, legacyData);

          // Commit the batch
          await batch.commit();

          // Verify data was written successfully
          bool dataVerified = false;
          try {
            final verifyDoc = await userRef.get();
            dataVerified = verifyDoc.exists;

            if (!dataVerified) {
              debugPrint(
                  "Warning: Primary user document was not created properly");

              // Try to recover by writing directly if batch failed
              await userRef.set(userData);

              // Check again
              final recheckDoc = await userRef.get();
              dataVerified = recheckDoc.exists;
            }
          } catch (verifyError) {
            debugPrint("Error verifying user data: $verifyError");
          }

          debugPrint(
              "User data saved successfully to Firestore. Data verified: $dataVerified");
          return {
            'success': true,
            'uid': uid,
            'user': user,
            'dataVerified': dataVerified
          };
        } catch (firestoreError) {
          debugPrint("Error saving user data to Firestore: $firestoreError");

          // Try one more time with a direct write approach
          try {
            final userRef = _firestore.collection(usersCollection).doc(uid);
            final userData = <String, dynamic>{
              'uid': uid,
              'email': normalizedEmail,
              'name': name,
              'phoneNumber': phoneNumber,
              'phNo': phoneNumber, // Include both versions for compatibility
              'createdAt': FieldValue.serverTimestamp(),
              'registrationDate': FieldValue.serverTimestamp(),
              'recovery': true, // Flag that this was a recovery write
            };

            await userRef.set(userData);
            debugPrint("Successfully saved user data via recovery method");

            return {
              'success': true,
              'partial': false,
              'uid': uid,
              'user': user,
              'recovery': true
            };
          } catch (recoveryError) {
            debugPrint("Recovery attempt also failed: $recoveryError");

            // Return partial success since the account was created but data wasn't saved
            return {
              'success': true,
              'partial': true,
              'uid': uid,
              'user': user,
              'firestoreError': firestoreError.toString()
            };
          }
        }
      } else if (!accountCreated) {
        // Account creation failed
        return {
          'success': false,
          'error': 'account-creation-failed',
          'message': errorMessage ?? "Failed to create account"
        };
      }

      // Should never reach here
      return {
        'success': false,
        'error': 'unknown-error',
        'message': "An unexpected error occurred"
      };
    } catch (e) {
      debugPrint("Unexpected error in createUserAccount: $e");
      return {
        'success': false,
        'error': 'unexpected-error',
        'message': e.toString()
      };
    }
  }

  // Simplified registration flow that handles PigeonUserDetails errors properly
  Future<Map<String, dynamic>> register(
      String email, String name, String phoneNumber, String password) async {
    try {
      // Check connectivity
      final isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        return {
          'success': false,
          'error': 'network-request-failed',
          'message':
              'No internet connection. Please check your network settings and try again.'
        };
      }

      // Create the account with our comprehensive error handling
      final result =
          await createUserAccount(email, password, name, phoneNumber);

      if (kDebugMode) {
        print("Registration result: $result");
      }

      return result;
    } catch (e) {
      debugPrint("Unexpected error in register method: $e");
      return {
        'success': false,
        'error': 'unexpected-error',
        'message': e.toString()
      };
    }
  }
}

// -----------------------
// UI COMPONENTS
// -----------------------

/// Registration screen widget for user signup
class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  // -----------------------
  // STATE VARIABLES
  // -----------------------

  // Create an instance of our new Registration Service
  final _registrationService = UserRegistrationService();

  // Controller for input fields
  final email = TextEditingController();
  final name = TextEditingController();
  final phoneNumber = TextEditingController();
  final password = TextEditingController();
  final confirmPassword =
      TextEditingController(); // Added password confirmation

  // State tracking
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  bool _isConnected = true;
  bool _isObscure = true;
  bool _isConfirmPasswordObscure = true; // For confirm password visibility
  bool _isPasswordValid = false;
  bool _passwordValidationInitiated = false;
  bool _termsAccepted = false; // Terms and conditions checkbox

  // Track registration attempts to prevent duplicate submissions
  bool _registrationAttemptInProgress = false;

  // UI components
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode =
      FocusNode(); // Added focus node for confirm password
  double height = 0, width = 0;

  // -----------------------
  // LIFECYCLE METHODS
  // -----------------------

  @override
  void initState() {
    super.initState();
    // Check Firebase connection status
    _checkConnectionStatus();
  }

  @override
  void dispose() {
    // Clean up all controllers when the widget is disposed
    email.dispose();
    name.dispose();
    phoneNumber.dispose();
    password.dispose();
    confirmPassword.dispose(); // Dispose confirm password controller
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose(); // Dispose confirm password focus node
    super.dispose();
  }

  // -----------------------
  // HELPER METHODS
  // -----------------------

  /// Check if the device has network connectivity
  Future<void> _checkConnectionStatus() async {
    try {
      // Use our new service's method
      bool isConnected = await _registrationService.checkInternetConnectivity();
      setState(() {
        _isConnected = isConnected;
        if (!isConnected) {
          _errorMessage =
              "No internet connection. Please check your network settings.";
        }
      });
    } catch (e) {
      print("Error checking connection: $e");
      // Default to assuming we're connected if the check fails
      setState(() {
        _isConnected = true;
      });
    }
  }

  /// Handle the registration process when submit button is pressed
  Future<void> _handleRegistration() async {
    // First check if we're connected
    if (!_isConnected) {
      await _checkConnectionStatus();
      if (!_isConnected) {
        setState(() {
          _errorMessage =
              "Cannot register while offline. Please check your internet connection.";
        });
        return;
      }
    }

    // Prevent multiple submission attempts
    if (_registrationAttemptInProgress) {
      debugPrint("Registration already in progress, ignoring duplicate tap");
      return;
    }

    // Validate form and password
    if (!formkey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Please fix the errors in the form.";
      });
      return;
    }

    // Extra validation for Firebase's password requirements
    if (password.text.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters.";
      });
      return;
    }

    if (!_isPasswordValid) {
      setState(() {
        _errorMessage = "Password does not meet the requirements.";
      });
      return;
    }

    if (password.text != confirmPassword.text) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      return;
    }

    if (!_termsAccepted) {
      setState(() {
        _errorMessage = "You must accept the Terms and Conditions.";
      });
      return;
    }

    // Set loading state and clear any previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _registrationAttemptInProgress = true;
    });

    try {
      final normalizedEmail = email.text.trim().toLowerCase();
      final normalizedName = name.text.trim();
      final normalizedPhone = phoneNumber.text.trim();

      // Use our new registration method that properly handles PigeonUserDetails error
      final result = await _registrationService.register(
        normalizedEmail,
        normalizedName,
        normalizedPhone,
        password.text,
      );

      debugPrint("Registration result: $result");

      // Check for different response types
      if (result['success'] == true) {
        // Successful registration
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _errorMessage = null;
          _registrationAttemptInProgress = false;
        });

        // Show success message before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Short delay before navigating to login screen
        Timer(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        });
      } else if (result['error'] == 'email-already-in-use') {
        // Email already in use error
        setState(() {
          _isLoading = false;
          _errorMessage =
              "This email is already registered. Please use a different email or try logging in.";
          _registrationAttemptInProgress = false;
        });
      } else if (result['error'] == 'network-request-failed') {
        // Network error
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Network connection issue. Please check your internet connection and try again.";
          _registrationAttemptInProgress = false;
        });
      } else {
        // Other errors
        setState(() {
          _isLoading = false;
          _errorMessage =
              result['message'] ?? "Registration failed. Please try again.";
          _registrationAttemptInProgress = false;
        });
      }
    } catch (e) {
      debugPrint("Exception during registration: $e");

      setState(() {
        _isLoading = false;
        _registrationAttemptInProgress = false;

        // Determine the appropriate error message
        if (e.toString().contains("PigeonUserDetails") ||
            e.toString().contains("List<Object?>") ||
            e.toString().contains("is not a subtype")) {
          // Check if we need to verify if account was created despite error
          _errorMessage =
              "There was a technical issue during registration. Please try logging in with your email and password before trying again.";
        } else if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              _errorMessage =
                  "This email is already registered. Please use a different email or try logging in.";
              break;
            case 'invalid-email':
              _errorMessage = "The email address is not valid.";
              break;
            case 'weak-password':
              _errorMessage = "The password provided is too weak.";
              break;
            case 'network-request-failed':
              _errorMessage =
                  "Network connection issue. Please check your internet connection and try again.";
              break;
            default:
              _errorMessage = "Registration error: ${e.message}";
          }
        } else {
          // Generic error handling
          _errorMessage = "Registration failed: ${e.toString()}";
        }
      });
    }
  }

  // -----------------------
  // UI BUILDING METHODS
  // -----------------------

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8A2387),
              Color(0xFFE94057),
              Color(0xFFF27121),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: formkey,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildRegistrationForm(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section with title
  Widget _buildHeader() {
    return Container(
      alignment: Alignment.center,
      height: height * .2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8A2387),
            Color(0xFFE94057),
            Color(0xFFF27121),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      child: const Text(
        'Sign Up',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.black,
              offset: Offset(2.0, 2.0),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main registration form container
  Widget _buildRegistrationForm() {
    // Get current brightness to determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF212121)
            : Colors.white, // Dark gray in dark mode
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Display error message in a nicer container if one exists
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            ),
          ],

          if (_isSuccess) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Registration successful! Redirecting to login...",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],

          ..._buildInputFields(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 20),
          _buildSignInText(),

          // Add emergency call section
          const SizedBox(height: 20),
          const Divider(
            height: 30,
            thickness: 1,
            indent: 30,
            endIndent: 30,
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF333333) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emergency,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency? Call',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle emergency call
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "1122",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds all the form input fields
  List<Widget> _buildInputFields() {
    // Get current brightness to determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define theme colors for text fields - improved for dark mode
    final inputBorderColor = isDarkMode
        ? const Color(0xFFE94057).withOpacity(0.7)
        : const Color(0xFFE94057).withOpacity(0.4);
    final focusedBorderColor = const Color(0xFFE94057);
    final hintTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[450];
    final iconColor =
        isDarkMode ? const Color(0xFFE94057) : const Color(0xFFE94057);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    // Better contrast in dark mode with darker background
    final fillColor = isDarkMode
        ? const Color(0xFF303030) // Darker background for dark theme
        : Colors.grey[200]; // Light gray for light theme

    final inputDecoration = (String hint, IconData icon) => InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: iconColor),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: hintTextColor,
            fontWeight: FontWeight.w500,
          ),
          fillColor: fillColor,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: inputBorderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
          ),
        );

    return [
      TextFormField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(color: textColor),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email is required';
          }
          if (!email_validator.EmailValidator.validate(value.trim())) {
            return 'Please enter a valid email';
          }
          return null;
        },
        decoration: inputDecoration("Email", Icons.email),
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: password,
        obscureText: _isObscure,
        focusNode: _passwordFocusNode,
        style: TextStyle(color: textColor),
        onChanged: (value) {
          // Mark that password validation has been initiated
          setState(() {
            _passwordValidationInitiated = true;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }

          // Additional check to ensure password validation has been performed
          if (!_passwordValidationInitiated) {
            return 'Please wait for password validation to complete';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, size: 20, color: iconColor),
          suffixIcon: IconButton(
            icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off,
                color: iconColor),
            onPressed: () {
              setState(() {
                _isObscure = !_isObscure;
              });
            },
          ),
          hintText: "Password",
          hintStyle: TextStyle(
            fontSize: 15,
            color: hintTextColor,
            fontWeight: FontWeight.w500,
          ),
          fillColor: fillColor,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: inputBorderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
          ),
        ),
      ),
      const SizedBox(height: 10),
      FlutterPwValidator(
        controller: password,
        minLength: 6, // Changed from 8 to 6 to match Firebase requirements
        uppercaseCharCount: 1,
        numericCharCount: 1,
        specialCharCount: 1,
        width: 400,
        height: 150,
        onSuccess: () {
          setState(() {
            _isPasswordValid = true;
            _passwordValidationInitiated = true;
          });
        },
        onFail: () {
          setState(() {
            _isPasswordValid = false;
            _passwordValidationInitiated = true;
          });
        },
      ),
      const SizedBox(height: 15),
      // Confirm Password Field
      TextFormField(
        controller: confirmPassword,
        obscureText: _isConfirmPasswordObscure,
        focusNode: _confirmPasswordFocusNode,
        style: TextStyle(color: textColor),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != password.text) {
            return 'Passwords do not match';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline, size: 20, color: iconColor),
          suffixIcon: IconButton(
            icon: Icon(
                _isConfirmPasswordObscure
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: iconColor),
            onPressed: () {
              setState(() {
                _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
              });
            },
          ),
          hintText: "Confirm Password",
          hintStyle: TextStyle(
            fontSize: 15,
            color: hintTextColor,
            fontWeight: FontWeight.w500,
          ),
          fillColor: fillColor,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: inputBorderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
          ),
        ),
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: name,
        style: TextStyle(color: textColor),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Name is required';
          }
          return null;
        },
        decoration: inputDecoration("Name", Icons.person),
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: phoneNumber,
        keyboardType: TextInputType.phone,
        style: TextStyle(color: textColor),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Phone number is required';
          }

          // More comprehensive phone validation
          // Allows for international formats with country codes, spaces, dashes, and parentheses
          final cleanedNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleanedNumber)) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
        decoration: inputDecoration(
            "Phone Number (e.g. +1 234 567 8900)", Icons.phone_iphone_rounded),
      ),
      const SizedBox(height: 15),
      // Terms and Conditions Checkbox
      Row(
        children: [
          Checkbox(
            value: _termsAccepted,
            fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFFE94057);
              }
              return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
          ),
          Expanded(
            child: Text(
              "I accept the Terms and Conditions",
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// Builds the submit button
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94057),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Register",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Builds the sign-in text with link to login page
  Widget _buildSignInText() {
    return RichText(
      text: TextSpan(
        text: "Already have an account?",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: Colors.black,
        ),
        children: <TextSpan>[
          TextSpan(
            text: " Sign In!",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE94057),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
          ),
        ],
      ),
    );
  }
}
