import 'package:flutter/material.dart';
import '../services/firestore_setup_helper.dart';
import '../services/medicine_search_service.dart';
import '../services/location_service.dart';

class SetupTestScreen extends StatefulWidget {
  const SetupTestScreen({super.key});

  @override
  State<SetupTestScreen> createState() => _SetupTestScreenState();
}

class _SetupTestScreenState extends State<SetupTestScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Search Setup & Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Setup Sample Data for Testing',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will create sample pharmacies and medicine inventory data in Firestore for testing the medicine search feature.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _setupSampleData,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Setup Sample Data'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _clearSampleData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Sample Data'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testLocationPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Location Permissions'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testMedicineSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Medicine Search'),
            ),
            
            const SizedBox(height: 20),
            
            const Divider(),
            
            const Text(
              'Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _statusMessage.isEmpty ? 'No operations performed yet.' : _statusMessage,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupSampleData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up sample data...\n';
    });

    try {
      await FirestoreSetupHelper.setupSampleData();
      await FirestoreSetupHelper.printCollectionStats();
      
      setState(() {
        _statusMessage += 'Sample data setup completed successfully!\n';
        _statusMessage += 'You can now test the medicine search feature.\n';
      });
    } catch (e) {
      setState(() {
        _statusMessage += 'Error setting up sample data: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSampleData() async {
    setState(() {
      _isLoading = true;
      _statusMessage += 'Clearing sample data...\n';
    });

    try {
      await FirestoreSetupHelper.clearSampleData();
      
      setState(() {
        _statusMessage += 'Sample data cleared successfully!\n';
      });
    } catch (e) {
      setState(() {
        _statusMessage += 'Error clearing sample data: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocationPermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage += 'Testing location permissions...\n';
    });

    try {
      final position = await LocationService.getCurrentPosition();
      
      if (position != null) {
        setState(() {
          _statusMessage += 'Location permission granted!\n';
          _statusMessage += 'Current location: ${position.latitude}, ${position.longitude}\n';
          _statusMessage += 'Accuracy: ${position.accuracy} meters\n';
        });
      } else {
        setState(() {
          _statusMessage += 'Location permission denied or location unavailable.\n';
          _statusMessage += 'Please enable location services and grant permission.\n';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage += 'Error testing location: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testMedicineSearch() async {
    setState(() {
      _isLoading = true;
      _statusMessage += 'Testing medicine search...\n';
    });

    try {
      // Test search for a common medicine
      final results = await MedicineSearchService.searchMedicinesNearby(
        medicineName: 'Paracetamol',
      );
      
      setState(() {
        _statusMessage += 'Search completed!\n';
        _statusMessage += 'Found ${results.length} results for "Paracetamol"\n';
        
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          _statusMessage += '\n${i + 1}. ${result.pharmacyName}\n';
          _statusMessage += '   Medicine: ${result.medicineName}\n';
          _statusMessage += '   Price: ₹${result.price}\n';
          _statusMessage += '   Stock: ${result.stockQuantity} ${result.unit}\n';
          _statusMessage += '   Distance: ${result.formattedDistance}\n';
        }
          if (results.isEmpty) {
          _statusMessage += 'No results found. Make sure:\n';
          _statusMessage += '1. Sample data is set up\n';
          _statusMessage += '2. Location permission is granted\n';
          _statusMessage += '3. Sample pharmacy locations exist in database\n';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage += 'Error testing medicine search: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
