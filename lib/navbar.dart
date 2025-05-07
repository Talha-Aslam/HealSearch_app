import 'package:flutter/material.dart';
import 'package:healsearch_app/chat_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:healsearch_app/profile.dart';
import 'package:url_launcher/url_launcher.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            'Logged In as:',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.normal,
                fontSize: 16),
          ),
          accountEmail: Text(
            appData.Email,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.normal,
                fontSize: 18),
          ),
          currentAccountPicture:
              (appData.profileImage != null && appData.profileImage!.isNotEmpty)
                  ? CircleAvatar(
                      maxRadius: 30,
                      minRadius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                        appData.profileImage!,
                      ),
                    )
                  : const CircleAvatar(
                      maxRadius: 30,
                      minRadius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage("Images/man.png"),
                    ),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              image: DecorationImage(
                image: AssetImage("Images/bkg.jpg"),
                fit: BoxFit.cover,
                colorFilter: Theme.of(context).brightness == Brightness.dark
                    ? ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.darken)
                    : null,
              )),
        ),
        ListTile(
          leading: const Icon(
            Icons.search,
            size: 30,
          ),
          title: const Text(
            'Search',
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 22),
          ),
          onTap: () {
            // pop closes the drawer
            Navigator.pop(context);
          },
          trailing: const Icon(Icons.arrow_forward, size: 25),
          // ignore: avoid_returning_null_for_void
        ),
        ListTile(
          leading: const Icon(Icons.assessment_rounded, size: 30),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return ChatScreen();
            }));
          },
          title: const Text(
            'AI ChatBot',
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 22),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person, size: 30),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const Profile();
            }));
          },
          title: const Text(
            'Profile',
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 22),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.contact_mail, size: 30),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  title: const Center(
                    child: Text(
                      'Contact Us',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.contact_mail,
                            size: 60,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'HealSearch Developers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const ListTile(
                          leading: Icon(Icons.email, color: Colors.blue),
                          title: Text('Email'),
                          subtitle: Text('talha@student.uol.edu.pk'),
                          dense: true,
                        ),
                        const ListTile(
                          leading: Icon(Icons.phone, color: Colors.blue),
                          title: Text('Phone'),
                          subtitle: Text('+92 123 456 7890'),
                          dense: true,
                        ),
                        const ListTile(
                          leading: Icon(Icons.location_on, color: Colors.blue),
                          title: Text('Address'),
                          subtitle: Text('University of Lahore, Pakistan'),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 15),
                  actionsAlignment: MainAxisAlignment.center,
                );
              },
            );
          },
          title: Text(
            'Contact Us',
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 22),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.exit_to_app, size: 30),
          onTap: () {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const Login();
            }), (Route<dynamic> route) => false);
          },
          title: const Text(
            'Logout',
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 22),
          ),
        ),
      ],
    ));
  }
}
