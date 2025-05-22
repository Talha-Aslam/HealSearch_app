import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyMapScreen extends StatefulWidget {
  final String pharmacyName;
  final double latitude;
  final double longitude;
  final String medicineName;
  final String medicinePrice;
  final String medicineQuantity;

  const PharmacyMapScreen({
    Key? key,
    required this.pharmacyName,
    required this.latitude,
    required this.longitude,
    required this.medicineName,
    required this.medicinePrice,
    required this.medicineQuantity,
  }) : super(key: key);

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LatLng pharmacyLocation = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () => _openInGoogleMaps(pharmacyLocation),
            tooltip: 'Open in Google Maps',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Medicine info card
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.medicineName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.pharmacyName,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        Text(
                          widget.medicinePrice,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Available Quantity: ${widget.medicineQuantity}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Map area
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: pharmacyLocation,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.healsearch_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: pharmacyLocation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                widget.pharmacyName,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map navigation options - using Row to save vertical space
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _openInGoogleMaps(pharmacyLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Get Directions',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _showMapOptions(pharmacyLocation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        minimumSize: const Size(0, 40),
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Map Options',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps(LatLng location) async {
    // Create a Uri object directly instead of parsing a string
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');

    try {
      // Try to launch with the main Google Maps URL
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not launch Google Maps. Try other map options.')),
          );
          // Show the options dialog if direct launch fails
          _showMapOptions(location);
        }
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
        // Show the options dialog if exception occurs
        _showMapOptions(location);
      }
    }
  }

  void _showMapOptions(LatLng location) {
    final coordString = '${location.latitude},${location.longitude}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Google Maps (Web)'),
                leading: const Icon(Icons.public),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$coordString');
                  await launchUrl(url,
                      mode: LaunchMode.externalNonBrowserApplication);
                },
              ),
              ListTile(
                title: const Text('Google Maps Navigation'),
                leading: const Icon(Icons.directions),
                onTap: () async {
                  Navigator.pop(context);
                  final url =
                      Uri.parse('google.navigation:q=$coordString&mode=d');
                  await launchUrl(url,
                      mode: LaunchMode.externalNonBrowserApplication);
                },
              ),
              ListTile(
                title: const Text('Native Maps App'),
                leading: const Icon(Icons.map),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse('geo:$coordString');
                  await launchUrl(url,
                      mode: LaunchMode.externalNonBrowserApplication);
                },
              ),
              ListTile(
                title: const Text('Open in Browser'),
                leading: const Icon(Icons.open_in_browser),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$coordString');
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
