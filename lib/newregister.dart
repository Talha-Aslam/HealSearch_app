import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healsearch_app/customTextField.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final EmailController = TextEditingController();
  final passController = TextEditingController();
  final pass2controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  
  // Form validation errors
  Map<String, String?> _errors = {
    'fname': null,
    'lname': null,
    'email': null,
    'password': null,
    'password2': null,
  };
  
  // Field touched state to prevent showing errors before user interaction
  Map<String, bool> _touched = {
    'fname': false,
    'lname': false,
    'email': false,
    'password': false,
    'password2': false,
  };
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Add listeners for real-time validation
    fnameController.addListener(() => _validateField('fname'));
    lnameController.addListener(() => _validateField('lname'));
    EmailController.addListener(() => _validateField('email'));
    passController.addListener(() {
      _validateField('password');
      if (_touched['password2']!) {
        _validateField('password2'); // Revalidate confirmation if changed
      }
    });
    pass2controller.addListener(() => _validateField('password2'));
  }

  // Validate individual fields
  void _validateField(String field) {
    if (!_touched[field]!) return;
    
    setState(() {
      switch (field) {
        case 'fname':
          _errors[field] = fnameController.text.trim().isEmpty
              ? "First name is required"
              : null;
          break;
        case 'lname':
          _errors[field] = lnameController.text.trim().isEmpty
              ? "Last name is required"
              : null;
          break;
        case 'email':
          final email = EmailController.text.trim();
          _errors[field] = email.isEmpty
              ? "Email is required"
              : !_validateEmail(email)
                  ? "Please enter a valid email address"
                  : null;
          break;
        case 'password':
          final password = passController.text;
          if (password.isEmpty) {
            _errors[field] = "Password is required";
          } else if (password.length < 8) {
            _errors[field] = "Password must be at least 8 characters";
          } else if (!password.contains(RegExp(r'[A-Z]'))) {
            _errors[field] = "Password must contain at least one uppercase letter";
          } else if (!password.contains(RegExp(r'[0-9]'))) {
            _errors[field] = "Password must contain at least one number";
          } else {
            _errors[field] = null;
          }
          break;
        case 'password2':
          final password = passController.text;
          final confirmation = pass2controller.text;
          _errors[field] = confirmation.isEmpty
              ? "Please confirm your password"
              : confirmation != password
                  ? "Passwords don't match"
                  : null;
          break;
      }
    });
  }

  // Mark a field as touched when user interacts with it
  void _setTouched(String field) {
    if (!_touched[field]!) {
      setState(() {
        _touched[field] = true;
      });
      _validateField(field);
    }
  }

  // Check if form is valid
  bool _isFormValid() {
    // Mark all fields as touched to show all errors
    for (var field in _touched.keys) {
      _touched[field] = true;
    }
    
    // Validate all fields
    for (var field in _errors.keys) {
      _validateField(field);
    }
    
    // Check if any errors exist
    return !_errors.values.any((error) => error != null);
  }

  // Validate password requirements
  bool _validatePassword(String password) {
    // At least 8 characters, 1 uppercase, 1 number
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
  
  // Validate email format
  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Save user data to Firestore
  Future<void> SaveUserdata() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !mounted) {
        throw Exception("User not authenticated");
      }
      
      await FirebaseFirestore.instance
        .collection("Users")
        .doc(EmailController.text.trim())
        .set({
          "Name": "${fnameController.text.trim()} ${lnameController.text.trim()}",
          "Email": EmailController.text.trim(),
          "Phone": "",
          "Gender": "Male",
          "CreatedAt": FieldValue.serverTimestamp(),
        })
        .timeout(
          Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException("Database operation timed out");
          },
        );
    } on FirebaseException catch (e) {
      print("Firebase error: ${e.code}, ${e.message}");
      throw Exception("Database error: ${e.message}");
    } on TimeoutException catch (_) {
      throw Exception("Connection timed out. Please check your internet connection.");
    } catch (e) {
      print("Error saving user data: $e");
      throw Exception("Failed to save user data: $e");
    }
  }

  // Create new user with Firebase Auth
  Future<bool> CreateUser() async {
    if (!_isFormValid()) {
      return false;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create the user account with error handling
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: EmailController.text.trim(),
              password: passController.text.trim())
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw FirebaseAuthException(
                code: 'timeout',
                message: 'Connection timed out. Please check your internet connection.',
              );
            },
          );
              
      return userCredential != null;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = "This email is already registered";
          break;
        case 'weak-password':
          message = "Please use a stronger password";
          break;
        case 'invalid-email':
          message = "Invalid email format";
          break;
        case 'network-request-failed':
          message = "Network error. Please check your connection";
          break;
        case 'operation-not-allowed':
          message = "Email/password accounts are not enabled";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later";
          break;
        case 'timeout':
          message = e.message ?? "Connection timed out. Please try again.";
          break;
        default:
          message = e.message ?? "Failed to create account";
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
      return false;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred";
        });
      }
      print("Error creating user: $e");
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  var is_checked = false;
  
  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    EmailController.dispose();
    passController.dispose();
    pass2controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _animationController.drive(
                  CurveTween(curve: Curves.easeInOut),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo and App Name
                    Hero(
                      tag: 'app_logo',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/images/logo_main.png',
                              height: 36,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Life Saver',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D3E88),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    // Heading
                    const Text(
                      'Join Us',
                      style: TextStyle(
                        color: Color(0xFF1D3E88),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    Text(
                      'Sign up to get help when you need it most',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Display global error message if any
                    if (_errorMessage != null)
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
                      
                    // Form fields
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField2(
                            controller: fnameController,
                            name: "First Name",
                            inputType: TextInputType.text,
                            obscureText: false,
                            prefixIcon: Icons.person_outline,
                            errorText: _errors['fname'],
                            onChanged: (_) => _setTouched('fname'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField2(
                            controller: lnameController,
                            name: "Last Name",
                            inputType: TextInputType.text,
                            obscureText: false,
                            prefixIcon: Icons.person_outline,
                            errorText: _errors['lname'],
                            onChanged: (_) => _setTouched('lname'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    CustomTextField2(
                      controller: EmailController,
                      name: "Email",
                      inputType: TextInputType.emailAddress,
                      obscureText: false,
                      prefixIcon: Icons.email_outlined,
                      errorText: _errors['email'],
                      onChanged: (_) => _setTouched('email'),
                    ),
                    
                    const SizedBox(height: 8),
                    CustomTextField2(
                      controller: passController,
                      name: "Password",
                      inputType: TextInputType.text,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      errorText: _errors['password'],
                      onChanged: (_) => _setTouched('password'),
                    ),
                    
                    const SizedBox(height: 8),
                    CustomTextField2(
                      controller: pass2controller,
                      name: "Confirm Password",
                      inputType: TextInputType.text,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      errorText: _errors['password2'],
                      onChanged: (_) => _setTouched('password2'),
                    ),
                    
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: is_checked,
                          fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.red;
                            }
                            return Colors.grey.shade400;
                          }),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              is_checked = value ?? false;
                              if (!is_checked) {
                                _errorMessage = null;
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading 
                          ? null 
                          : () async {
                              // Clear the global error message
                              setState(() {
                                _errorMessage = null;
                              });
                              
                              // Check terms agreement
                              if (!is_checked) {
                                setState(() {
                                  _errorMessage = "Please agree to Terms and Conditions";
                                });
                                return;
                              }
                              
                              // Create user account
                              if (await CreateUser()) {
                                try {
                                  await SaveUserdata();
                                  
                                  // Show success and navigate to dashboard
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account created successfully!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  
                                  // Navigator.pushReplacement(
                                  //   context, 
                                  //   MaterialPageRoute(builder: (context) => Dashboard()),
                                  // );
                                } catch (e) {
                                  setState(() {
                                    _errorMessage = e.toString();
                                  });
                                }
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red.withOpacity(0.5),
                          elevation: 2,
                          shadowColor: Colors.red.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            'Sign in Here',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Emergency call section
                    const Divider(
                      height: 30,
                      thickness: 1,
                      indent: 30,
                      endIndent: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
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
                              color: Colors.grey[700],
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
