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
    // Placeholder for Google Sign-In implementation
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In is not configured yet")));
  }

  Future<void> _handleFacebookSignIn() async {
    // Placeholder for Facebook Sign-In implementation
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Facebook Sign-In is not configured yet")));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions only once per build
    final mediaQuery = MediaQuery.of(context);
    height = mediaQuery.size.height;
    width = mediaQuery.size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensures keyboard doesn't cause overflow
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: mediaQuery.size.height -
                  mediaQuery.padding.top -
                  mediaQuery.padding.bottom,
            ),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
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
                        _buildGuestLoginButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Extracted widget methods for better readability and performance
  Widget _buildHeader() {
    return Container(
      height: height * 0.3,
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
              'Welcome to Search a Holic',
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
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email, AutofillHints.username],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94057), width: 2),
        ),
      ),
      validator: _emailValidator.call,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _isObscure,
      autocorrect: false,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) => onClickLogin(),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94057), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
      ),
      validator: _passwordValidator.call,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, null);
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _isLoading = true;
                });
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: resetEmailController.text.trim(),
                  );
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                  Navigator.pop(context, 'success');
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                  Navigator.pop(
                      context,
                      e.toString().contains('user-not-found')
                          ? 'user-not-found'
                          : 'error');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94057),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    ).then((result) {
      if (result == 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (result == 'user-not-found' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No account found with this email'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (result == 'error' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending reset email. Please try again.'),
            backgroundColor: Colors.red,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use IconButton with minimized rebuilds
            IconButton(
              icon: const Icon(
                Icons.g_mobiledata,
                size: 50,
                color: Colors.red,
              ),
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(
                Icons.facebook_outlined,
                size: 40,
                color: Colors.blue,
              ),
              onPressed: _handleFacebookSignIn,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestLoginButton() {
    return TextButton(
      onPressed: () {
        // Let users know they're in guest mode with limited access
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Guest mode: Some features like profile will require login'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Search()));
      },
      child: const Text(
        'Continue as Guest',
        style: TextStyle(color: Color.fromARGB(255, 190, 82, 15)),
      ),
    );
  }
}
