import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard.dart';
import 'screens/postsite_details.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String postsite_details = '/postsite_details';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    login: (context) => LoginScreen(),
    dashboard:(context) => DashBoardScreen(),
    postsite_details:(context) => PostsiteDetails()
  };
}