// lib/session_data.dart
class SessionData {
  static Map<String, dynamic>? userProfile;
  static Map<String, dynamic>? companyInfo;
  static String? token;
  static String? checkID;

  /// Kept for compatibility with existing screens. It means checked in,
  /// not necessarily actively clocked in.
  static bool? clockedIn;
  static String? postSiteID;
  static Map<String, dynamic>? selectedShift;
  static Map<String, dynamic>? activeSession;

  static bool get isCheckedIn => activeSession?['checkedIn'] == true;
  static bool get isActivelyClockedIn => activeSession?['clockedIn'] == true;
  static String? get activePostSiteId => activeSession?['postSiteId']?.toString();

  static bool isActiveAtPost(String? postSiteId) {
    return postSiteId != null &&
        postSiteId.isNotEmpty &&
        activePostSiteId == postSiteId;
  }

  static bool isActiveAtAnotherPost(String? postSiteId) {
    return activeSession != null && !isActiveAtPost(postSiteId);
  }

  static void applyActiveSession(dynamic rawSession) {
    if (rawSession is Map) {
      activeSession = Map<String, dynamic>.from(rawSession);
      checkID = activeSession?['reportId']?.toString();
      clockedIn = activeSession?['checkedIn'] == true;
      final shift = activeSession?['selectedShift'];
      if (shift is Map) {
        selectedShift = Map<String, dynamic>.from(shift);
      }
    } else {
      activeSession = null;
      checkID = null;
      clockedIn = false;
    }
  }

  static void clearAuthentication() {
    userProfile = null;
    companyInfo = null;
    token = null;
    postSiteID = null;
    selectedShift = null;
    activeSession = null;
    checkID = null;
    clockedIn = false;
  }

  static void clear() => clearAuthentication();
}
