import 'package:flutter/material.dart';
import 'package:watch_team/screens/report/all_report.dart';
import 'package:watch_team/screens/report/select_report.dart';
import 'package:watch_team/screens/report/send_report.dart';
import 'screens/home.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard.dart';
import 'screens/postsite_details.dart';
import 'screens/scantag_screen.dart';
import 'screens/post_order_screen.dart';
import 'screens/chat_caller.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String postsite_details = '/postsite_details';
  static const String all_reports = '/all_report';
  static const String sel_reports = '/select_report';
  static const String send_reports = '/send_report';
  static const String scan_tags = '/scantag_screen';
  static const String post_order_screen = '/post_order_screen';
  static const String chat = '/chat_callert';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    login: (context) => LoginScreen(),
    dashboard:(context) => DashBoardScreen(),
    postsite_details:(context) => PostsiteDetails(),
    all_reports:(context) => AllReports(),
    sel_reports:(context) => SelectReportScreen(),
    post_order_screen:(context) => PostOrdersScreen(),
    scan_tags:(context) => ScanTagScreen(),
    chat:(context) => ChatUserListScreen(),



    send_reports: (context) {
      final args = ModalRoute
          .of(context)!
          .settings
          .arguments as Map<String, dynamic>;
      final title = (args['reportTitle'] ?? 'Report') as String;
      return ReportFormScreen(reportTitle: title);
    }

  };
}