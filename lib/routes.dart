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
import 'package:watch_team/screens/notes_screen.dart';
import 'package:watch_team/screens/add_note_screen.dart';
import 'package:watch_team/screens/edit_note_screen.dart';
import 'package:watch_team/screens/events_screen.dart';
import 'package:watch_team/screens/dispatch_list_screen.dart';
import 'package:watch_team/screens/visitor_detail_screen.dart';
import 'package:watch_team/screens/visitor_list_screen.dart';
import 'package:watch_team/screens/add_visitor_screen.dart';

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
  static const String dispatch = '/dispatch';
  static const String visitor_detail_screen = '/visitor_detail_screen';
  static const String visitor_list_screen = '/visitor_list_screen';
  static const String add_visitor_screen = '/add_visitor_screen';



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

    '/notes': (context) => const NotesScreen(),
    '/add_note': (context) => const AddNoteScreen(),
    '/edit_note': (context) => const EditNoteScreen(),
    '/events': (context) => const EventsScreen(),
    dispatch: (context) => const DispatchListScreen(),
    visitor_detail_screen:(context) => const VisitorDetailScreen(visitor: {}),
    visitor_list_screen:(context) => const VisitorListScreen(postSiteId: '', postSiteName: ''),
    add_visitor_screen:(context) => const AddVisitorScreen(postSiteId: '', postSiteName: ''),


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