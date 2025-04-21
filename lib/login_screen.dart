import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:my_project/registration.dart';
import 'package:my_project/search_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool _isObscure = true;
  var email = TextEditingController();
  var password = TextEditingController();
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  double height = 0, width = 0;

  void onClickFun(RoundedLoadingButtonController btnController) async {
    Timer(const Duration(seconds: 3), () {
      _btnController.success();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Search()));
    });
  }

  void onClickFun2(RoundedLoadingButtonController btnController) async {
    Timer(const Duration(seconds: 2), () {
      _btnController.error();
      Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
                    Text(
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
                    SizedBox(height: 10),
                    Text(
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formkey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: email,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: MultiValidator([
                        RequiredValidator(errorText: "Required *"),
                        EmailValidator(errorText: "Not a valid email"),
                      ]).call,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
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
                      validator:
                          RequiredValidator(errorText: "Required *").call,
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Implement forgot password functionality
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.deepOrangeAccent,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    RoundedLoadingButton(
                      controller: _btnController,
                      onPressed: () => onClickFun(_btnController),
                      color: Color(0xFFE94057),
                      child:
                          Text('Login', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 7),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
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
                                color: Colors.deepOrangeAccent,
                              ),
                            ),
                          ), // Add spacing between text and button
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    Center(
                      child: Text(
                        'Or login with',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.g_mobiledata,
                            size: 50,
                          ),
                          color: Colors.red,
                          onPressed: () {
                            // Implement Google login
                          },
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(
                            Icons.facebook_outlined,
                            size: 40,
                          ),
                          color: Colors.blue,
                          onPressed: () {
                            // Implement Facebook login
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Search()));
                      },
                      child: Text('Continue as Guest',
                          style: TextStyle(
                              color: Color.fromARGB(255, 190, 82, 15))),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
