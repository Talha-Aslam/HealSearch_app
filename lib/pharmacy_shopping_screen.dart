import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../Models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/pharmacy_search_service.dart';
import '../firebase_database.dart';
import '../pharmacy_map_screen_fixed.dart';

class PharmacyShoppingScreen extends StatefulWidget {
  final String pharmacyName;
  final CartItem? initialItem; // The medicine clicked from search
  final double? pharmacyLatitude;
  final double? pharmacyLongitude;

  const PharmacyShoppingScreen({
    Key? key,
    required this.pharmacyName,
    this.initialItem,
    this.pharmacyLatitude,
    this.pharmacyLongitude,
  }) : super(key: key);

  @override
  State<PharmacyShoppingScreen> createState() => _PharmacyShoppingScreenState();
}

class _PharmacyShoppingScreenState extends State<PharmacyShoppingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CartService _cartService = CartService();
  List<Map<String, dynamic>> _availableMedicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializePharmacyShopping();
  }

  Future<void> _initializePharmacyShopping() async {
    // Set current pharmacy in cart service
    _cartService.setCurrentPharmacy(widget.pharmacyName);

    // Add initial item to cart if provided
    if (widget.initialItem != null) {
      _cartService.addToCart(widget.initialItem!);
    }

    // Load medicines from this pharmacy
    await _loadPharmacyMedicines();
  }

  Future<void> _loadPharmacyMedicines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user position for search
      var position = await Flutter_api().getPosition();

      // Search for medicines specifically from this pharmacy
      var medicines = await PharmacySearchService.searchNearbyMedicines(
        userPosition: position,
        searchQuery: null, // Get all medicines
        pharmacyName: widget.pharmacyName, // Filter by pharmacy
      );

      setState(() {
        _availableMedicines = medicines;
        _filteredMedicines = medicines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show dummy data for this pharmacy
      _loadDummyDataForPharmacy();
    }
  }

  void _loadDummyDataForPharmacy() {
    // Filter dummy data by pharmacy name
    final dummyData = [
      {
        "Name": "Paracetamol 500mg",
        "Category": "Pain Relief",
        "Description": "Pain reliever and fever reducer",
        "Price": "Rs. 25.50",
        "Quantity": 150,
        "StoreName": widget.pharmacyName,
        "Distance": "0.5",
        "Expire": "2025-12-31",
        "id": "dummy_1_${widget.pharmacyName}",
      },
      {
        "Name": "Vitamin C 1000mg",
        "Category": "Supplements",
        "Description": "Immune system booster",
        "Price": "Rs. 85.00",
        "Quantity": 75,
        "StoreName": widget.pharmacyName,
        "Distance": "0.5",
        "Expire": "2026-03-15",
        "id": "dummy_2_${widget.pharmacyName}",
      },
      {
        "Name": "Cough Syrup",
        "Category": "Respiratory",
        "Description": "Relief from cough and cold",
        "Price": "Rs. 120.00",
        "Quantity": 40,
        "StoreName": widget.pharmacyName,
        "Distance": "0.5",
        "Expire": "2025-10-20",
        "id": "dummy_3_${widget.pharmacyName}",
      },
    ];

    setState(() {
      _availableMedicines = dummyData;
      _filteredMedicines = dummyData;
    });
  }

  void _searchMedicines(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredMedicines = _availableMedicines;
      } else {
        _filteredMedicines = _availableMedicines
            .where((medicine) =>
                medicine["Name"]
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                medicine["Category"]
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addToCart(Map<String, dynamic> medicine) {
    final cartItem = CartItem.fromMap(medicine);
    _cartService.addToCart(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicine["Name"]} added to cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _checkout() async {
    final cartItems = _cartService.currentCartItems;
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    // Show checkout confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pharmacy: ${widget.pharmacyName}'),
            const SizedBox(height: 8),
            Text('Total Items: ${_cartService.totalItemsCount}'),
            Text(
                'Total Amount: Rs. ${_cartService.totalPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Do you want to place this order?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    try {
      // Get user location for delivery
      var position = await Flutter_api().getPosition();
      var address =
          await Flutter_api().getAddress(position.latitude, position.longitude);

      // Prepare order data
      final orderData = {
        'pharmacyName': widget.pharmacyName,
        'items':
            _cartService.currentCartItems.map((item) => item.toMap()).toList(),
        'totalAmount': _cartService.totalPrice,
        'deliveryAddress': address,
        'customerLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'orderTime': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Here you would typically send this to your backend/Firebase
      // For now, we'll show a success message
      print('Order placed: $orderData');

      // Clear cart
      _cartService.clearCurrentCart();

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed Successfully!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Your order has been sent to ${widget.pharmacyName}'),
              const SizedBox(height: 8),
              const Text('You will receive a confirmation call shortly.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to search screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () {
              if (widget.pharmacyLatitude != null &&
                  widget.pharmacyLongitude != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyMapScreen(
                      pharmacyName: widget.pharmacyName,
                      latitude: widget.pharmacyLatitude!,
                      longitude: widget.pharmacyLongitude!,
                      medicineName: '',
                      medicinePrice: '',
                      medicineQuantity: '',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.location_on),
            tooltip: 'Show Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchMedicines,
              decoration: InputDecoration(
                hintText: 'Search medicines in ${widget.pharmacyName}',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchMedicines('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.background,
              ),
            ),
          ),

          // Medicine List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMedicines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? 'No medicines found for your search'
                                  : 'No medicines available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMedicines.length,
                        itemBuilder: (context, index) {
                          final medicine = _filteredMedicines[index];
                          final isInCart =
                              _cartService.isInCart(medicine["id"]);
                          final quantity =
                              _cartService.getItemQuantity(medicine["id"]);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  Icons.medication,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                medicine["Name"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(medicine["Description"]),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          medicine["Category"],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stock: ${medicine["Quantity"]}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    medicine["Price"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isInCart)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'In Cart ($quantity)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () => _addToCart(medicine),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                      ),
                                      child: const Text(
                                        'Add to Cart',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Cart Summary
          AnimatedBuilder(
            animation: _cartService,
            builder: (context, child) {
              final itemCount = _cartService.totalItemsCount;
              final totalPrice = _cartService.totalPrice;

              if (itemCount == 0) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$itemCount items in cart',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Total: Rs. ${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _checkout,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
