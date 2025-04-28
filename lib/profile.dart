import 'package:flutter/material.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:firedart/firedart.dart';
import 'package:healsearch_app/showProfile.dart';
import 'package:healsearch_app/updateProfile.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  double height = 0, width = 0;
  String? name;
  String? email;
  String? phoneNumber;
  bool isLoading = false;
  String? errorMessage;

  Future<void> getprofile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Only fetch from Firebase if logged in
    if (appData.isLoggedIn && appData.Email != "You are not logged in") {
      try {
        var data = Firestore.instance.collection("appData");
        var data1 = data.document(appData.Email);
        var data2 = await data1.get();

        setState(() {
          name = data2['name'];
          email = data2['email'];
          phoneNumber = data2['phNo'];
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          errorMessage = "Error fetching profile data";
          isLoading = false;
        });
        print("Error fetching profile: $e");
      }
    } else {
      // Use the data from AppData for faster access
      setState(() {
        name = appData.userName;
        email = appData.Email;
        phoneNumber = appData.phoneNumber;
        isLoading = false;
      });
    }
  }

  void _handleLogout() {
    appData.clearUserData();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  void _handleDeleteProfile() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Profile"),
          content: const Text("Are you sure you want to delete your profile?"),
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
                // Delete user profile
                if (appData.isLoggedIn && appData.Email != "You are not logged in") {
                  try {
                    var data = Firestore.instance.collection("appData");
                    await data.document(appData.Email).delete();
                    appData.clearUserData();
                    
                    Navigator.of(context).pop(); // Close dialog
                    
                    // Navigate back to login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile deleted successfully')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop(); // Close dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete profile: ${e.toString()}')),
                    );
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getprofile();
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: appData.isLoggedIn
          ? isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: height * .31,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 190, 82, 15),
                                Color.fromARGB(188, 255, 140, 0),
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
                          name ?? 'User',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 26),
                        ),
                      ),
                      if (errorMessage != null) 
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red),
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
                                ).then((_) => getprofile()); // Refresh data when returning
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
                                ).then((_) => getprofile()); // Refresh data when returning
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
                              onPressed: _handleDeleteProfile,
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
                        onPressed: _handleLogout,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94057),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
