import 'package:flutter/material.dart';

import 'package:my_project/data.dart';
import 'package:my_project/login_screen.dart';
import 'package:my_project/profile.dart';
import 'package:my_project/search_screen.dart';
// import 'package:share_plus/share_plus.dart';

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
        // const ListTile(
        //   leading: Icon(Icons.contact_mail, size: 30),
        //   title: Text(
        //     'Contact Us',
        //     style: TextStyle(
        //         color: Colors.grey,
        //         fontWeight: FontWeight.normal,
        //         fontSize: 22),
        //   ),
        // ),
        // ListTile(
        //   leading: Icon(Icons.share, size: 30),
        //   onTap: () {
        //     var url = "https://www.google.com/";
        //     // Share plugin
        //     // Share.share('check out my website https://example.com');
        //     // Share.share(
        //     //     'Check Out our Search a Holic Application, Now you can search anything here 😎 https://example.com',
        //     //     subject: 'Search a Holic Application Download Now!!');
        //   },
        //   title: const Text(
        //     'Share',
        //     style: TextStyle(
        //         color: Colors.grey,
        //         fontWeight: FontWeight.normal,
        //         fontSize: 22),
        //   ),
        // ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.exit_to_app, size: 30),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const Search();
            }));
          },
          title: const Text(
            'Exit',
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
