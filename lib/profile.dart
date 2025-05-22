import 'package:flutter/material.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/firebase_database.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? profileImageUrl;
  bool isLoading = false;
  String? errorMessage;

  // Create instance of our Firebase API wrapper
  final _firebaseApi = Flutter_api();

  Future<void> getprofile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Only fetch from Firebase if logged in
    if (appData.isLoggedIn && appData.Email != "You are not logged in") {
      try {
        // Use our improved getUserData method with caching
        final userData = await _firebaseApi.getUserData();

        if (userData != null) {
          setState(() {
            name = userData['name'];
            email = userData['email'];
            // Handle different field names for phone number
            phoneNumber = userData['phoneNumber'] ?? userData['phNo'];
            profileImageUrl = userData['profileImage'];
            // Update global appData profile image for navbar
            appData.profileImage = userData['profileImage'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "User profile not found";
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = "Error fetching profile data";
          isLoading = false;
        });
      }
    } else {
      // Use the data from AppData for faster access
      setState(() {
        name = appData.userName;
        email = appData.Email;
        phoneNumber = appData.phoneNumber;
        profileImageUrl = null;
        isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    try {
      // Use our improved signOut method
      await _firebaseApi.signOut();

      appData.clearUserData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: ${e.toString()}')),
      );
    }
  }

  void _handleDeleteProfile() async {
    // Store the context in a variable that will be captured in the closure
    final BuildContext currentContext = context;
    BuildContext?
        loadingDialogContext; // Define dialog context variable at method level

    showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Profile"),
          content: const Text("Are you sure you want to delete your profile?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () async {
                // First close the confirmation dialog
                Navigator.of(dialogContext).pop();

                // Delete user profile
                if (appData.isLoggedIn &&
                    appData.Email != "You are not logged in") {
                  // Store variables to track state outside the try block for wider scope
                  bool shouldNavigateToLogin = false;
                  bool deletionSuccessful = false;
                  String? errorMessage;
                  try {
                    // Show a loading dialog
                    // Using the method-level loadingDialogContext
                    showDialog(
                      context: currentContext,
                      barrierDismissible: false,
                      builder: (BuildContext dialogContext) {
                        loadingDialogContext = dialogContext;
                        return const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Deleting profile..."),
                            ],
                          ),
                        );
                      },
                    );

                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Use a batch operation to delete user data from both collections
                      final batch = FirebaseFirestore.instance.batch();

                      // Delete from users collection
                      batch.delete(FirebaseFirestore.instance
                          .collection(FirestoreCollections.users)
                          .doc(user.uid));

                      // Delete from legacy appData collection if email is available
                      if (appData.Email.isNotEmpty) {
                        batch.delete(FirebaseFirestore.instance
                            .collection(FirestoreCollections.appData)
                            .doc(appData.Email));
                      }

                      // Commit batch operation
                      await batch.commit();

                      // The user needs to have recently signed in to delete their account
                      // First check when they last signed in
                      final metadata = user.metadata;
                      final lastSignInTime = metadata.lastSignInTime;
                      final now = DateTime.now();

                      // If the user hasn't signed in recently (within the last hour), we need to re-authenticate
                      if (lastSignInTime == null ||
                          now.difference(lastSignInTime).inMinutes > 60) {
                        // Close the loading dialog safely
                        if (Navigator.canPop(loadingDialogContext!)) {
                          Navigator.of(loadingDialogContext!).pop();
                          loadingDialogContext = null;
                        }

                        // Create a password controller for re-authentication
                        final passwordController = TextEditingController();

                        // Show a dialog to get the user's password for re-authentication
                        final reAuthResult = await showDialog<bool>(
                          context: currentContext,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text("Re-authentication Required"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                      "Please enter your password to confirm account deletion."),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: "Password",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text("Confirm"),
                                  onPressed: () async {
                                    try {
                                      // Show loading indicator in dialog
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Verifying...')),
                                      );

                                      // Create credential
                                      final credential =
                                          EmailAuthProvider.credential(
                                        email: user.email!,
                                        password: passwordController.text,
                                      );

                                      // Re-authenticate
                                      await user.reauthenticateWithCredential(
                                          credential);
                                      Navigator.of(dialogContext).pop(true);
                                    } catch (e) {
                                      Navigator.of(dialogContext).pop(false);
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Authentication failed: ${e.toString()}')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );

                        // If re-authentication was cancelled or failed, abort the deletion
                        if (reAuthResult != true) {
                          errorMessage = 'Account deletion cancelled';
                          return;
                        }

                        // Show loading dialog again
                        showDialog(
                          context: currentContext,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            loadingDialogContext = dialogContext;
                            return const AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text("Deleting profile..."),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      try {
                        // Now try to delete the user authentication record
                        await user.delete();

                        // Clear cache and user data
                        _firebaseApi.clearCaches();
                        appData.clearUserData();

                        deletionSuccessful = true;
                        shouldNavigateToLogin = true;
                      } catch (e) {
                        errorMessage =
                            'Failed to delete profile: ${e.toString()}';
                      }
                    }
                  } catch (e) {
                    errorMessage = 'Failed to delete profile: ${e.toString()}';
                  } finally {
                    // Close loading dialog safely if it's still open
                    if (loadingDialogContext != null &&
                        Navigator.canPop(loadingDialogContext!)) {
                      Navigator.of(loadingDialogContext!).pop();
                    }

                    // Show success or error message - but only if we're not navigating away
                    if (!shouldNavigateToLogin && errorMessage != null) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    } else if (deletionSuccessful) {
                      // First show the success message
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        const SnackBar(
                            content: Text('Profile deleted successfully')),
                      );

                      // Use a slight delay before navigation to allow the snackbar to be seen
                      await Future.delayed(const Duration(milliseconds: 500));

                      // Then navigate to login screen if the context is still valid
                      if (currentContext.mounted) {
                        Navigator.pushReplacement(
                          currentContext,
                          MaterialPageRoute(
                              builder: (context) => const Login()),
                        );
                      }
                    }
                  }
                } else {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'You must be logged in to delete your profile')),
                  );
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
              ? const Center(child: CircularProgressIndicator())
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
                      Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: (profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage("Images/man.png")
                                  as ImageProvider,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Text(
                          name ?? 'User',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 190, 82, 15),
                              fontWeight: FontWeight.bold,
                              fontSize: 26),
                        ),
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
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
                                      builder: (context) =>
                                          const ShowProfile()),
                                ).then((_) =>
                                    getprofile()); // Refresh data when returning
                              },
                              icon:
                                  const Icon(Icons.person, color: Colors.white),
                              label: const Text('Show Profile'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(255, 190, 82, 15),
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
                                      builder: (context) =>
                                          const UpdateProfile()),
                                ).then((_) =>
                                    getprofile()); // Refresh data when returning
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text('Update Profile'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(188, 255, 140, 0),
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
                              icon:
                                  const Icon(Icons.delete, color: Colors.white),
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
