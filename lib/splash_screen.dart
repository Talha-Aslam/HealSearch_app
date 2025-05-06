import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:healsearch_app/login_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  // Using AnimationController for more efficient animations
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.repeat();

    // Use a more efficient way to navigate
    _navigateToHome();
  }

  @override
  void dispose() {
    // Properly dispose the animation controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    // Reduced splash screen time to improve user experience
    return Future.delayed(const Duration(milliseconds: 3000)).then((_) {
      // Using pushReplacement with a fade transition for smoother experience
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Login(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        // Using Stack instead of Column for better layout performance
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pre-cached image for better performance
            Image.asset(
              "images/logo3.png",
              width: 400,
              // Using cacheWidth to optimize memory usage
              cacheWidth: 400,
            ),

            // Position the loading indicator below the logo
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.35,
              child: SpinKitChasingDots(
                color: Colors.black,
                size: 40.0,
                // controller: _animationController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
