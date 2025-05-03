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

import 'firebase_database.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  var email = TextEditingController();
  var name = TextEditingController();
  var phoneNumber = TextEditingController();
  var password = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  bool _isConnected = true;

  bool _isObscure = true;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordValid = false;
  double height = 0, width = 0;

  // Create an instance of our Firebase API wrapper
  final _firebaseApi = Flutter_api();

  @override
  void initState() {
    super.initState();
    // Check Firebase connection status
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    try {
      // Use the public connectivity check method from our API
      bool isConnected = await _firebaseApi.checkInternetConnectivity();
      setState(() {
        _isConnected = isConnected;
        if (!isConnected) {
          _errorMessage = "No internet connection. Please check your network settings.";
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

  @override
  void dispose() {
    // Clean up all controllers when the widget is disposed
    email.dispose();
    name.dispose();
    phoneNumber.dispose();
    password.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    // First check if we're connected
    if (!_isConnected) {
      await _checkConnectionStatus();
      if (!_isConnected) {
        setState(() {
          _errorMessage = "Cannot register while offline. Please check your internet connection.";
        });
        return;
      }
    }
    
    if (formkey.currentState!.validate() && _isPasswordValid) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print("Starting registration with: Email=${email.text.trim()}, Name=${name.text.trim()}, Phone=${phoneNumber.text.trim()}");
      try {
        // Check if email is already registered before attempting registration
        try {
          final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email.text.trim());
          if (methods.isNotEmpty) {
            // Email already exists, show error and don't attempt registration
            setState(() {
              _isLoading = false;
              _errorMessage = "This email is already registered. Please use a different email or try logging in.";
            });
            return;
          }
        } catch (e) {
          // If there's an error checking email existence, continue with registration attempt
          print("Error checking email existence: $e");
        }

        // Attempt to register with Firebase
        bool registrationSuccess = await _firebaseApi.register(
          email.text.trim(),
          name.text.trim(),
          phoneNumber.text.trim(),
          password.text,
        );

        print("Registration result: $registrationSuccess");

        if (registrationSuccess) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
            _errorMessage = null;
          });

          // Show success message before navigating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );

          // Short delay before navigating to login screen
          Timer(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = "Registration failed. Email may already be in use.";
          });
        }
      } catch (e) {
        print("Registration exception caught: ${e.toString()}");
        setState(() {
          _isLoading = false;
          
          // More specific error handling
          if (e.toString().contains('email-already-in-use')) {
            _errorMessage = "This email is already registered. Please use a different email or try logging in.";
          } else if (e.toString().contains('network-request-failed') || 
              e.toString().contains('connection') ||
              e.toString().contains('timeout')) {
            _errorMessage = "Network connection issue. Please check your internet connection and try again.";
          } else if (e.toString().contains('recaptcha')) {
            _errorMessage = "Google verification service is temporarily unavailable. Please try again in a moment.";
          } else if (e.toString().contains('invalid-email')) {
            _errorMessage = "The email address is not valid.";
          } else if (e.toString().contains('weak-password')) {
            _errorMessage = "The password provided is too weak.";
          } else if (e.toString().contains('verify user data')) {
            // Handle data verification failures
            _errorMessage = "Registration completed but there was an issue verifying your data. Please try logging in.";
          } else if (e.toString().contains('Firestore')) {
            // Handle Firestore specific errors
            _errorMessage = "There was an issue saving your account data. Please try again or contact support.";
          } else if (e.toString().contains('PigeonUserDetails')) {
            _errorMessage = "This email may already be registered. Please try a different email or log in.";
          } else {
            _errorMessage = "Registration error: ${e.toString().replaceAll(RegExp(r'Exception: '), '')}";
          }
        });
        print("Registration error: $e");
      }
    } else {
      setState(() {
        _errorMessage = "Please fix the errors in the form.";
      });
    }
  }

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
                Container(
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
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ..._buildInputFields(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_isSuccess) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "Registration successful! Redirecting to login...",
                          style: TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      _buildSignInText(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInputFields() {
    return [
      TextFormField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email is required';
          }
          if (!email_validator.EmailValidator.validate(value.trim())) {
            return 'Please enter a valid email';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.email, size: 20),
          hintText: "Email",
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey[450],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: password,
        obscureText: _isObscure,
        focusNode: _passwordFocusNode,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          if (value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _isObscure = !_isObscure;
              });
            },
          ),
          hintText: "Password",
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey[450],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      const SizedBox(height: 10),
      FlutterPwValidator(
        controller: password,
        minLength: 8,
        uppercaseCharCount: 1,
        numericCharCount: 1,
        specialCharCount: 1,
        width: 400,
        height: 150,
        onSuccess: () {
          setState(() {
            _isPasswordValid = true;
          });
        },
        onFail: () {
          setState(() {
            _isPasswordValid = false;
          });
        },
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: name,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Name is required';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person, size: 20),
          hintText: "Name",
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey[450],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: phoneNumber,
        keyboardType: TextInputType.phone,
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
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
          hintText: "Phone Number (e.g. +1 234 567 8900)",
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey[450],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    ];
  }

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
