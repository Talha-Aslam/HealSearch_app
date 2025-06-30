import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healsearch_app/splash_screen.dart';
import 'package:healsearch_app/login_screen.dart';
import 'package:healsearch_app/navbar.dart';

class AppStateManager extends StatefulWidget {
  const AppStateManager({super.key});

  @override
  State<AppStateManager> createState() => _AppStateManagerState();
}

class _AppStateManagerState extends State<AppStateManager> {
  bool _isLoading = true;
  bool _showSplash = true;
  Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if this is the first app launch
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('first_launch') ?? true;

      if (isFirstLaunch) {
        // First launch - show splash screen
        await prefs.setBool('first_launch', false);
        _showSplashThenProceed();
      } else {
        // Not first launch - check auth state and navigate directly
        _checkAuthAndNavigate();
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Fallback to splash screen
      _showSplashThenProceed();
    }
  }

  void _showSplashThenProceed() {
    setState(() {
      _showSplash = true;
      _isLoading = false;
    });

    // After splash screen duration, check auth state
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() {
    try {
      final user = FirebaseAuth.instance.currentUser;

      setState(() {
        _showSplash = false;
        _isLoading = false;

        if (user != null) {
          // User is logged in - go to main app
          _currentPage = const Navbar();
        } else {
          // User not logged in - go to login
          _currentPage = const Login();
        }
      });
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      // Fallback to login screen
      setState(() {
        _showSplash = false;
        _isLoading = false;
        _currentPage = const Login();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a minimal loading screen while determining app state
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showSplash) {
      return const Splash();
    }

    return _currentPage ?? const Login();
  }
}
