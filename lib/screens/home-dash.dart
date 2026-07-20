import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:watch_team/session_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../routes.dart';
import 'package:watch_team/services/worked_hours_service.dart';
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/global.dart' as g;
import 'dispatch_list_screen.dart';
import 'package:watch_team/screens/shifts/open_shift_screen.dart';
import 'package:watch_team/screens/schedule/availability_screen.dart';
import 'package:watch_team/screens/schedule/schedule_screen.dart';
import 'package:watch_team/screens/reminder_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);

  bool isTorchOn = false;
  bool loadingShiftStatus = false;
  int pendingShiftCount = 0;
  int confirmedShiftCount = 0;

  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    TorchLight.disableTorch();
    profile = SessionData.userProfile;
    loadShiftStatus();
  }

  Future<void> _enableTorch(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final available = await TorchLight.isTorchAvailable();

      if (!available) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Flashlight is not available on this device'),
          ),
        );
        return;
      }

      if (!isTorchOn) {
        await TorchLight.enableTorch();
        if (!mounted) return;
        setState(() {
          isTorchOn = true;
        });
      } else {
        await TorchLight.disableTorch();
        if (!mounted) return;
        setState(() {
          isTorchOn = false;
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Could not enable flashlight: $e'),
        ),
      );
    }
  }

  DateTime getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String get companyId {
    return (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
  }

  String get guardId {
    return (SessionData.userProfile?['_id'] ?? '').toString();
  }

  Future<void> loadShiftStatus() async {
    if (companyId.isEmpty || guardId.isEmpty) return;

    if (mounted) setState(() => loadingShiftStatus = true);

    try {
      final results = await Future.wait([
        api.listOpenShifts(companyId: companyId, guardId: guardId),
        api.getMySchedule(companyId: companyId, guardId: guardId),
      ]);

      final openShifts = results[0];
      final mySchedule = results[1];

      if (!mounted) return;
      setState(() {
        pendingShiftCount = openShifts.length;
        confirmedShiftCount = mySchedule.length;
      });
    } catch (e) {
      debugPrint('Home dashboard shift status error: $e');
    } finally {
      if (mounted) setState(() => loadingShiftStatus = false);
    }
  }

  Future<bool?> showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3558),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white70,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        height: 26,
                        width: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            "!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  "Confirm!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Do you want to logout?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE7EDF6),
                            foregroundColor: const Color(0xFF1B1F2A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "No",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Yes, Logout",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final worked = WorkedHoursService.calculate();

    final dailyText = formatHHMMSS(worked["daily"]);
    final weeklyText = formatHHMMSS(worked["weekly"]);
    final Map<int, Duration> byDay =
    Map<int, Duration>.from(worked["byDay"] ?? {});

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final ok = await showLogoutDialog(context);
        if (ok == true) {
          SessionData.userProfile = null;
          try {
            await TorchLight.disableTorch();
          } catch (_) {}

          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
                (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await loadShiftStatus();
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hours Worked',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      "Daily",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      dailyText,
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      "Weekly",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      weeklyText,
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Shift Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (loadingShiftStatus)
                                  const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      "Pending",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      pendingShiftCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      "Confirmed",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      confirmedShiftCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Card(
                      color: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: BarChart(
                          BarChartData(
                            groupsSpace: 5,
                            barTouchData: BarTouchData(enabled: true),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index > 6) {
                                      return const SizedBox.shrink();
                                    }

                                    final DateTime now = DateTime.now();
                                    final monday = getMonday(now);
                                    final DateTime date =
                                    monday.add(Duration(days: index));
                                    final label = DateFormat('MMM d').format(date);

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: _buildBarGroups(byDay),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.maxFinite,
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Color(0xFF222324),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                        bottom: Radius.circular(0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Table(
                        border: TableBorder(
                          horizontalInside:
                          BorderSide(color: Colors.grey.shade800),
                          verticalInside:
                          BorderSide(color: Colors.grey.shade800),
                        ),
                        children: [
                          TableRow(
                            children: [
                              IconsText(
                                iconType: Icons.event,
                                itemName: "Events",
                                onTap: () {
                                  Navigator.pushNamed(context, '/events');
                                },
                              ),
                              IconsText(
                                iconType: Icons.send_time_extension,
                                itemName: "Dispatch",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DispatchListScreen(),
                                    ),
                                  );
                                },
                              ),
                              const IconsText(
                                iconType: Icons.local_taxi,
                                itemName: "Vehicle Patrol",
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const IconsText(
                                iconType: Icons.policy,
                                itemName: "Docs & Policies",
                              ),
                              IconsText(
                                iconType: Icons.event_note,
                                itemName: "Schedule",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ScheduleScreen(),
                                    ),
                                  ).then((_) => loadShiftStatus());
                                },
                              ),
                              IconsText(
                                iconType: Icons.av_timer,
                                itemName: "Open Shifts",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const OpenShiftScreen(),
                                    ),
                                  ).then((_) => loadShiftStatus());
                                },
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _enableTorch(context);
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 5,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 8,
                                        ),
                                        height: 35,
                                        width: 35,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF123458),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isTorchOn
                                              ? Icons.flashlight_on
                                              : Icons.flashlight_off,
                                          color: isTorchOn
                                              ? Colors.deepOrange
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const Text(
                                        "Flash Light",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconsText(
                                iconType: Icons.nest_cam_wired_stand,
                                itemName: "Watch Mode",
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed('/watchmode');
                                },
                              ),
                              IconsText(
                                iconType: Icons.event_available,
                                itemName: "Availability",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const AvailabilityScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              IconsText(
                                iconType: Icons.alarm_rounded,
                                itemName: "Reminders",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReminderScreen(),
                                    ),
                                  );
                                },
                              ),
                              IconsText(
                                iconType: Icons.edit_document,
                                itemName: "Notes",
                                onTap: () {
                                  Navigator.pushNamed(context, '/notes');
                                },
                              ),
                              const SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatHHMMSS(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

List<BarChartGroupData> _buildBarGroups(Map<int, Duration> byDay) {
  final values = List.generate(7, (index) {
    final duration = byDay[index] ?? Duration.zero;
    return duration.inMinutes / 60.0;
  });

  return List.generate(values.length, (index) {
    return BarChartGroupData(
      x: index,
      barsSpace: 10,
      barRods: [
        BarChartRodData(
          toY: values[index],
          width: 18,
          borderRadius: BorderRadius.circular(2),
          color: Colors.deepOrangeAccent,
        ),
      ],
    );
  });
}

class IconsText extends StatelessWidget {
  final IconData iconType;
  final String itemName;
  final VoidCallback? onTap;

  const IconsText({
    super.key,
    required this.iconType,
    required this.itemName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                color: const Color(0xFF123458),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconType,
                color: Colors.white,
                size: 20,
              ),
            ),
            Text(
              itemName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _isTorchAvailable(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    return await TorchLight.isTorchAvailable();
  } on Exception catch (_) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Could not check if the device has an available torch'),
      ),
    );
    rethrow;
  }
}

Future<void> _disableTorch(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    await TorchLight.disableTorch();
  } on Exception catch (_) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Could not disable torch'),
      ),
    );
  }
}