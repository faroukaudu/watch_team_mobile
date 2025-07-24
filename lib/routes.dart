import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    login: (context) => LoginScreen(),
    dashboard:(context) => DashBoardScreen(),
  };
}