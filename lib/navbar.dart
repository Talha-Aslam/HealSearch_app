import 'package:flutter/material.dart';
import 'package:healsearch_app/chat_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:healsearch_app/profile.dart';
import 'package:healsearch_app/contact_us_screen_new.dart';
import 'package:url_launcher/url_launcher.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.withOpacity(0.8);
    final iconColor = theme.colorScheme.primary;

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
          leading: Icon(
            Icons.search,
            size: 30,
            color: iconColor,
          ),
          title: Text(
            'Search',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.normal, fontSize: 22),
          ),
          onTap: () {
            // pop closes the drawer
            Navigator.pop(context);
          },
          trailing: Icon(Icons.arrow_forward, size: 25, color: iconColor),
          // ignore: avoid_returning_null_for_void
        ),
        ListTile(
          leading: Icon(Icons.assessment_rounded, size: 30, color: iconColor),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return ChatScreen();
            }));
          },
          title: Text(
            'AI ChatBot',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.normal, fontSize: 22),
          ),
        ),
        ListTile(
          leading: Icon(Icons.person, size: 30, color: iconColor),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const Profile();
            }));
          },
          title: Text(
            'Profile',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.normal, fontSize: 22),
          ),
        ),
        ListTile(
          leading: Icon(Icons.contact_mail, size: 30, color: iconColor),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const ContactUsScreen();
            }));
          },
          title: Text(
            'Contact Us',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.normal, fontSize: 22),
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.exit_to_app, size: 30, color: iconColor),
          onTap: () {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return const Login();
            }), (Route<dynamic> route) => false);
          },
          title: Text(
            'Logout',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.normal, fontSize: 22),
          ),
        ),
      ],
    ));
  }
}
