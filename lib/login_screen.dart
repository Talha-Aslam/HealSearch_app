import 'dart:async';

import 'package:flutter/material.dart';
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
      // Use our improved login method
      bool loginSuccess = await _firebaseApi.check_login(
        _email.text.trim(),
        _password.text,
      );
      
      // If we're not mounted anymore, don't continue
      if (!mounted) return;
      
      if (loginSuccess) {
        try {
          // Use our improved API to fetch user data with caching
          final userData = await _firebaseApi.getUserData();
          
          if (!mounted) return;
          
          if (userData != null) {
            // Set user data in our global AppData object
            appData.setUserData(
              _email.text.trim(),
              userData['name'] ?? "User",
              userData['phoneNumber'] ?? userData['phNo'] ?? "",
            );
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
                content: Text("Signed in, but there was an issue loading your profile"),
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
            _errorMessage = "Authentication succeeded but there was an issue with user data. Please try again.";
          } else if (e.toString().contains('network')) {
            _errorMessage = "Network error. Please check your internet connection and try again.";
          } else if (e.toString().contains('password')) {
            _errorMessage = "Incorrect password. Please try again.";
          } else if (e.toString().contains('user-not-found') || e.toString().contains('user not found')) {
            _errorMessage = "User not found. Please check your email or register a new account.";
          } else {
            _errorMessage = "Error connecting to the server. Please try again later.";
          }
        });
      }
    }
  }

  // Simplified social sign-in methods with error handling
  Future<void> _handleGoogleSignIn() async {
    // Placeholder for Google Sign-In implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google Sign-In is not configured yet"))
    );
  }

  Future<void> _handleFacebookSignIn() async {
    // Placeholder for Facebook Sign-In implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Facebook Sign-In is not configured yet"))
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions only once per build
    final mediaQuery = MediaQuery.of(context);
    height = mediaQuery.size.height;
    width = mediaQuery.size.width;
    
    return Scaffold(
      // Optimize scrolling performance with scrolling physics
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
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
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
      ),
      validator: _emailValidator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_isObscure
              ? Icons.visibility
              : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
      ),
      validator: _passwordValidator,
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Forgot password functionality
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
                )
              )
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
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const Registration()));
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
            content: Text('Guest mode: Some features like profile will require login'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const Search()));
      },
      child: const Text(
        'Continue as Guest',
        style: TextStyle(color: Color.fromARGB(255, 190, 82, 15)),
      ),
    );
  }
}
