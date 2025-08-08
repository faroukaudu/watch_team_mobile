import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/routes.dart';
// AIzaSyASbZIITafeYZViSsD0PqqPcUVaX_dabm8
// API KEY
void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(MyApp());
}
// Extend AppColors with dark theme values
class DarkAppColors {
  static const Color primary = Color(0xFF121212); // Dark surface
  static const Color secondary = Color(0xFFFFC107); // Amber (same)
  static const Color background = Color(0xFF1E1E1E); // Darker background
  static const Color textPrimary = Color(0xFFE0E0E0); // Light text
  static const Color textSecondary = Color(0xFFBDBDBD); // Gray text
}

// Define Custom Dark Theme
final ThemeData myDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: DarkAppColors.primary,
  scaffoldBackgroundColor: DarkAppColors.background,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkAppColors.primary,
    foregroundColor: Colors.white,
  ),
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
  ).copyWith(
    secondary: DarkAppColors.secondary,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: DarkAppColors.textPrimary, fontSize: 18),
    bodyMedium: TextStyle(color: DarkAppColors.textSecondary, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkAppColors.secondary,
      foregroundColor: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: myDarkTheme,
      debugShowCheckedModeBanner: false,
      title: 'Named Routes Demo',
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}