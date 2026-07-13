
import 'package:flutter/material.dart';

class SecurityColors {
  static const background = Color(0xFF070A0F);
  static const surface = Color(0xFF111720);
  static const surface2 = Color(0xFF18212D);
  static const border = Color(0xFF263445);
  static const primary = Color(0xFF19B5FE);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF35D07F);
  static const red = Color(0xFFFF4757);
  static const amber = Color(0xFFFFB020);
}

class SecurityPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const SecurityPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecurityColors.background,
      appBar: AppBar(
        backgroundColor: SecurityColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      body: child,
    );
  }
}

class SecuritySectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SecuritySectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SecurityColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.28),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
