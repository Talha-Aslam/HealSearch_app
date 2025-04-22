//import 'package:fluent_ui/fluent_ui.dart';

import 'package:firedart/firestore/firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_project/data.dart';
import 'package:my_project/login_screen.dart';
import 'package:firedart/firedart.dart';
import 'package:my_project/showProfile.dart';
import 'package:my_project/updateProfile.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  double height = 0, width = 0;
  // ignore: non_constant_identifier_names
  dynamic Name;
  // ignore: non_constant_identifier_names
  dynamic Email;
  // ignore: non_constant_identifier_names
  dynamic Phone_number;

  Future getprofile() async {
    // Getting Documents from Firestore
    if (appData.Email != "You are not logged in") {
      var data = Firestore.instance.collection("appData");
      var data1 = data.document(appData.Email);
      var data2 = await data1.get();

      setState(() {
        Name = data2['name'];
        Email = data2['email'];
        Phone_number = data2['phNo'];

        //password = data2['password'];
      });
    }
  }

  @override
// Update State
  void initState() {
    getprofile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: appData.isLoggedIn
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: height * .31,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFE94057),
                            Color(0xFFF27121),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50))),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 27),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Icon(Icons.arrow_back_ios_new_sharp,
                                    size: 25, color: Colors.white)),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 10.0),
                            child: Text(
                              'My Profile',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28),
                            ),
                          ),
                          const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Icon(Icons.more_horiz,
                                  size: 25, color: Colors.transparent)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircleAvatar(
                      maxRadius: 50,
                      minRadius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage("images/man.png"),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Text(
                      Name ?? 'Talha Aslam',
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ShowProfile()),
                            );
                          },
                          icon: const Icon(Icons.person, color: Colors.white),
                          label: const Text('Show Profile'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromARGB(255, 190, 82, 15),
                            textStyle: const TextStyle(fontSize: 16),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const UpdateProfile()),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text('Update Profile'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromARGB(188, 255, 140, 0),
                            textStyle: const TextStyle(fontSize: 16),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Delete Profile"),
                                  content: const Text(
                                      "Are you sure you want to delete your profile?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("Yes"),
                                      onPressed: () async {
                                        // Add your delete profile functionality here
                                        if (appData.Email !=
                                            "You are not logged in") {
                                          var data = Firestore.instance
                                              .collection("appData");
                                          await data
                                              .document(appData.Email)
                                              .delete();
                                          setState(() {
                                            appData.isLoggedIn = false;
                                            appData.Email =
                                                "You are not logged in";
                                          });
                                        }
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text('Delete Profile'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            textStyle: const TextStyle(fontSize: 16),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FloatingActionButton.extended(
                    icon: const Icon(Icons.logout_outlined),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    label: const Text("Logout"),
                    onPressed: () {
                      setState(() {
                        appData.isLoggedIn = false;
                        appData.Email = "You are not logged in";
                      });
                    },
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom))
                ],
              ),
            )
          : Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Padding(
                      padding: EdgeInsets.only(top: 60.0, right: 260),
                      child: Icon(Icons.arrow_back_ios_new_sharp,
                          size: 25, color: Colors.black)),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 300.0, left: 50),
                  child: Text(
                    'You are not logged in! Please Log In to Continue',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 80),
                  child: ElevatedButton(
                    child: const Text('Login'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
