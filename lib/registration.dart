import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_project/login_screen.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
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
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  void onClickFun(RoundedLoadingButtonController btnController) async {
    Timer(const Duration(seconds: 3), () {
      _btnController.success();
    });
  }

  void onClickFun2(RoundedLoadingButtonController btnController) async {
    Timer(const Duration(seconds: 2), () {
      _btnController.error();
      Future.delayed(const Duration(seconds: 1));
      _btnController.reset();
    });
  }

  bool _isObscure = true;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  double height = 0, width = 0;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: formkey,
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: height * .15,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 190, 82, 15),
                          Color.fromARGB(188, 255, 140, 0),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100),
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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Container(
                      height: height * .7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 190.0, left: 40),
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.027,
                  ),
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: PhysicalModel(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    child: TextFormField(
                      controller: email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email Required';
                        } else {
                          RegExp regExp = RegExp(
                            r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                            caseSensitive: false,
                            multiLine: false,
                          );

                          if (!regExp.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.email,
                          size: 20,
                        ),
                        hintText: "Email",
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[450],
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              width: 0.15, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 280.0, left: 40),
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.015,
                  ),
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: PhysicalModel(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    child: TextFormField(
                      obscureText: _isObscure,
                      controller: password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password required';
                        } else {
                          RegExp regExp = RegExp(
                            r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$",
                            caseSensitive: false,
                            multiLine: false,
                          );
                          if (!regExp.hasMatch(value)) {
                            return 'Please enter a valid password';
                          }
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock,
                          size: 20,
                        ),
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
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 352.0, left: 40),
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.027,
                  ),
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: PhysicalModel(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    child: TextFormField(
                      controller: name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name required';
                        } else {
                          RegExp regExp = RegExp(
                            r"^[A-Za-z\s]*$",
                            caseSensitive: false,
                            multiLine: false,
                          );
                          if (!regExp.hasMatch(value)) {
                            return 'Please enter a valid name';
                          }
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                          size: 20,
                        ),
                        hintText: "Name",
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[450],
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              width: 0.15, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 430.0, left: 40),
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.027,
                  ),
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: PhysicalModel(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    child: TextFormField(
                      controller: phoneNumber,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number required';
                        } else {
                          RegExp regExp = RegExp(
                            r"^[0-9]{11}$",
                            caseSensitive: false,
                            multiLine: false,
                          );
                          if (!regExp.hasMatch(value)) {
                            return 'Please enter a valid phone number';
                          }
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.phone_iphone_rounded,
                          size: 20,
                        ),
                        hintText: "Phone Number",
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[450],
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              width: 0.15, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 530.0),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: 50,
                    child: PhysicalModel(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      child: RoundedLoadingButton(
                        onPressed: () async {
                          var object1 = Flutter_api();
                          if (formkey.currentState!.validate()) {
                            if (await object1.register(email.text, name.text,
                                    phoneNumber.text, password.text) ==
                                true) {
                              onClickFun(_btnController);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Login()),
                              );
                            } else {
                              onClickFun2(_btnController);
                            }
                          }
                        },
                        controller: _btnController,
                        color: Color.fromARGB(188, 255, 140, 0),
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 600.0, left: 20),
                child: Container(
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account?",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: " SignIn!",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Color.fromRGBO(221, 125, 15, 1),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Login()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
