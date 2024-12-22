import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:my_project/firebase_database.dart';
import 'package:my_project/card.dart';
import 'package:my_project/navbar.dart';
// import 'package:flutter_switch/flutter_switch.dart';
// import 'package:toggle_switch/toggle_switch.dart';

class Search extends StatefulWidget {
  const Search({super.key});
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String fullAddress = ".....";
  final TextEditingController _searchQuery = TextEditingController();
  TextEditingController txt = TextEditingController();
  List allProducts = [];
  List nearbyProducts = [];
  List searchedProducts = [];
  late double userlat;
  late double userlon;
  bool status1 = false;

  int status = 0;

  late GlobalKey<ScaffoldState> _scaffoldKey;
  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    setProducts();
    setLocation();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () async {
          await setProducts();
        },
        //commiting again
        child: Scaffold(
          key: _scaffoldKey,
          drawer: const Navbar(),
          body: Stack(children: [
            Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40.0),
                      bottomRight: Radius.circular(40.0))),
            ),
            Container(
                height: 230,
                width: MediaQuery.of(context).size.width * 1,
                decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 22.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GestureDetector(
                                  onTap: () {
                                    _scaffoldKey.currentState!.openDrawer();

                                    // drwaer element
                                  },
                                  child: const Icon(Icons.menu_open_sharp,
                                      size: 35, color: Colors.white))),
                          Padding(
                            padding: const EdgeInsets.all(1.0),
                            child: PopupMenuButton(
                              icon: const Icon(Icons.more_horiz,
                                  size: 25, color: Colors.white),
                              itemBuilder: (context) => [
                                // PopupMenuItem(
                                //   child: Text("Help ?"),
                                //   onTap: () {
                                //     showDialog(
                                //       context: context,
                                //       builder: (BuildContext context) {
                                //         return StatefulBuilder(
                                //           builder: (BuildContext context,
                                //               StateSetter setState) {
                                //             return AlertDialog(
                                //               title: const Text("Help"),
                                //               content: const Text(
                                //                   "This is a help dialog box"),
                                //               actions: [
                                //                 TextButton(
                                //                   onPressed: () {
                                //                     Navigator.of(context).pop();
                                //                   },
                                //                   child: const Text("Close"),
                                //                 ),
                                //               ],
                                //             );
                                //           },
                                //         );
                                //       },
                                //     );
                                //   },
                                //   value: 1,
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 220.0),
                      child: Text(
                        'Search for',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 150.0),
                      child: Text(
                        'Your Medicine!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontSize: 26),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 08),
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.08,
                      child: TextField(
                        controller: _searchQuery,
                        onSubmitted: (value) {},
                        onChanged: (value) {
                          // Filtering the Products
                          // ignore: avoid_print
                          print(value);
                          setState(() {
                            if (value == "" && status == 0) {
                              searchedProducts = allProducts;
                            }
                            if (value != "" && status == 0) {
                              searchedProducts = allProducts
                                  .where((element) => element["Name"]
                                      .toString()
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            }
                          });
                        },
                        //controller: email,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.filter_list_off_outlined),
                              onPressed: () {}),
                          hintText: "Search",
                          filled: true,
                          fillColor: Colors.white,
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(25.0))),
                          hintStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w300),
                        ),
                      ),
                    ),
                  ],
                )),

            Padding(
              padding: const EdgeInsets.only(top: 235.0, left: 35),
              // ignore: avoid_unnecessary_containers
              child: Container(
                  child: const Text(
                "Search Results",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              )),
            ),

            // Location Left Side icon and Text with Current Location
            Padding(
                padding: const EdgeInsets.only(top: 259.0, left: 30),
                child: SizedBox(
                  child: Row(
                    // ignore: prefer_const_literals_to_create_immutables
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        fullAddress,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                )),

            const Padding(
              padding: EdgeInsets.only(top: 85, left: 280),
              child: CircleAvatar(
                maxRadius: 25,
                minRadius: 25,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage("images/man.png"),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(top: 250.0, left: 80),
            //   // ignore: avoid_unnecessary_containers
            //   child: Container(
            //     child: ToggleSwitch(
            //       minWidth: 110.0,
            //       cornerRadius: 20.0,
            //       activeBgColors: [
            //         [Colors.blue],
            //         [Colors.blue],
            //       ],
            //       activeFgColor: Colors.white,
            //       inactiveBgColor: Colors.green,
            //       inactiveFgColor: Colors.white,
            //       initialLabelIndex: 0,
            //       totalSwitches: 2,
            //       labels: ['All Products', 'Nearby'],
            //       radiusStyle: true,
            //       onToggle: (index) {
            //         searchQuery(index!);
            //       },
            //     ),
            //   ),
            // ),

            // Padding(
            //   padding: const EdgeInsets.only(left: 80, bottom: 160),
            //   child: FlutterSwitch(
            //     width: 105.0,
            //     height: 40.0,
            //     valueFontSize: 25.0,
            //     toggleSize: 45.0,
            //     value: status1,
            //     borderRadius: 30.0,
            //     padding: 8.0,
            //     showOnOff: true,
            //     onToggle: (val) {
            //       setState(() {
            //         status1 = val;
            //         print(status1);
            //       });
            //     },
            //   ),
            // ),

            Padding(
              padding: const EdgeInsets.only(top: 250.0),
              child: ListView.builder(
                  itemCount: status == 0
                      ? searchedProducts.length
                      : nearbyProducts.length,
                  itemBuilder: (context, index) {
                    if (status == 0) {
                      // ignore: avoid_print
                      print("---------> ALL Products");
                      return CardView(
                        productList: searchedProducts[index],
                      );
                    } else {
                      // ignore: avoid_print
                      print("---------> NearBy Products");

                      return CardView(
                        productList: nearbyProducts[index],
                      );
                    }
                  }),
            )
          ]),
        ));
  }

  Future<void> setLocation() async {
    var position = await Flutter_api().getPosition();
    var address =
        await Flutter_api().getAddress(position.latitude, position.longitude);

    setState(() {
      fullAddress = address;
      txt.text = fullAddress;
      userlat = position.latitude;
      userlon = position.longitude;
    });
  }

  Future<void> setProducts() async {
    var products = await Flutter_api().getAllProducts();
    setState(() {
      allProducts = products;
      searchedProducts = products;
    });
  }

  // Search Query for Products
  Future<void> searchQuery(int index) async {
    setState(() {
      status = index;
    });
    // ignore: avoid_print
    print(status);

    if (index == 0) return;

    // nearbyProducts
    var pos = await Flutter_api().getPosition();
    int radius = 5000000;
    nearbyProducts.clear();
    // filter the products based on the location
    for (var element in allProducts) {
      if (element["StoreLocation"] != null) {
        var distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            element["StoreLocation"].latitude,
            element["StoreLocation"].longitude);
        // ignore: avoid_print
        print(distance);
        if (distance / 1000 < radius) {
          // ignore: avoid_print
          print("add Product");
          nearbyProducts.add(element);
        }
      }
    }

    // ignore: avoid_print
    print(allProducts.length);
    // ignore: avoid_print
    print(nearbyProducts.length);
  }
}
