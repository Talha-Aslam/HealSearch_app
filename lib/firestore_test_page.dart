import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestPage extends StatefulWidget {
  const FirestoreTestPage({super.key});

  @override
  _FirestoreTestPageState createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _result;

  Future<void> _saveData() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });
    try {
      await FirebaseFirestore.instance.collection('test_collection').add({
        'value': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _result = 'Data saved successfully!';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Test Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter value to save'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveData,
                    child: Text('Save to Firestore'),
                  ),
            SizedBox(height: 20),
            if (_result != null) Text(_result!),
          ],
        ),
      ),
    );
  }
}
