
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:watch_team/screens/home.dart';
import '../routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Home")),
      body: AnimatedSplashScreen(
            splash: CustomSplashContent(),
            splashIconSize: 180.0,
            duration: 5000,
            nextScreen: LoginScreen(),
            splashTransition: SplashTransition.scaleTransition,
            pageTransitionType: PageTransitionType.bottomToTop,
            backgroundColor: Colors.black,
        ),

    );
  }
}

class CustomSplashContent extends StatefulWidget {
  const CustomSplashContent({super.key});

  @override
  _CustomSplashContentState createState() => _CustomSplashContentState();
}

class _CustomSplashContentState extends State<CustomSplashContent> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Delay the fade-in of the text
    Future.delayed(Duration(seconds: 2), () {
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
            child:Hero(
              tag: "logo",
                child: Image.asset('images/logonew.png', height: 150)
            ),
        ),
        SizedBox(height: 20),
        AnimatedOpacity(
          duration: Duration(seconds: 1),
          opacity: _opacity,
          child: Text(
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


