import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/distance_verification_service.dart';
import '../services/pharmacy_cache_service.dart';
import '../services/firebase_debug_util.dart';

/// A screen to verify the accuracy of pharmacy distance calculations
class PharmacyDebugScreen extends StatefulWidget {
  const PharmacyDebugScreen({super.key});

  @override
  State<PharmacyDebugScreen> createState() => _PharmacyDebugScreenState();
}

class _PharmacyDebugScreenState extends State<PharmacyDebugScreen> {
  bool _isLoading = false;
  String _statusMessage = "Ready to verify distances";
  List<Map<String, dynamic>> _pharmacies = [];
  Position? _userPosition;
  int _selectedMethodIndex = 0;

  final _calculationMethods = [
    {'name': 'All Methods (Compare)', 'value': -1},
    {
      'name': 'Geolocator (Default)',
      'value': CalculationMethod.geolocator.index
    },
    {'name': 'Haversine Formula', 'value': CalculationMethod.haversine.index},
    {'name': 'Vincenty Formula', 'value': CalculationMethod.vincenty.index},
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocationAndData();
  }

  /// Initialize location and pharmacy data
  Future<void> _initializeLocationAndData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Getting your location...";
    });

    try {
      await PharmacyCacheService.initializeCache();
      await _getCurrentLocation();
      await _loadPharmacies();
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = "Location services are disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = "Location permissions are denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = "Location permissions are permanently denied";
        });
        return;
      }

      // Get current position
      setState(() {
        _statusMessage = "Getting your precise location...";
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPosition = position;
        _statusMessage = "Location acquired, loading pharmacies...";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error getting location: $e";
      });
    }
  }

  /// Load all pharmacies from Firestore
  Future<void> _loadPharmacies() async {
    if (_userPosition == null) {
      setState(() {
        _statusMessage = "Cannot load pharmacies: Location not available";
      });
      return;
    }

    setState(() {
      _statusMessage = "Loading pharmacies...";
      _pharmacies = [];
    });

    try {
      // Get all pharmacies from Firestore
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('pharmacies').get();

      final pharmacyDocs = snapshot.docs;
      setState(() {
        _statusMessage = "Found ${pharmacyDocs.length} pharmacies";
      });

      final List<Map<String, dynamic>> pharmacyList = [];

      // Process each pharmacy
      for (final doc in pharmacyDocs) {
        final data = doc.data() as Map<String, dynamic>;

        // Skip if no location data
        if (data['location'] == null) continue;

        final location = data['location'] as GeoPoint;
        final name = data['name'] ?? 'Unknown Pharmacy';
        final address = data['address'] ?? 'No address';
        final id = doc.id;

        // Check for valid coordinates
        final bool hasValidCoordinates =
            (location.latitude != 0 || location.longitude != 0) &&
                (_userPosition!.latitude != location.latitude ||
                    _userPosition!.longitude != location.longitude);

        // Calculate distance with selected method
        final distanceInfo = await _calculatePharmacyDistance(
            location.latitude, location.longitude,
            isValid: hasValidCoordinates);

        pharmacyList.add({
          'id': id,
          'name': name,
          'address': address,
          'location': location,
          'distanceInfo': distanceInfo,
        });
      }

      // Sort by distance
      pharmacyList.sort((a, b) {
        final distanceA = a['distanceInfo']['average'] as double? ?? 0;
        final distanceB = b['distanceInfo']['average'] as double? ?? 0;
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _pharmacies = pharmacyList;
        _statusMessage =
            "Loaded ${_pharmacies.length} pharmacies with location data";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error loading pharmacies: $e";
      });
    }
  }

  /// Calculate distance between user and pharmacy using selected method
  Future<Map<String, dynamic>> _calculatePharmacyDistance(
      double pharmacyLat, double pharmacyLon,
      {bool isValid = true}) async {
    try {
      if (_userPosition == null) {
        return {
          'error': 'Location not available',
          'average': double.infinity,
        };
      }

      // Check if coordinates are valid
      if (!isValid ||
          (pharmacyLat == 0 && pharmacyLon == 0) ||
          (_userPosition!.latitude == pharmacyLat &&
              _userPosition!.longitude == pharmacyLon)) {
        debugPrint(
            '⚠️ Invalid coordinates for distance calculation: [$pharmacyLat,$pharmacyLon]');
        return {
          'error': 'Invalid coordinates',
          'average': -1,
          'displayDistance': 'Invalid coords',
          'geolocator': -1,
          'haversine': -1,
          'vincenty': -1,
          'confidence': 0,
          'confidenceText': 'Invalid',
        };
      }

      // If using comparison mode (-1), return all methods
      if (_calculationMethods[_selectedMethodIndex]['value'] == -1) {
        return await DistanceVerificationService
            .calculateDistanceWithMultipleMethods(
          startLat: _userPosition!.latitude,
          startLon: _userPosition!.longitude,
          endLat: pharmacyLat,
          endLon: pharmacyLon,
        );
      } else {
        // Otherwise use single selected method
        final method = CalculationMethod
            .values[_calculationMethods[_selectedMethodIndex]['value'] as int];
        final distance = await DistanceVerificationService.calculateDistance(
          startLat: _userPosition!.latitude,
          startLon: _userPosition!.longitude,
          endLat: pharmacyLat,
          endLon: pharmacyLon,
          method: method,
        );

        return {
          'average': distance,
          'displayDistance': _formatDistance(distance),
          'methodName': _calculationMethods[_selectedMethodIndex]['name'],
        };
      }
    } catch (e) {
      return {
        'error': e.toString(),
        'average': double.infinity,
      };
    }
  }

  /// Format distance for display
  String _formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else if (distanceKm < 10.0) {
      return '${distanceKm.toStringAsFixed(2)} km';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Recalculate all distances with the selected method
  void _recalculateDistances() {
    _loadPharmacies();
  }

  /// Show debug information for testing distance accuracy
  void _showDebugInfo() async {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available yet')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Running debug tests...';
    });

    try {
      // Select a pharmacy to test (first one in the list if available)
      final testPharmacy = _pharmacies.isNotEmpty ? _pharmacies[0] : null;

      if (testPharmacy == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pharmacies available to test')),
        );
        return;
      }

      final location = testPharmacy['location'] as GeoPoint;

      // Run the test
      final results = await FirebaseDebugUtil.verifyDistanceCalculation(
        startLat: _userPosition!.latitude,
        startLon: _userPosition!.longitude,
        endLat: location.latitude,
        endLon: location.longitude,
      );

      // Show the debug report in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Distance Verification Report'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pharmacy: ${testPharmacy['name']}'),
                  Text(
                      'Your coordinates: ${_userPosition!.latitude.toStringAsFixed(6)}, ${_userPosition!.longitude.toStringAsFixed(6)}'),
                  Text(
                      'Pharmacy coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'),
                  const Divider(),
                  Text(
                      'Geolocator distance: ${results['geolocator']?.toStringAsFixed(3)} km'),
                  Text(
                      'Haversine distance: ${results['haversine']?.toStringAsFixed(3)} km'),
                  Text(
                      'Vincenty distance: ${results['vincenty']?.toStringAsFixed(3)} km'),
                  const Divider(),
                  Text(
                      'Average distance: ${results['average']?.toStringAsFixed(3)} km'),
                  Text(
                      'Confidence score: ${results['confidence']} (${results['confidenceText']})'),
                  Text('Max difference: ${results['maxDifferenceKm']} km'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  DistanceVerificationService.openInGoogleMaps(
                    startLat: _userPosition!.latitude,
                    startLon: _userPosition!.longitude,
                    endLat: location.latitude,
                    endLon: location.longitude,
                  );
                },
                child: Text('Open in Maps'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running debug test: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Debug test completed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance Verification'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _isLoading ? null : _showDebugInfo,
            tooltip: 'Show debug info',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _recalculateDistances,
            tooltip: 'Refresh distances',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status message and method selector
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User location
                if (_userPosition != null)
                  Text(
                    'Your Location: ${_userPosition!.latitude.toStringAsFixed(6)}, ${_userPosition!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                // Status message
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Method selector
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Calculation Method',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMethodIndex,
                  items: List.generate(
                    _calculationMethods.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(_calculationMethods[index]['name'] as String),
                    ),
                  ),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMethodIndex = value;
                            });
                            _recalculateDistances();
                          }
                        },
                ),
              ],
            ),
          ),

          // Pharmacy list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pharmacies.isEmpty
                    ? const Center(
                        child: Text('No pharmacies found with location data'))
                    : ListView.builder(
                        itemCount: _pharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = _pharmacies[index];
                          final distanceInfo =
                              pharmacy['distanceInfo'] as Map<String, dynamic>;
                          final location = pharmacy['location'] as GeoPoint;

                          // Check if we're using comparison mode
                          final isComparisonMode =
                              _calculationMethods[_selectedMethodIndex]
                                      ['value'] ==
                                  -1;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: ExpansionTile(
                              title: Text(
                                pharmacy['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                isComparisonMode
                                    ? 'Avg: ${distanceInfo['displayDistance']} (${distanceInfo['confidenceText']})'
                                    : distanceInfo['displayDistance'] as String,
                              ),
                              trailing: isComparisonMode
                                  ? _buildConfidenceIndicator(
                                      distanceInfo['confidence'] as double)
                                  : null,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Address: ${pharmacy['address']}'),
                                      Text('ID: ${pharmacy['id']}'),
                                      Text(
                                        'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                      ),
                                      const Divider(),

                                      // Different UI based on calculation mode
                                      if (isComparisonMode) ...[
                                        Text(
                                          'Distance Calculations:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDistanceComparison(distanceInfo),
                                      ] else ...[
                                        Text(
                                          'Distance (${_calculationMethods[_selectedMethodIndex]['name']}): ${distanceInfo['displayDistance']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ],

                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.map),
                                        label:
                                            const Text('Open in Google Maps'),
                                        onPressed: () {
                                          DistanceVerificationService
                                              .openInGoogleMaps(
                                            startLat: _userPosition!.latitude,
                                            startLon: _userPosition!.longitude,
                                            endLat: location.latitude,
                                            endLon: location.longitude,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Build a comparison table for different distance calculation methods
  Widget _buildDistanceComparison(Map<String, dynamic> distanceInfo) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(
        color: Colors.grey.withOpacity(0.3),
        width: 1,
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Method',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Distance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Difference',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        _buildDistanceRow(
          'Geolocator',
          distanceInfo['geolocator'] as double,
          distanceInfo['average'] as double,
        ),
        _buildDistanceRow(
          'Haversine',
          distanceInfo['haversine'] as double,
          distanceInfo['average'] as double,
        ),
        _buildDistanceRow(
          'Vincenty',
          distanceInfo['vincenty'] as double,
          distanceInfo['average'] as double,
        ),
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Average',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _formatDistance(distanceInfo['average'] as double),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Max: ${distanceInfo['maxDifferenceKm']} km',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build a table row for distance comparison
  TableRow _buildDistanceRow(String method, double distance, double average) {
    final diff = ((distance - average) / average * 100).abs();
    final diffText = '${diff.toStringAsFixed(1)}%';

    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(method),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_formatDistance(distance)),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(diffText),
          ),
        ),
      ],
    );
  }

  /// Build a confidence indicator widget
  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    if (confidence >= 95) {
      color = Colors.green;
    } else if (confidence >= 80) {
      color = Colors.lightGreen;
    } else if (confidence >= 70) {
      color = Colors.amber;
    } else if (confidence >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${confidence.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
