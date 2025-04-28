import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:healsearch_app/firebase_database.dart';
import 'package:healsearch_app/navbar.dart';

void main() {
  runApp(const MaterialApp(
    home: Search(),
  ));
}

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
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF8A2387),
                        Color(0xFFE94057),
                        Color(0xFFF27121),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 22.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GestureDetector(
                                  onTap: () {
                                    _scaffoldKey.currentState!.openDrawer();
                                  },
                                  child: const Icon(Icons.menu_open_sharp,
                                      size: 35, color: Colors.white))),
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
              child: Container(
                  child: const Text(
                "Search Results",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              )),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 270.0),
              child: ListView.builder(
                  itemCount: status == 0
                      ? searchedProducts.length
                      : nearbyProducts.length,
                  itemBuilder: (context, index) {
                    if (status == 0) {
                      return CardView(
                        productList: searchedProducts[index],
                      );
                    } else {
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
    // Dummy data for medicines
    var products = [
      {
        "Name": "Panadol",
        "Description": "Pain reliever and fever reducer",
        "StoreLocation": {"latitude": 37.7749, "longitude": -122.4194},
        "StoreName": "Pharmacy A",
        "Price": "\$5"
      },
      {
        "Name": "Panadol",
        "Description": "Pain reliever and fever reducer",
        "StoreLocation": {"latitude": 37.7449, "longitude": -132.4194},
        "StoreName": "Pharmacy B",
        "Price": "\$8"
      },
      {
        "Name": "Panadol",
        "Description": "Pain reliever and fever reducer",
        "StoreLocation": {"latitude": 37.7249, "longitude": -124.4194},
        "StoreName": "Pharmacy C",
        "Price": "\$2"
      },
      {
        "Name": "Aspirin",
        "Description": "Used to reduce pain, fever, or inflammation",
        "StoreLocation": {"latitude": 37.7749, "longitude": -122.4194},
        "StoreName": "Pharmacy B",
        "Price": "\$3"
      },
      {
        "Name": "Ibuprofen",
        "Description": "Nonsteroidal anti-inflammatory drug (NSAID)",
        "StoreLocation": {"latitude": 37.7749, "longitude": -122.4194},
        "StoreName": "Pharmacy C",
        "Price": "\$7"
      },
      {
        "Name": "Amoxicillin",
        "Description": "Antibiotic used to treat bacterial infections",
        "StoreLocation": {"latitude": 37.7749, "longitude": -122.4194},
        "StoreName": "Pharmacy D",
        "Price": "\$10"
      },
      {
        "Name": "Amoxicillin",
        "Description": "Antibiotic used to treat bacterial infections",
        "StoreLocation": {"latitude": 37.7749, "longitude": -122.4194},
        "StoreName": "Pharmacy D",
        "Price": "\$10"
      },
      {
        "Name": "Cough Syrup",
        "Description": "Used to relieve cough and cold symptoms",
        "StoreLocation": {"latitude": 37.7749, "longitude": -122.4194},
        "StoreName": "Pharmacy E",
        "Price": "\$8"
      },
    ];

    var pos = await Flutter_api().getPosition();
    for (var product in products) {
      var distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          (product["StoreLocation"] as Map<String, dynamic>)["latitude"],
          (product["StoreLocation"] as Map<String, dynamic>)["longitude"]);
      product["Distance"] = (distance / 1000).toStringAsFixed(2); // in km
    }

    products.sort((a, b) => double.parse(a["Distance"] as String)
        .compareTo(double.parse(b["Distance"] as String))); // Sort by distance

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
            element["StoreLocation"]["latitude"],
            element["StoreLocation"]["longitude"]);
        if (distance / 1000 < radius) {
          nearbyProducts.add(element);
        }
      }
    }
  }
}

class CardView extends StatelessWidget {
  final Map productList;

  const CardView({required this.productList, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            Text("${productList["Distance"]} km"),
          ],
        ),
        title: Text(productList["Name"]),
        subtitle: Text(productList["Description"]),
        trailing: Text(productList["Price"]),
        onTap: () {
          // Handle card tap
        },
      ),
    );
  }
}
