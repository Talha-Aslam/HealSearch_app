// ignore_for_file: unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class Androidsmall1Widget extends StatefulWidget {
  late final String productName;
  late final String productCategory;
  late final String expiryDate;
  late final String price;
  late final String storeName;
  late final String lat;
  late final String long;

  Androidsmall1Widget({super.key, required this.lat, required this.long});

  // Getting Google Maps Link

  late final String mapsLink = Flutter_api().getGoogleMapsLink(lat, long);

  @override
  State<Androidsmall1Widget> createState() => _Androidsmall1WidgetState();
}

class _Androidsmall1WidgetState extends State<Androidsmall1Widget> {
  // Getting maps link from Widget

  late String lat = widget.lat;
  late String long = widget.long;

  static void navigateTo(double lat, double lng) async {
    var uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch ${uri.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using Padding Rows and Column instead of Positioned responses to the screen size

    return Scaffold(
        backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
        body: Stack(children: <Widget>[
          Positioned(
              top: 39,
              left: 108,
              child: Text(
                'Product Details',
                textAlign: TextAlign.left,
                style: GoogleFonts.josefinSans(
                    color: const Color.fromRGBO(2, 0, 47, 1),
                    fontSize: 25,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 124,
              left: 31,
              child: Text(
                'Adalimumab',
                textAlign: TextAlign.left,
                style: GoogleFonts.kumbhSans(
                    color: const Color.fromRGBO(2, 0, 47, 1),
                    fontSize: 21,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 172,
              left: 140,
              child: Text(
                'Details',
                textAlign: TextAlign.left,
                style: GoogleFonts.josefinSans(
                    color: const Color.fromRGBO(255, 101, 86, 1),
                    fontSize: 25,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 225,
              left: 31,
              child: Text(
                'Category:',
                textAlign: TextAlign.left,
                style: GoogleFonts.josefinSans(
                    color: const Color.fromRGBO(2, 0, 47, 1),
                    fontSize: 15,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 280,
              left: 31,
              child: Text(
                'Expiry Date:',
                textAlign: TextAlign.left,
                style: GoogleFonts.josefinSans(
                    color: const Color.fromRGBO(2, 0, 47, 1),
                    fontSize: 15,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 335,
              left: 31,
              child: Text(
                'Price:',
                textAlign: TextAlign.left,
                style: GoogleFonts.josefinSans(
                    color: const Color.fromRGBO(2, 0, 47, 1),
                    fontSize: 15,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 390,
              left: 31,
              child: Text(
                'Store Name:',
                textAlign: TextAlign.left,
                style: GoogleFonts.josefinSans(
                    color: const Color.fromRGBO(2, 0, 47, 1),
                    fontSize: 15,
                    letterSpacing:
                        0 /*percentages not used in flutter. defaulting to zero*/,
                    fontWeight: FontWeight.normal,
                    height: 1),
              )),
          Positioned(
              top: 583,
              left: 0,
              child: SizedBox(
                  width: 360,
                  height: 57,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 360,
                            height: 57,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(2, 0, 47, 1),
                            ))),
                    Positioned(
                        top: 12.05767822265625,
                        left: 295.9050598144531,
                        child: Container(
                            width: 32.04747772216797,
                            height: 32.88461685180664,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('images/user.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                    Positioned(
                        top: 12.05767822265625,
                        left: 34.18397521972656,
                        child: Container(
                            width: 32.04747772216797,
                            height: 32.88461685180664,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('images/products.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                    Positioned(
                        top: 12.05767822265625,
                        left: 164.5103759765625,
                        child: Container(
                            width: 32.04747772216797,
                            height: 32.88461685180664,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('images/search.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                  ]))),
          Positioned(
              top: 34,
              left: 31,
              child: SizedBox(
                  width: 28,
                  height: 25,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 28,
                            height: 25,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5),
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                              color: Color.fromRGBO(2, 0, 47, 1),
                            ))),
                    Positioned(
                        top: 2,
                        left: 4,
                        child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.25),
                                    offset: Offset(0, 4),
                                    blurRadius: 4)
                              ],
                              image: DecorationImage(
                                  image: AssetImage('images/back.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                  ]))),
          Positioned(
              top: 125,
              left: 291,
              child: SizedBox(
                  width: 28,
                  height: 25,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 28,
                            height: 25,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5),
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                              color: Color.fromRGBO(2, 0, 47, 1),
                            ))),
                    Positioned(
                        top: 2,
                        left: 4,
                        child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('images/favorite.png'),
                                  fit: BoxFit.fitWidth),
                            ))),
                  ]))),
          Positioned(
              top: 455,
              left: 75,
              child: SizedBox(
                  width: 211,
                  height: 50,
                  child: Stack(children: <Widget>[
                    Positioned(
                      top: 20,
                      left: 18,
                      child: TextButton(
                          onPressed: () {
                            // Adding link to google maps

                            // Converting String to double
                            double lat = double.parse(widget.lat);
                            double long = double.parse(widget.long);

                            navigateTo(lat, long);
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromRGBO(255, 107, 83, 1)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            )),
                          ),
                          child: Text(
                            'Open on Google Maps',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.josefinSans(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontSize: 17,
                                letterSpacing:
                                    0 /*percentages not used in flutter. defaulting to zero*/,
                                fontWeight: FontWeight.normal,
                                height: 1),
                          )),
                    ),
                  ]))),
          Positioned(
              top: 219,
              left: 180,
              child: SizedBox(
                  width: 139,
                  height: 27,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 139,
                            height: 27,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              color: Color.fromRGBO(239, 239, 239, 1),
                            ))),
                    Positioned(
                        top: 6,
                        left: 42,
                        child: Text(
                          'Tablets',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.montserrat(
                              color: const Color.fromRGBO(30, 30, 30, 1),
                              fontSize: 15,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                        )),
                  ]))),
          Positioned(
              top: 274,
              left: 179,
              child: SizedBox(
                  width: 139,
                  height: 27,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 139,
                            height: 27,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              color: Color.fromRGBO(239, 239, 239, 1),
                            ))),
                    Positioned(
                        top: 7,
                        left: 20,
                        child: Text(
                          '26 - 03 - 2023',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.montserrat(
                              color: const Color.fromRGBO(30, 30, 30, 1),
                              fontSize: 15,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                        )),
                  ]))),
          Positioned(
              top: 329,
              left: 179,
              child: SizedBox(
                  width: 139,
                  height: 27,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 139,
                            height: 27,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              color: Color.fromRGBO(239, 239, 239, 1),
                            ))),
                    Positioned(
                        top: 5,
                        left: 38,
                        child: Text(
                          'Rs. 2500',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.montserrat(
                              color: const Color.fromRGBO(30, 30, 30, 1),
                              fontSize: 15,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                        )),
                  ]))),
          Positioned(
              top: 384,
              left: 179,
              child: SizedBox(
                  width: 136,
                  height: 55,
                  child: Stack(children: <Widget>[
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                            width: 136,
                            height: 55,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              color: Color.fromRGBO(239, 239, 239, 1),
                            ))),
                    Positioned(
                        top: 9,
                        left: 9,
                        child: Text(
                          'Rehman Medical Store',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.montserrat(
                              color: const Color.fromRGBO(30, 30, 30, 1),
                              fontSize: 15,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                        )),
                  ]))),
        ]));
  }
}
