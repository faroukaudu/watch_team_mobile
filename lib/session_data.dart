// lib/session_data.dart
class SessionData {
  static Map<String, dynamic>? userProfile;
  static Map<String, dynamic>? companyInfo;
  static String? token;
  static String? checkID;
  static bool? clockedIn;
  static String? postSiteID;

  static void clear() {
    userProfile = null;
    companyInfo = null;
    token = null;
    clockedIn = false;
    checkID = null;
    postSiteID = null;

  }
}