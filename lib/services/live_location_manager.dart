import 'package:watch_team/session_data.dart';
import 'package:watch_team/global.dart' as g;
import 'live_location.dart';

class LiveLocationManager {
  LiveLocationManager._();

  static final LiveLocationService service = LiveLocationService();
  static bool _isLive = false;

  static Future<void> startLive() async {
    if (_isLive) return;

    final companyId = SessionData.userProfile?['assignedCompanyID'];
    final guardId   = SessionData.userProfile?['_id'];
    final guardName = SessionData.userProfile?['fullname'];

    if (companyId == null || guardId == null || guardName == null) return;

    await service.start(
      baseUrl: g.baseUrl.toString(),
      companyId: companyId.toString(),
      guardId: guardId.toString(),
      guardName: guardName.toString(),
    );

    _isLive = true;
  }

  static Future<void> stopLive() async {
    if (!_isLive) return;


    final companyId = SessionData.userProfile?['assignedCompanyID'];
    final guardId   = SessionData.userProfile?['_id'];

    if (companyId == null || guardId == null) {
      // still stop stream locally even if IDs are missing
      await service.stop(
        baseUrl: g.baseUrl.toString(),
        companyId: "",
        guardId: "",
      );
      _isLive = false;
      return;
    }

    await service.stop(
      baseUrl: g.baseUrl.toString(),
      companyId: companyId.toString(),
      guardId: guardId.toString(),
    );

    _isLive = false;
  }
}
