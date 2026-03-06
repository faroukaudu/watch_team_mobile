import 'package:watch_team/session_data.dart';

class WorkedHoursService {
  /// Returns:
  /// {
  ///   "daily": Duration,
  ///   "weekly": Duration,
  ///   "byDay": Map<int, Duration> // Mon=0 … Sun=6
  /// }
  static Map<String, dynamic> calculate() {
    Duration daily = Duration.zero;
    Duration weekly = Duration.zero;
    Map<int, Duration> byDay = {};

    final company = SessionData.companyInfo;
    final guardId = SessionData.userProfile?['_id']?.toString();

    if (company == null || guardId == null || guardId.isEmpty) {
      return {
        "daily": daily,
        "weekly": weekly,
        "byDay": byDay,
      };
    }

    final checkedReport = (company['checkedReport'] as List?) ?? [];
    if (checkedReport.isEmpty) {
      return {
        "daily": daily,
        "weekly": weekly,
        "byDay": byDay,
      };
    }

    // 🔹 STEP 1: Find latest shift date for this guard
    DateTime? latestShiftDate;

    for (final rep in checkedReport) {
      if (rep['guardId']?.toString() != guardId) continue;

      final checkIn = _parseDate(rep['checkInTime']);
      if (checkIn == null) continue;

      if (latestShiftDate == null || checkIn.isAfter(latestShiftDate)) {
        latestShiftDate = checkIn;
      }
    }

    if (latestShiftDate == null) {
      return {
        "daily": daily,
        "weekly": weekly,
        "byDay": byDay,
      };
    }

    // 🔹 STEP 2: Build date windows from latest shift
    final dayStart = DateTime(
      latestShiftDate.year,
      latestShiftDate.month,
      latestShiftDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final weekStart =
    dayStart.subtract(Duration(days: dayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    // 🔹 STEP 3: Sum work time
    for (final rep in checkedReport) {
      if (rep['guardId']?.toString() != guardId) continue;

      final checkIn = _parseDate(rep['checkInTime']);
      if (checkIn == null) continue;

      final clockList = (rep['clock'] as List?) ?? [];
      for (final c in clockList) {
        final wt = _parseWorkTime(c['workTime']);

        // Daily (latest shift day)
        if (!checkIn.isBefore(dayStart) && checkIn.isBefore(dayEnd)) {
          daily += wt;
        }

        // Weekly (week of latest shift)
        if (!checkIn.isBefore(weekStart) && checkIn.isBefore(weekEnd)) {
          weekly += wt;
          final idx = checkIn.weekday - 1; // Mon = 0
          byDay[idx] = (byDay[idx] ?? Duration.zero) + wt;
        }
      }
    }

    return {
      "daily": daily,
      "weekly": weekly,
      "byDay": byDay,
    };
  }

  // ================== HELPERS ==================

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
  }

  static Duration _parseWorkTime(dynamic value) {
    if (value == null) return Duration.zero;

    final s = value.toString();
    if (!s.contains(':')) return Duration.zero;

    final parts = s.split('.');
    final hms = parts[0].split(':');
    if (hms.length != 3) return Duration.zero;

    return Duration(
      hours: int.tryParse(hms[0]) ?? 0,
      minutes: int.tryParse(hms[1]) ?? 0,
      seconds: int.tryParse(hms[2]) ?? 0,
    );
  }

  /// Optional formatting helper for UI
  static String formatHHMM(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return "$h:$m";
  }
}
