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
  String _selectedFilter = 'distance'; // 'distance' or 'price'
  bool _isLoading = true; // Loading state

  late GlobalKey<ScaffoldState> _scaffoldKey;
  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    // Initialize the app with location and products
    _initializeWithLocation();
  }

  // Initialize the app with location first, then fetch products
  Future<void> _initializeWithLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await setLocation();
      await setProducts();
    } catch (e) {
      print("Error initializing: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get colors from theme
    final backgroundColor = Theme.of(context).colorScheme.background;
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return RefreshIndicator(
        onRefresh: () async {
          await setProducts();
        },
        child: Scaffold(
          key: _scaffoldKey,
          drawer: const Navbar(),
          backgroundColor: backgroundColor,
          body: Stack(children: [
            Container(
              decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
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
                              _applyFilter();
                            }
                            if (value != "" && status == 0) {
                              searchedProducts = allProducts
                                  .where((element) => element["Name"]
                                      .toString()
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                              _applyFilter();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.filter_list_off_outlined),
                              onPressed: () {
                                _showFilterDialog();
                              }),
                          hintText: "Search",
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(25.0))),
                          hintStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ),
                      ),
                    ),
                  ],
                )),
            Padding(
              padding: const EdgeInsets.only(top: 235.0, left: 35),
              child: Container(
                  child: Text(
                "Search Results",
                style: TextStyle(
                    color: onBackgroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              )),
            ),
            _isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 270.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text("Loading medicines...",
                              style: TextStyle(
                                  fontSize: 16, color: onBackgroundColor))
                        ],
                      ),
                    ),
                  )
                : searchedProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 270.0),
                          child: Text(
                            "No medicines found",
                            style: TextStyle(
                                fontSize: 16, color: onBackgroundColor),
                          ),
                        ),
                      )
                    : Padding(
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.location_on,
                  color: _selectedFilter == 'distance'
                      ? Theme.of(context).colorScheme.primary
                      : null),
              title: Text('Sort by Distance'),
              onTap: () {
                setState(() {
                  _selectedFilter = 'distance';
                  _applyFilter();
                });
                Navigator.pop(context);
              },
              selected: _selectedFilter == 'distance',
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
            ),
            ListTile(
              leading: Icon(Icons.attach_money,
                  color: _selectedFilter == 'price'
                      ? Theme.of(context).colorScheme.primary
                      : null),
              title: Text('Sort by Price'),
              onTap: () {
                setState(() {
                  _selectedFilter = 'price';
                  _applyFilter();
                });
                Navigator.pop(context);
              },
              selected: _selectedFilter == 'price',
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
            ),
          ],
        );
      },
    );
  }

  void _applyFilter() {
    if (_selectedFilter == 'distance') {
      searchedProducts.sort((a, b) => double.parse(a["Distance"] as String)
          .compareTo(double.parse(b["Distance"] as String)));
    } else if (_selectedFilter == 'price') {
      searchedProducts.sort((a, b) {
        double priceA = double.tryParse(
                (a["Price"] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
        double priceB = double.tryParse(
                (b["Price"] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
        return priceA.compareTo(priceB);
      });
    }
  }

  Future<void> setLocation() async {
    try {
      var position = await Flutter_api().getPosition();
      var address =
          await Flutter_api().getAddress(position.latitude, position.longitude);

      setState(() {
        fullAddress = address;
        txt.text = fullAddress;
        userlat = position.latitude;
        userlon = position.longitude;
      });
    } catch (e) {
      print("Error getting location: $e");
      // Handle error gracefully, maybe show a message to user
    }
  }

  Future<void> setProducts() async {
    try {
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

      // Get user position for distance calculations
      var pos = await Flutter_api().getPosition();

      // Calculate distance for each product
      for (var product in products) {
        var distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            (product["StoreLocation"] as Map<String, dynamic>)["latitude"],
            (product["StoreLocation"] as Map<String, dynamic>)["longitude"]);
        product["Distance"] = (distance / 1000).toStringAsFixed(2); // in km
      }

      // Sort by distance
      products.sort((a, b) => double.parse(a["Distance"] as String)
          .compareTo(double.parse(b["Distance"] as String)));

      // Update state to display the products
      if (mounted) {
        setState(() {
          allProducts = products;
          searchedProducts = products;
        });
      }
    } catch (e) {
      print("Error loading products: $e");
      // Handle error gracefully
    }
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.primary),
            Text(
              "${productList["Distance"]} km",
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.8)),
            ),
          ],
        ),
        title: Text(
          productList["Name"],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          productList["Description"],
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: Text(
          productList["Price"],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // Handle card tap
        },
      ),
    );
  }
}
