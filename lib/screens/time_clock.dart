import 'dart:async';
import 'package:flutter/material.dart';
import '../server_push.dart';
import 'package:watch_team/session_data.dart';
import 'package:intl/intl.dart';

class TimeClock extends StatefulWidget {
  const TimeClock({super.key});

  @override
  State<TimeClock> createState() => _TimeClockState();
}

class _TimeClockState extends State<TimeClock> {
  Duration _elapsed = Duration.zero;   // work time
  Duration _teaBreak = Duration.zero;  // break time
  Duration _remaining = Duration.zero;  // selected shift remaining time
  Duration _overTime = Duration.zero;   // time worked after shift end


  Timer? _timer;        // work timer
  Timer? _breakTimer;   // break timer
  Timer? _remainingTimer; // shift countdown timer

  bool _isRunning = false; // currently counting work time
  bool _takeBreak = false;
  late String startClockTime;
  late String endClockTime;
  // currently on break


  DateTime? _todayShiftDateTime(String? timeText) {
    if (timeText == null || timeText.trim().isEmpty) return null;
    final parts = timeText.trim().split(":");
    if (parts.length < 2) return null;
    final now = DateTime.now();
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Duration _shiftDuration() {
    final shift = SessionData.selectedShift;
    if (shift == null) return Duration.zero;
    final start = _todayShiftDateTime(shift['startTime']?.toString());
    var end = _todayShiftDateTime(shift['endTime']?.toString());
    if (start == null || end == null) return Duration.zero;
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return end.difference(start);
  }

  void _refreshRemaining() {
    final duration = _shiftDuration();
    final left = duration - _elapsed;
    setState(() {
      _remaining = left.isNegative ? Duration.zero : left;
      _overTime = left.isNegative ? left.abs() : Duration.zero;
    });
  }

  bool _canClockInSelectedShift() {
    final shift = SessionData.selectedShift;
    if (shift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an open shift before clocking in.")),
      );
      return false;
    }
    final start = _todayShiftDateTime(shift['startTime']?.toString());
    if (start != null && DateTime.now().isBefore(start.subtract(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only clock in 1 hour before ${shift['startTime']}")),
      );
      return false;
    }
    return true;
  }

  // Start (Clock In): reset counters and begin work timer

  void notCheckedIn (){
    // debugPrint("not Checked In");
    print("Not checked IN");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Not Checked In", style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold
                )),
                SizedBox(height: 10),
                Center(child: Text("Kindly CheckIn before Clocking in.")),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.red),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                )
              ],
            ),
          ),
        );
      },
    );
  }
  void _startTimer() {
    if (_isRunning) return;
    DateTime now = DateTime.now();

    // Reset everything for a fresh session
    _timer?.cancel();
    _breakTimer?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _teaBreak = Duration.zero;
      _remaining = _shiftDuration();
      _overTime = Duration.zero;
      _takeBreak = false;
      _isRunning = true;
    });
    startClockTime = DateFormat('HH:mm:ss').format(now);
    print(startClockTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      _refreshRemaining();
    });

    _remainingTimer?.cancel();
    _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshRemaining();
    });
  }

  // Stop (Clock Out): stop all timers and freeze state
  void _stopTimer() async {
    _timer?.cancel();
    _breakTimer?.cancel();
    _remainingTimer?.cancel();
    DateTime stopNow = DateTime.now();
    // Capture results
    final work = _elapsed;
    final brk  = _teaBreak;
    final total = work + brk;
    final overtime = _overTime;
    endClockTime = DateFormat('HH:mm:ss').format(stopNow);

    // Build a readable message
    final msg =
        'Work: ${_formatDuration(work)} | Break: ${_formatDuration(brk)} | Total: ${_formatDuration(total)}';

    final msg2 = "Work Data Updated";

    // Print to console
    debugPrint(msg);
    await _sendData(work.toString(),brk.toString(),total.toString(), startClockTime.toString(),
    endClockTime.toString());

    // (Optional) show on screen too
    if (mounted) {

      // print("I have work here");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg2)));
    }

    setState(() {
      _isRunning = false;
      _takeBreak = false;
    });
  }

  // Toggle Break: pause/resume work and start/stop break counter
  void _pause() {
    if (_isRunning && !_takeBreak) {
      // ▶ Currently working -> go on break
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        _takeBreak = true;
      });
      _breakTimer?.cancel();
      _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _teaBreak += const Duration(seconds: 1));
      });
    } else if (_takeBreak && !_isRunning) {
      // ⏸ Currently on break -> end break and resume work
      _breakTimer?.cancel();
      setState(() {
        _takeBreak = false;
        _isRunning = true;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  // Sednign the button
  String _result = 'Press the button to send data';
  bool _loading = false;


  Future<void> _sendData(String work, String brk, String total, String startT, String stopT,) async {
    print("I am sedding state");
    print(work);
    print(brk);
    print(startT);
    print(stopT);
    setState(() {
      _loading = true;
      _result = 'Sending...';
    });

    try {
      // final response = await TimeClockPush.sendDataToServer(
      //   name: 'Michael',
      //   value: 42,
      // );
      final response = await TimeClockPush.sendDataToServer(checkedId: SessionData.checkID!,
          worktime: work, breaktime: brk,
          userData: SessionData.userProfile,
          companyData: SessionData.companyInfo,
          startTimer: startT,
          stopTimer: stopT,
        docId: SessionData.checkID!,


      );

      if(response['success'] == true){
        setState(() {
          SessionData.companyInfo = response['companyInfo'];
        });
      }



      setState(() {
        _result = 'Response from server:\n${response.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      print("We are doing finally Now?");
      setState(() {
        _loading = false;
      });
    }
  }



  @override
  void initState() {
    // TODO: implement initState
    //  checked = SessionData.clockedIn;

  }

  void dispose() {
    _timer?.cancel();
    _breakTimer?.cancel();
    _remainingTimer?.cancel();
    super.dispose();
  }

  void checker() {
    print("Break is ${_takeBreak}");
    print("Running is ${_isRunning}");
    print("Work elapsed: ${_elapsed.inSeconds}s, Break elapsed: ${_teaBreak.inSeconds}s");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Column(
        children: [
          // Top counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222324),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Work Hours",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(_formatDuration(_elapsed),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.deepOrange)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222324),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Break Hours",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(_formatDuration(_teaBreak),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Middle card (you can wire Remaining Time later)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF20a0e9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text("Current Time",
                              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_formatDuration(_elapsed),
                              style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Remaining Time",
                              style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_formatDuration(_remaining),
                              style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("Overtime: ${_formatDuration(_overTime)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ),
          const SizedBox(height: 15),

          // Action area
          _isRunning || _takeBreak
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Break toggle
              Expanded(
                child: GestureDetector(
                  onTap: _pause,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _takeBreak ? Colors.purple[900] : Colors.indigo[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_food_beverage, color: Colors.white),
                        Text(
                          _takeBreak ? " End Break" : " Take a Break",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Clock Out
              Expanded(
                child: GestureDetector(
                  onTap: _loading ? null : _stopTimer,

                  child: _loading ? const CircularProgressIndicator() : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.punch_clock, color: Colors.white),
                        Text(" Clock Out",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
              : GestureDetector(
            onLongPress: (){
              if (SessionData.clockedIn == true && _canClockInSelectedShift()) {
                _startTimer();
              } else {
                notCheckedIn();
              }

            }, // long-press to Clock In (or change to onTap)
            // onLongPress: notCheckedIn,
            onTap: (){
              print(SessionData.clockedIn);
              print(SessionData.companyInfo!['checkedReport']);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.timer_outlined, color: Colors.white),
                  Text(" Clock In",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
              child: Text("Time Log Entries", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, ),  )),
          const SizedBox(height: 5),

          Expanded(
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  // 1) Make sure companyInfo exists
                  final company = SessionData.companyInfo;
                  if (company == null) {
                    return const Text("No company info");
                  }

                  // 2) Get all reports as a list
                  final List<dynamic> allReportsDyn =
                      (company['checkedReport'] as List<dynamic>?) ?? <dynamic>[];

                  // 3) Get guardId from userProfile (correct: _id)
                  final String guardId =
                      SessionData.userProfile?['_id']?.toString() ?? '';

                  // 4) Filter reports for this guard
                  List<Map<String, dynamic>> reports = allReportsDyn
                      .where((r) {
                    final m = r as Map<String, dynamic>;
                    return (m['guardId'] ?? '').toString() == guardId;
                  })
                      .cast<Map<String, dynamic>>()
                      .toList();

                  // 5) Most recent reports first
                  reports = reports.reversed.toList();

                  if (reports.isEmpty) {
                    return const Text("Empty");
                  }

                  // 6) FLATTEN: one card per clock entry
                  final List<Widget> cards = [];

                  for (final report in reports) {
                    final List<dynamic> clocks =
                        (report['clock'] as List<dynamic>?) ?? <dynamic>[];

                    for (final c in clocks) {
                      final clock = c as Map<String, dynamic>;
                      cards.add(_buildClockCard(report, clock));
                    }
                  }

                  if (cards.isEmpty) {
                    return const Text("No clock entries");
                  }

                  return Column(children: cards);
                },
              ),
            ),
          )

        ],
      ),
    );
  }

  Divider divide() {
    return Divider(
                        thickness: 1,          // line thickness
                        color: Colors.white24,    // line color
                        height: 20,        // right spacing
                      );
  }

  Widget _buildTimeLogCard(Map<String, dynamic> report) {
    // 1) Basic fields from checkedReport
    final String dateOnly = _extractDate(report['checkInTime'] ?? '').toString();
    final String guardName   = (report['guardName'] ?? '').toString();
    final String checkInTime = (report['checkInTime'] ?? '').toString();
    final String postSiteId  = (report['postSite'] ?? '').toString();

    // 2) Resolve Post Site name from companyInfo.postSite list
    final String postSiteName = _getPostSiteName(postSiteId);


    // 3) Get last clock entry (you can change to first if you want)
    final List<dynamic> clocks = (report['clock'] ?? []) as List<dynamic>;
    Map<String, dynamic>? lastClock =
    clocks.isNotEmpty ? clocks.last as Map<String, dynamic> : null;

    final String clockInTime   = lastClock?['clockInTime']?.toString() ?? '';
    final String clockOutTime  = lastClock?['clockOutTime']?.toString() ?? '';
    final String workTime      = lastClock?['workTime']?.toString() ?? '';
    final String breakTime     = lastClock?['breakTime']?.toString() ?? '';

    final String work = _cleanDuration(workTime);
    final String brk  = _cleanDuration(breakTime);

    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 80, end: 0),         // 30px below → 0 (original position)
        duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),            // move up from 30 to 0
            child: Opacity(
              opacity: 1 - (value / 80),         // fade in while moving
              child: child,
            ),
          );
        },
        child: Container(
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Date",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateOnly, // or format this string into a nicer date
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            divide(),

            // Post Site row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Post Site",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  postSiteName,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            divide(),

            // Guard row (optional)
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     const Text(
            //       "Guard",
            //       style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            //     ),
            //     Text(
            //       guardName,
            //       style: const TextStyle(fontSize: 15),
            //     ),
            //   ],
            // ),
            // divide(),

            // Start Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Start Time",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  clockInTime,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            divide(),

            // End Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "End Time",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  clockOutTime,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            divide(),

            // Work Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Work Time",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  work,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            divide(),

            // Break Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Break Time",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  brk,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
  Widget _buildClockCard(
      Map<String, dynamic> report,
      Map<String, dynamic> clock,
      ) {
    // From checkedReport
    final String dateOnly   = _extractDate(report['checkInTime']?.toString() ?? '');
    final String guardName  = (report['guardName'] ?? '').toString();
    final String postSiteId = (report['postSite'] ?? '').toString();
    final String postSiteName = _getPostSiteName(postSiteId);

    // From clock entry
    final String clockInRaw   = clock['clockInTime']?.toString() ?? '';
    final String clockOutRaw  = clock['clockOutTime']?.toString() ?? '';
    final String workTimeRaw  = clock['workTime']?.toString() ?? '';
    final String breakTimeRaw = clock['breakTime']?.toString() ?? '';

    final String clockInTime  = _cleanClock(clockInRaw);
    final String clockOutTime = _cleanClock(clockOutRaw);
    final String work         = _cleanDuration(workTimeRaw);
    final String brk          = _cleanDuration(breakTimeRaw);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 80, end: 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1 - (value / 80),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header: Date + Post site
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Date",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateOnly,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              divide(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Post Site",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    postSiteName,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              divide(),

              // Optional: Guard row
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     const Text(
              //       "Guard",
              //       style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              //     ),
              //     Text(
              //       guardName,
              //       style: const TextStyle(fontSize: 15),
              //     ),
              //   ],
              // ),
              // divide(),

              // This clock entry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  // Text(
                  //   "Clock Entry",
                  //   style: TextStyle(
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.white70,
                  //   ),
                  // ),
                  // SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 4),

              // Start Time row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Start Time",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    clockInTime,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              divide(),

              // End Time row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "End Time",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    clockOutTime,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              divide(),

              // Work Time row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Work Time",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    work,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              divide(),

              // Break Time row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Break Time",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    brk,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _getPostSiteName(String postSiteId) {
    final List<dynamic> sites =
    (SessionData.companyInfo?['postSite'] ?? []) as List<dynamic>;

    for (final s in sites) {
      final site = s as Map<String, dynamic>;
      if (site['_id']?.toString() == postSiteId) {
        return (site['siteName'] ?? '').toString();
      }
    }

    return ''; // if not found
  }
}


String _extractDate(String fullDateTime) {
  if (fullDateTime.contains(" ")) {
    return fullDateTime.split(" ")[0];
  }
  return fullDateTime;
}

String _cleanDuration(String raw) {
  if (raw.isEmpty) return raw;

  // remove microseconds (.000000)
  String cleaned = raw.split(".").first;

  // cleaned is now like: "0:00:05" or "1:02:03"
  List<String> parts = cleaned.split(":");

  if (parts.length == 3) {
    String h = parts[0].padLeft(2, '0');
    String m = parts[1].padLeft(2, '0');
    String s = parts[2].padLeft(2, '0');
    return "$h:$m:$s";   // final output e.g. "00:00:05"
  }

  return cleaned;
}

String _cleanClock(String raw) {
  if (raw.isEmpty) return '--';
  return raw.split('.').first; // "04:51:19.000000" -> "04:51:19"
}



// [
// Container(
// margin: EdgeInsets.symmetric(vertical: 20.0),
// // color: Colors.grey,
// decoration: BoxDecoration(
// color: Colors.white12,
// borderRadius: BorderRadius.circular(12),
// ),
// child: Padding(
// padding: const EdgeInsets.all(20.0),
// child: Column(
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("Date", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("Thu, Nov 06, 2025", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("Post Site", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("Dakata...", style: TextStyle(fontSize: 15, ),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("Start Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("03:42", style: TextStyle(fontSize: 15, ),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("End Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("03:42", style: TextStyle(fontSize: 15, ),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("End Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("03:42", style: TextStyle(fontSize: 15, ),),
// ],
// )
//
// ],
// ),
// ),
// ),
// Container(
// // color: Colors.grey,
// decoration: BoxDecoration(
// color: Colors.white12,
// borderRadius: BorderRadius.circular(12),
// ),
// child: Padding(
// padding: const EdgeInsets.all(20.0),
// child: Column(
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("Date", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("Thu, Nov 06, 2025", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("Post Site", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("Dakata...", style: TextStyle(fontSize: 15, ),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("Start Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("03:42", style: TextStyle(fontSize: 15, ),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("End Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("03:42", style: TextStyle(fontSize: 15, ),),
// ],
// ),
// divide(),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text("End Time", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
// Text("03:42", style: TextStyle(fontSize: 15, ),),
// ],
// )
//
// ],
// ),
// ),
// ),
// ],