import 'package:flutter/material.dart';
import 'screens/post_site.dart';
import 'screens/postsite_details.dart';

final GlobalKey<NavigatorState> postSiteNavigatorKey =
GlobalKey<NavigatorState>();

class PostSiteNavigator extends StatelessWidget {
  const PostSiteNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: postSiteNavigatorKey,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/':
            page = const PostSite();
            break;

          case '/postsite_details':
            page = PostsiteDetails();
            break;

          default:
            page = const PostSite();
        }

        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}