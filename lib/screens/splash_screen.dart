import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_team/screens/home.dart';
import '../routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashScreen(
        splash: const CustomSplashContent(),
        splashIconSize: 180.0,
        duration: 5000,
        nextScreen: const AuthCheckScreen(),
        splashTransition: SplashTransition.scaleTransition,
        pageTransitionType: PageTransitionType.bottomToTop,
        backgroundColor: Colors.black,
      ),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getString('userId');

    if (!mounted) return;

    if (isLoggedIn && userId != null && userId.isNotEmpty) {
      try {
        final profileLoaded = await fetchUserProfile(userId);

        if (!mounted) return;

        if (profileLoaded == true) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          await prefs.clear();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        }
      } catch (e) {
        await prefs.clear();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class CustomSplashContent extends StatefulWidget {
  const CustomSplashContent({super.key});

  @override
  State<CustomSplashContent> createState() => _CustomSplashContentState();
}

class _CustomSplashContentState extends State<CustomSplashContent> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Hero(
            tag: "logo",
            child: Image.asset('images/logonew.png', height: 150),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedOpacity(
          duration: const Duration(seconds: 1),
          opacity: _opacity,
          child: const Text(
            'Watch Team',
            style: TextStyle(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}