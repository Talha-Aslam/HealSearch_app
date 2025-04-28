import 'package:flutter/material.dart';
import 'package:healsearch_app/chat_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:healsearch_app/profile.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: const Text(
            'Logged In as:',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 16),
          ),
          accountEmail: Text(
            appData.Email,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 18),
          ),
          currentAccountPicture: const CircleAvatar(
            maxRadius: 30,
            minRadius: 30,
            backgroundImage: AssetImage("images/man.png"),
          ),
          decoration: const BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                image: AssetImage("images/bkg.jpg"),
                fit: BoxFit.cover,
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
          leading: const Icon(Icons.login, size: 30),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const Login();
            }));
          },
          title: const Text(
            'Login',
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
                  title: const Text('Contact Us'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.contact_mail, size: 50, color: Colors.blue),
                      SizedBox(height: 10),
                      Text('HealSearch Developers'),
                      Text('Email: talha@student.uol.edu.pk'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Thanks'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
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
