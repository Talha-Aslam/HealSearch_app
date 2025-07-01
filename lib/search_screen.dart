import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:healsearch_app/firebase_database.dart';
import 'package:healsearch_app/navbar.dart';
import 'package:healsearch_app/pharmacy_map_screen_fixed.dart';
import 'package:healsearch_app/services/pharmacy_search_service.dart';
import 'package:healsearch_app/services/pharmacy_diagnostic_util.dart';
import 'package:healsearch_app/data.dart';
import 'package:healsearch_app/login_screen.dart';

// Utility class to prevent multiple snackbars from appearing
class SnackBarDebouncer {
  static DateTime? _lastSnackBarTime;
  static const Duration _debounceTime = Duration(seconds: 2);

  // Show a snackbar only if enough time has passed since the last one
  static void showSnackBar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 2)}) {
    final now = DateTime.now();
    if (_lastSnackBarTime == null ||
        now.difference(_lastSnackBarTime!) > _debounceTime) {
      _lastSnackBarTime = now;

      // Hide any existing snackbars first
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show the new snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
        ),
      );
    }
    // If not enough time has passed, do nothing (suppress the snackbar)
  }
}

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
  Timer? _searchTimer;
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

    // Check authentication before proceeding
    _checkAuthenticationAndInitialize();
  }

  Future<void> _checkAuthenticationAndInitialize() async {
    final user = FirebaseAuth.instance.currentUser;
    final appDataInstance = AppData();

    // Check if user is properly authenticated
    if (user == null ||
        !appDataInstance.isLoggedIn ||
        appDataInstance.Email == "You are not logged in") {
      // User is not properly authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      });
      return;
    }

    // User is authenticated, proceed with initialization
    _initializeWithLocation();
  } // Initialize the app with location first, then fetch products

  Future<void> _initializeWithLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Run diagnostics to check pharmacy data before starting
      try {
        debugPrint('🔬 Running pharmacy data diagnostics...');
        await PharmacyDiagnosticUtil.verifyPharmacyData();
      } catch (diagError) {
        debugPrint('⚠️ Diagnostic error: $diagError');
      }

      await setLocation();
      await setProducts();
    } catch (e) {
      // Handle location-specific errors
      if (e.toString().contains('Location services are disabled')) {
        _showLocationServiceDialog();
      } else if (e.toString().contains('Location permissions are denied') ||
          e.toString().contains('permanently denied')) {
        _showLocationPermissionDialog();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check whether location services are enabled before showing loading indicator
  Future<bool> _verifyLocationServices() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // If not enabled, update UI and show error
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            status1 = true; // Set location error flag
            _isLoading = false; // Ensure loading is off
          });
          // Only show dialog on first load if products are empty
          if (allProducts.isEmpty) {
            _showLocationServiceDialog();
          } else {
            // Just show a snackbar for subsequent attempts
            SnackBarDebouncer.showSnackBar(
              context,
              'Please enable location services',
              duration: const Duration(seconds: 2),
            );
          }
        }
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            status1 = true;
            _isLoading = false;
          });
          _showLocationPermissionDialog();
        }
        return false;
      }

      return true; // Location services and permissions are okay
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get colors from theme
    final backgroundColor = Theme.of(context).colorScheme.background;
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;
    return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          try {
            await setLocation();
            await setProducts();
          } catch (e) {
            // Errors are handled in the respective methods
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
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
                          // Cancel previous search timer if it exists
                          _searchTimer?.cancel();

                          // Real-time search using Firestore with debouncing
                          if (status == 0) {
                            if (value.trim().isEmpty) {
                              // If search is empty, show all products immediately
                              setState(() {
                                searchedProducts = allProducts;
                                _applyFilter();
                              });
                            } else {
                              // Debounce the search to avoid too many API calls
                              _searchTimer = Timer(
                                  const Duration(milliseconds: 500), () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  // Search for medicines with the query
                                  var position =
                                      await Flutter_api().getPosition();
                                  var filteredProducts =
                                      await PharmacySearchService
                                          .searchNearbyMedicines(
                                    userPosition: position,
                                    searchQuery: value.trim(),
                                  );

                                  // If no results from Firestore, show empty results
                                  if (filteredProducts.isEmpty) {
                                    debugPrint(
                                        'No medicines found matching search: $value');
                                  }

                                  setState(() {
                                    searchedProducts = filteredProducts;
                                    _applyFilter();
                                    _isLoading = false;
                                  });

                                  // Check for expiring medicines in search results
                                  _checkForExpiringSoonMedicines();
                                } catch (e) {
                                  debugPrint('Error during search: $e');

                                  // Show error message and empty results
                                  setState(() {
                                    searchedProducts = [];
                                    _applyFilter();
                                    _isLoading = false;
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Error searching medicines: Please try again"),
                                      ),
                                    );
                                  }
                                }
                              });
                            }
                          }
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
              child: Text(
                "Search Results",
                style: TextStyle(
                    color: onBackgroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
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
                : status1 == true // Location error occurred
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 270.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Location services are disabled",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: onBackgroundColor),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Please enable location services to see medicines available near you.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: onBackgroundColor.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Geolocator.openLocationSettings();
                                  // Wait briefly and then try again
                                  await Future.delayed(
                                      const Duration(seconds: 1));
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = true;
                                      status1 = false;
                                    });
                                    _retryLocationInitialization();
                                  }
                                },
                                icon: const Icon(Icons.settings),
                                label: const Text("Open Location Settings"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // FIXED RETRY BUTTON IMPLEMENTATION
                              TextButton.icon(
                                onPressed: () async {
                                  // First check if location is enabled before showing loading indicator
                                  bool serviceEnabled = await Geolocator
                                      .isLocationServiceEnabled();
                                  if (!serviceEnabled) {
                                    if (context.mounted) {
                                      SnackBarDebouncer.showSnackBar(
                                        context,
                                        'Please enable location services first',
                                        duration: const Duration(seconds: 2),
                                      );
                                    }
                                    return;
                                  }

                                  // Double-check permissions to prevent loading indefinitely
                                  LocationPermission permission =
                                      await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied ||
                                      permission ==
                                          LocationPermission.deniedForever) {
                                    if (context.mounted) {
                                      SnackBarDebouncer.showSnackBar(
                                        context,
                                        'Location permission is denied. Please update in settings.',
                                        duration: const Duration(seconds: 2),
                                      );
                                    }
                                    return;
                                  }

                                  if (mounted) {
                                    setState(() {
                                      _isLoading = true;
                                      status1 =
                                          false; // Reset location error status
                                    });
                                    try {
                                      await setLocation();
                                      await setProducts();
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() {
                                          status1 = true;
                                        });
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : searchedProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 270.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: onBackgroundColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No medicines found",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: onBackgroundColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Try searching for a different medicine\nor check your internet connection",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: onBackgroundColor.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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

  // Show dialog when location services are disabled
  void _showLocationServiceDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
              'Please enable location services to see nearby medicines. '
              'HealSearch needs your location to show medicines available near you.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                // Wait a moment and check if location is enabled now
                await Future.delayed(const Duration(seconds: 3));
                if (mounted) {
                  _retryLocationInitialization();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Show dialog when location permissions are denied
  void _showLocationPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'HealSearch needs location permission to show medicines available near you. '
              'Please grant location permission in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open App Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
                // Wait a moment and check if permission is granted now
                await Future.delayed(const Duration(seconds: 3));
                if (mounted) {
                  _retryLocationInitialization();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // FIXED: Improved retry location initialization
  Future<void> _retryLocationInitialization() async {
    if (!mounted) return;

    // First verify location services without showing dialog
    bool servicesEnabled = await _verifyLocationServices();

    // Only proceed if location services are enabled
    if (servicesEnabled) {
      if (mounted) {
        try {
          await setLocation();
          await setProducts();
        } catch (e) {
          // If there's an error, ensure we update the UI state properly
          if (mounted) {
            setState(() {
              status1 = true;
              _isLoading = false;
            });
          }
        } finally {
          // Ensure loading is turned off in all cases
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } else {
      // If location services are still not available, make sure loading state is off
      if (mounted) {
        setState(() {
          _isLoading = false;
          status1 = true;
        });
      }
    }
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

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchQuery.dispose();
    txt.dispose();
    super.dispose();
  }

  Future<void> setLocation() async {
    try {
      // Reset status1 flag
      if (mounted) {
        setState(() {
          status1 = false;
        });
      }

      // Try to get user position
      var position = await Flutter_api().getPosition();
      var address =
          await Flutter_api().getAddress(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          fullAddress = address;
          txt.text = fullAddress;
          userlat = position.latitude;
          userlon = position.longitude;
        });
      }
    } catch (e) {
      // Set status1 flag to indicate location error
      if (mounted) {
        setState(() {
          status1 = true;
        });
      }

      // Re-throw the error so the calling method can handle it
      rethrow;
    }
  }

  Future<void> setProducts() async {
    if (status1) {
      // If we already know location services are disabled, don't proceed
      return;
    }

    try {
      // Get user position
      var position = await Flutter_api().getPosition();

      debugPrint('User position: ${position.latitude}, ${position.longitude}');

      // Search for nearby medicines using Firestore
      var products = await PharmacySearchService.searchNearbyMedicines(
        userPosition: position,
        searchQuery: null, // Get all medicines initially
      );

      debugPrint('Found ${products.length} medicines from Firestore');

      // If no products found, show a message but don't throw an error
      if (products.isEmpty) {
        debugPrint('No medicines found in nearby pharmacies');
        // Show message that no medicines were found
        debugPrint(
            'No medicines found in nearby pharmacies - showing empty list');
      }

      // Update state to display the products
      if (mounted) {
        setState(() {
          allProducts = products;
          searchedProducts = products;
        });

        // Check for medicines expiring soon and show warning
        _checkForExpiringSoonMedicines();
      }
    } catch (e) {
      debugPrint('Error loading medicine data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error loading medicine data: Please try again")));
      }

      // Show empty results on error
      if (mounted) {
        setState(() {
          allProducts = [];
          searchedProducts = [];
        });
      }
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

  /// Check for medicines expiring soon (without showing snackbar alerts)
  void _checkForExpiringSoonMedicines() {
    // This method is now a no-op to avoid interrupting user experience
    // The expiry information is still visible in the UI through color coding
    // and expiry date display in the CardView widgets
  }
}

class CardView extends StatelessWidget {
  final Map productList;

  const CardView({required this.productList, super.key});

  /// Get color for expiry date based on timeframe
  Color _getExpiryColor(String expiryDate, ThemeData theme) {
    if (_isExpiringWithinWeek(expiryDate)) {
      return Colors.red; // Red for urgent (within a week)
    } else if (_isExpiringSoon(expiryDate)) {
      return Colors.orange; // Orange for warning (within 3 months)
    } else {
      return theme.colorScheme.onSurface.withOpacity(0.6); // Normal color
    }
  }

  /// Get font weight for expiry date based on timeframe
  FontWeight _getExpiryFontWeight(String expiryDate) {
    if (_isExpiringWithinWeek(expiryDate)) {
      return FontWeight.bold; // Bold for urgent
    } else if (_isExpiringSoon(expiryDate)) {
      return FontWeight.w600; // Semi-bold for warning
    } else {
      return FontWeight.normal; // Normal weight
    }
  }

  /// Check if expiring within a week (urgent)
  bool _isExpiringWithinWeek(String expiryDate) {
    if (expiryDate.isEmpty) return false;

    try {
      DateTime expiry;
      final now = DateTime.now();

      // Handle different date formats
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 3) {
          final year = int.parse(parts[2]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[0]);

          if (month > 12) {
            expiry = DateTime(year, day, month);
          } else {
            expiry = DateTime(year, month, day);
          }
        } else {
          return false;
        }
      } else if (expiryDate.contains('-')) {
        expiry = DateTime.parse(expiryDate);
      } else {
        expiry = DateTime.parse(expiryDate);
      }

      // Check if expiring within a week
      final oneWeekFromNow = DateTime(now.year, now.month, now.day + 7);
      return expiry.isBefore(oneWeekFromNow) && expiry.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  /// Check if a medicine is expiring soon (within 3 months)
  bool _isExpiringSoon(String expiryDate) {
    if (expiryDate.isEmpty) return false;

    try {
      DateTime expiry;
      final now = DateTime.now();

      // Handle different date formats
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 3) {
          final year = int.parse(parts[2]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[0]);

          if (month > 12) {
            expiry = DateTime(year, day, month);
          } else {
            expiry = DateTime(year, month, day);
          }
        } else {
          return false;
        }
      } else if (expiryDate.contains('-')) {
        expiry = DateTime.parse(expiryDate);
      } else {
        expiry = DateTime.parse(expiryDate);
      }

      // Check if expiring within 3 months
      final threeMonthsFromNow = DateTime(now.year, now.month + 3, now.day);
      return expiry.isBefore(threeMonthsFromNow) && expiry.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  /// Format expiry date for display
  String _formatExpiryDate(String expiryDate) {
    if (expiryDate.isEmpty) return 'N/A';

    try {
      DateTime expiry;

      // Handle different date formats
      if (expiryDate.contains('/')) {
        final parts = expiryDate.split('/');
        if (parts.length == 3) {
          final year = int.parse(parts[2]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[0]);

          if (month > 12) {
            expiry = DateTime(year, day, month);
          } else {
            expiry = DateTime(year, month, day);
          }
        } else {
          return expiryDate;
        }
      } else if (expiryDate.contains('-')) {
        expiry = DateTime.parse(expiryDate);
      } else {
        expiry = DateTime.parse(expiryDate);
      }

      // Format as "Dec 2025" or "15 Aug 2025" for better readability
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return "${expiry.day} ${months[expiry.month - 1]} ${expiry.year}";
    } catch (e) {
      return expiryDate; // Return original if parsing fails
    }
  }

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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              productList["Description"],
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Add expiry date display
            if (productList["Expire"] != null &&
                productList["Expire"].toString().isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: _getExpiryColor(
                        productList["Expire"].toString(), theme),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Expires: ${_formatExpiryDate(productList["Expire"].toString())}",
                    style: TextStyle(
                      fontSize: 12,
                      color: _getExpiryColor(
                          productList["Expire"].toString(), theme),
                      fontWeight: _getExpiryFontWeight(
                          productList["Expire"].toString()),
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2,
                      size: 12, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 2),
                  Text(
                    "Qty: ${productList["Quantity"] ?? 'N/A'}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              productList["Price"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to pharmacy location on map
          final storeLocation =
              productList["StoreLocation"] as Map<String, dynamic>;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacyMapScreen(
                pharmacyName: productList["StoreName"],
                latitude: storeLocation["latitude"],
                longitude: storeLocation["longitude"],
                medicineName: productList["Name"],
                medicinePrice: productList["Price"],
                medicineQuantity: productList["Quantity"]?.toString() ?? "N/A",
              ),
            ),
          );
        },
      ),
    );
  }
}
