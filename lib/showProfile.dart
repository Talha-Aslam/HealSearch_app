import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healsearch_app/firebase_database.dart';

class ShowProfile extends StatefulWidget {
  const ShowProfile({super.key});

  @override
  State<ShowProfile> createState() => _ShowProfileState();
}

class _ShowProfileState extends State<ShowProfile> {
  final Flutter_api _api = Flutter_api();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userData = await _api.getUserData();

      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color.fromARGB(255, 190, 82, 15),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_userData == null) {
      return const Center(child: Text('No profile data found'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: (_userData?['profileImage'] != null &&
                        (_userData?['profileImage'] as String).isNotEmpty)
                    ? Image.network(
                        _userData!['profileImage'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        cacheHeight: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "Images/man.png",
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        "Images/man.png",
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                'Name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(_userData?['name'] ?? 'Not available'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text(
                'Email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(_userData?['email'] ?? 'Not available'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(_userData?['phoneNumber'] ??
                  _userData?['phNo'] ??
                  'Not available'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 190, 82, 15),
            ),
            child: const Text('Back to Profile',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                )),
          ),
        ],
      ),
    );
  }
}
