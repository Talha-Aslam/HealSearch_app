import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/firebase_database.dart' as firebase_db;
import 'package:healsearch_app/registration.dart';
import 'package:healsearch_app/search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool _isObscure = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  double height = 0, width = 0;
  // Create an instance of our Firebase API wrapper
  final _firebaseApi = firebase_db.Flutter_api();
  String? _errorMessage;

  // Cache form validators to avoid rebuilding them
  final _emailValidator = MultiValidator([
    RequiredValidator(errorText: "Required *"),
    EmailValidator(errorText: "Not a valid email"),
  ]);
  final _passwordValidator = RequiredValidator(errorText: "Required *");

  get userData => null;

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> onClickLogin() async {
    // Validate early and return if invalid
    if (!formkey.currentState!.validate()) return;

    // Show loading indicator
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check connectivity to provide better error message
      final isConnected = await _firebaseApi.checkInternetConnectivity();
      if (!mounted) return;
      if (!isConnected && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "No internet connection. Please check your network and try again.";
        });
        return;
      }

      // Use our improved login method
      bool loginSuccess = await _firebaseApi.check_login(
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;

      // If we're not mounted anymore, don't continue
      if (!mounted) return;

      if (loginSuccess) {
        try {
          // Use our improved API to fetch user data with caching
          final userData = await _firebaseApi.getUserData();
          if (!mounted) return;

          if (userData != null) {
            // Get phone number from either field for maximum compatibility
            final String phoneNum =
                userData['phoneNumber'] ?? userData['phNo'] ?? "";

            // Set user data in our global AppData object
            appData.setUserData(
              _email.text.trim(),
              userData['name'] ?? "User",
              phoneNum,
              userData['profileImage'],
            );

            // Save login session to stay logged in (using secure storage would be better)
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userData['uid'])
                  .update({
                'lastLogin': FieldValue.serverTimestamp(),
                'lastLoginDevice': Platform.isIOS ? 'ios' : 'android',
              });
              if (!mounted) return;
            } catch (e) {
              // Ignore errors updating last login time
              debugPrint("Failed to update last login time: $e");
            }
          } else {
            // If we couldn't get user data, set minimal information
            appData.setUserData(
              _email.text.trim(),
              "User",
              "",
              userData?['profileImage'],
            );
          }

          // Only update state if still mounted
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Use pushAndRemoveUntil for more efficient navigation
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Search()),
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            debugPrint("Error fetching user data: $e");

            // Handle PigeonUserDetails type casting error specifically
            if (e.toString().contains('PigeonUserDetails')) {
              // Set minimal user information when facing the PigeonUserDetails error
              appData.setUserData(
                _email.text.trim(),
                "User",
                "",
                userData?['profileImage'],
              );

              setState(() {
                _isLoading = false;
              });

              // Navigate to search screen despite the error
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
                (route) => false,
              );
              return;
            }

            // Still navigate to search screen even if we couldn't fetch complete profile data
            // This prevents login issues due to profile data access problems
            setState(() {
              _isLoading = false;
            });

            // Show a brief message about the issue
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Signed in, but there was an issue loading your profile"),
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Search()),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Invalid email or password. Please try again.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Login error: $e");
        setState(() {
          _isLoading = false;

          // More specific error message based on error type
          if (e.toString().contains('PigeonUserDetails')) {
            _errorMessage =
                "Authentication succeeded but there was an issue with user data. Please try again.";
          } else if (e.toString().contains('network')) {
            _errorMessage =
                "Network error. Please check your internet connection and try again.";
          } else if (e.toString().contains('password')) {
            _errorMessage = "Incorrect password. Please try again.";
          } else if (e.toString().contains('invalid-credential')) {
            _errorMessage =
                "Invalid login credentials. Please check your email and password.";
          } else if (e.toString().contains('user-not-found') ||
              e.toString().contains('user not found')) {
            _errorMessage =
                "User not found. Please check your email or register a new account.";
          } else if (e.toString().contains('RecaptchaCallWrapper')) {
            _errorMessage =
                "Security verification failed. Please try again in a few moments.";
          } else if (e.toString().contains('too-many-requests')) {
            _errorMessage =
                "Too many login attempts. Please try again later or reset your password.";
          } else {
            _errorMessage =
                "Error connecting to the server. Please try again later.";
          }
        });
      }
    }
  }

  // Simplified social sign-in methods with error handling
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check connectivity first
      final isConnected = await _firebaseApi.checkInternetConnectivity();
      if (!mounted) return;

      if (!isConnected) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "No internet connection. Please check your network and try again.";
        });
        return;
      }

      // Use our Google Sign-In method from the Firebase API - now returns Map instead of UserCredential
      final userData = await _firebaseApi.signInWithGoogle();

      // If we're not mounted anymore, don't continue
      if (!mounted) return;

      // If user cancelled sign-in or sign-in failed
      if (userData == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // User successfully signed in with Google
      if (userData['success'] == true) {
        // Get user information from the returned userData map
        final String email = userData['email'] ?? "";
        final String name = userData['name'] ?? "User";
        final String phoneNum = userData['phoneNumber'] ?? "";

        // Set user data in our global AppData object
        appData.setUserData(email, name, phoneNum, userData['profileImage']);

        // Navigate to search screen
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Search()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Failed to sign in with Google. Please try again.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is FirebaseAuthException) {
            _errorMessage =
                e.message ?? "Google Sign-In failed. Please try again.";
          } else {
            _errorMessage = "Google Sign-In failed. Please try again.";
          }
        });
        debugPrint("Google Sign-In error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions only once per build
    final mediaQuery = MediaQuery.of(context);
    height = mediaQuery.size.height;
    width = mediaQuery.size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensures keyboard doesn't cause overflow
      // Remove the SafeArea from here and handle it properly in the body
      body: Column(
        children: [
          // Header container with gradient that properly accounts for status bar
          Container(
            height: height * 0.3,
            padding: EdgeInsets.only(
                top: mediaQuery.padding.top), // Add padding for status bar
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8A2387),
                  Color(0xFFE94057),
                  Color(0xFFF27121),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to HealSearch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: formkey,
                  child: Column(
                    children: [
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.red),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      _buildForgotPassword(),
                      const SizedBox(height: 20),
                      _buildLoginButton(),
                      const SizedBox(height: 7),
                      _buildSignUpSection(),
                      const SizedBox(height: 18),
                      _buildSocialLoginSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return _buildInputField(
      context,
      _email,
      'Email',
      Icons.email,
      false,
      _emailValidator.call,
    );
  }

  Widget _buildPasswordField() {
    return _buildInputField(
      context,
      _password,
      'Password',
      Icons.lock,
      true,
      _passwordValidator.call,
    );
  }

  Widget _buildInputField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPassword,
    String? Function(String?)? validator,
  ) {
    // Get current brightness to determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define theme colors for text fields to match registration screen with better contrast
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: textColor),
        obscureText: isPassword ? _isObscure : false,
        validator: validator,
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
          hintText: label,
          hintStyle: TextStyle(color: hintTextColor),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          _showForgotPasswordDialog();
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color.fromARGB(255, 238, 24, 52),
          ),
        ),
      ),
    );
  }

  // Add this new method for password reset functionality
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_reset,
                color: const Color(0xFFE94057),
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your registered email',
                      prefixIcon: Icon(Icons.email, color: Color(0xFFE94057)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE94057), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.trim().contains('@') ||
                          !value.trim().contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE94057)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sending reset link...',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, null);
                      }
                    },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isLoading ? Colors.grey : Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isLoading = true;
                        });
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: resetEmailController.text.trim(),
                          );
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context, 'success');
                          }
                        } catch (e) {
                          // Wait a bit to show loading state before closing
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                          if (mounted) {
                            Navigator.pop(
                                context,
                                e.toString().contains('user-not-found')
                                    ? 'user-not-found'
                                    : e.toString().contains('invalid-email')
                                        ? 'invalid-email'
                                        : 'error');
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94057),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                'Send Reset Link',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    ).then((result) {
      if (result == 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Password reset link sent! Please check your email inbox.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (result == 'user-not-found' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('No account found with this email address'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (result == 'invalid-email' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('The email address is not valid'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (result == 'error' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Error sending reset email. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onClickLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94057),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ))
            : const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Don\'t have an account!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Registration()));
          },
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color.fromARGB(255, 238, 24, 52),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        const Text(
          'Or login with',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                "G",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA4335), // Google red
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
