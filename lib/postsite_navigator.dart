// post_site_navigator.dart
import 'package:flutter/material.dart';
import 'screens/post_site.dart';
import 'screens/postsite_details.dart';

class PostSiteNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/':
            page = PostSite(); // the main PostSite page
            break;
          case '/postsite_details':
            page = PostsiteDetails(); // the nested inner page
            break;
          default:
            page = PostSite();
        }

        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}
