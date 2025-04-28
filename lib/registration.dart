import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:flutter/gestures.dart';

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

  bool _isObscure = true;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  double height = 0, width = 0;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        height: double
            .infinity, // Ensures the gradient covers the full screen height
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
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      _buildSignInText(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInputFields() {
    return [
      _buildTextField(email, "Email", Icons.email, false),
      const SizedBox(height: 15),
      _buildTextField(password, "Password", Icons.lock, true),
      const SizedBox(height: 15),
      _buildTextField(name, "Name", Icons.person, false),
      const SizedBox(height: 15),
      _buildTextField(
          phoneNumber, "Phone Number", Icons.phone_iphone_rounded, false),
    ];
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      IconData icon, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText required';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon:
                    Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              )
            : null,
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.grey[450],
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading 
            ? null 
            : () async {
                if (formkey.currentState!.validate()) {
                  setState(() {
                    _isLoading = true;
                  });
                  
                  var object1 = Flutter_api();
                  if (await object1.register(
                      email.text, name.text, phoneNumber.text, password.text) == true) {
                    // Simulate success state before navigating
                    Timer(const Duration(seconds: 3), () {
                      setState(() {
                        _isLoading = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    });
                  } else {
                    // Handle error state
                    Timer(const Duration(seconds: 2), () {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94057),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Submit",
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
