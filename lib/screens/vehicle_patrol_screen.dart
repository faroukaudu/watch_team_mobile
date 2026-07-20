import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/global.dart' as g;
import 'package:watch_team/services/api_client.dart';
import 'package:watch_team/session_data.dart';

class VehiclePatrolScreen extends StatefulWidget {
  const VehiclePatrolScreen({super.key});

  @override
  State<VehiclePatrolScreen> createState() => _VehiclePatrolScreenState();
}

class _VehiclePatrolScreenState extends State<VehiclePatrolScreen> {
  final ApiClient api = ApiClient(baseUrl: g.baseUrl);
  final TextEditingController notesController = TextEditingController();
  Timer? timer;
  List<Map<String, dynamic>> patrols = [];
  Map<String, dynamic>? activePatrol;
  Map<String, dynamic>? activeSession;
  bool loading = true;
  bool saving = false;
  int elapsedSeconds = 0;
  int counter = 0;

  String get companyId => (SessionData.userProfile?['assignedCompanyID'] ?? '').toString();
  String get guardId => (SessionData.userProfile?['_id'] ?? '').toString();
  String get guardName => (SessionData.userProfile?['fullname'] ?? SessionData.userProfile?['username'] ?? 'Guard').toString();
  String get postSiteId => (SessionData.postSiteID ?? '').toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    timer?.cancel();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final items = await api.listVehiclePatrols(
        companyId: companyId,
        guardId: guardId,
        postSiteId: postSiteId,
      );
      Map<String, dynamic>? foundPatrol;
      Map<String, dynamic>? foundSession;
      for (final patrol in items) {
        if (patrol['activeSession'] is Map) {
          foundPatrol = patrol;
          foundSession = Map<String, dynamic>.from(patrol['activeSession'] as Map);
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        patrols = items;
        activePatrol = foundPatrol;
        activeSession = foundSession;
        counter = int.tryParse('${foundSession?['counter'] ?? 0}') ?? 0;
        notesController.text = (foundSession?['notes'] ?? '').toString();
        elapsedSeconds = _calculateElapsed(foundSession);
        loading = false;
      });
      _syncTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _message(_readError(e), error: true);
    }
  }

  int _calculateElapsed(Map<String, dynamic>? session) {
    if (session == null || session['startedAt'] == null) return 0;
    final started = DateTime.tryParse(session['startedAt'].toString())?.toLocal();
    if (started == null) return 0;
    final paused = int.tryParse('${session['totalPausedSeconds'] ?? 0}') ?? 0;
    final end = session['completedAt'] != null
        ? DateTime.tryParse(session['completedAt'].toString())?.toLocal()
        : DateTime.now();
    return ((end ?? DateTime.now()).difference(started).inSeconds - paused).clamp(0, 999999999).toInt();
  }

  void _syncTimer() {
    timer?.cancel();
    if (activeSession?['status'] == 'Active') {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => elapsedSeconds++);
      });
    }
  }

  String _duration(int value) {
    final h = (value ~/ 3600).toString().padLeft(2, '0');
    final m = ((value % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (value % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _readError(Object e) {
    final text = e.toString();
    if (text.contains('409')) return 'Complete your active patrol before starting another one.';
    return text.replaceFirst('Exception: ', '');
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB3261E) : const Color(0xFF123458),
      content: Text(text),
    ));
  }

  Future<void> _start(Map<String, dynamic> patrol) async {
    setState(() => saving = true);
    try {
      final result = await api.startVehiclePatrol(
        patrolId: patrol['_id'].toString(),
        companyId: companyId,
        guardId: guardId,
        guardName: guardName,
      );
      if (!mounted) return;
      setState(() {
        activePatrol = patrol;
        activeSession = Map<String, dynamic>.from(result['session'] as Map);
        elapsedSeconds = 0;
        counter = 0;
        notesController.clear();
      });
      _syncTimer();
      _message('Vehicle patrol started. The duration timer is now running.');
    } catch (e) {
      _message(_readError(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _update(String action) async {
    if (activePatrol == null || activeSession == null) return;
    setState(() => saving = true);
    try {
      final result = await api.updateVehiclePatrolSession(
        patrolId: activePatrol!['_id'].toString(),
        sessionId: activeSession!['_id'].toString(),
        companyId: companyId,
        guardId: guardId,
        action: action,
        counter: counter,
        notes: notesController.text.trim(),
      );
      if (!mounted) return;
      final session = Map<String, dynamic>.from(result['session'] as Map);
      setState(() {
        activeSession = session;
        elapsedSeconds = _calculateElapsed(session);
      });
      _syncTimer();
      if (action == 'complete' || action == 'cancel') {
        _message(action == 'complete' ? 'Patrol completed and submitted.' : 'Patrol cancelled.');
        await Future.delayed(const Duration(milliseconds: 350));
        await _load();
      }
    } catch (e) {
      _message(_readError(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _complete() async {
    final target = int.tryParse('${activePatrol?['targetCount'] ?? 1}') ?? 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF10243A),
        title: const Text('Complete patrol?', style: TextStyle(color: Colors.white)),
        content: Text(
          counter < target
              ? 'You recorded $counter of $target required activities. You can still submit, but the shortage will remain visible to management.'
              : 'Your duration, final counter and notes will be submitted to management.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Patrol')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Complete')),
        ],
      ),
    );
    if (confirmed == true) await _update('complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF06111D),
        foregroundColor: Colors.white,
        title: const Text('Vehicle Patrol'),
        actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  _hero(),
                  const SizedBox(height: 16),
                  if (activeSession != null && ['Active', 'Paused'].contains(activeSession!['status']))
                    _activePanel()
                  else
                    ..._availablePatrols(),
                ],
              ),
            ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF123458), Color(0xFF0A7185)]),
        boxShadow: const [BoxShadow(color: Color(0x4400C8FF), blurRadius: 28, offset: Offset(0, 14))],
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.directions_car_filled_rounded, color: Color(0xFF79ECFF)), SizedBox(width: 9), Text('VEHICLE OPERATIONS', style: TextStyle(color: Color(0xFF79ECFF), fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 11))]),
        SizedBox(height: 14),
        Text('Patrol with clarity.', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        SizedBox(height: 7),
        Text('No GPS is collected. Your patrol is documented using a live duration timer, activity counter and operational notes.', style: TextStyle(color: Colors.white70, height: 1.45)),
      ]),
    );
  }

  List<Widget> _availablePatrols() {
    if (patrols.isEmpty) {
      return [
        _glassCard(child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 34),
          child: Column(children: [Icon(Icons.route_rounded, color: Colors.white38, size: 44), SizedBox(height: 12), Text('No patrol option is available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)), SizedBox(height: 6), Text('An administrator must publish a Vehicle Patrol option for your post site.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))]),
        )),
      ];
    }
    return patrols.map((patrol) => Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: _glassCard(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Color(0xFF2B7FFF), Color(0xFF20D9FF)])), child: const Icon(Icons.local_taxi_rounded, color: Colors.white)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patrol['patrolName']?.toString() ?? 'Vehicle Patrol', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 4), Text('${patrol['postSiteName'] ?? 'Post Site'} • ${patrol['vehicleLabel'] ?? 'Patrol Vehicle'}', style: const TextStyle(color: Colors.white54))])),
          ]),
          const SizedBox(height: 15),
          Text((patrol['instructions'] ?? 'Follow the patrol instructions and use the counter for every completed activity.').toString(), style: const TextStyle(color: Colors.white70, height: 1.45)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _metric(Icons.add_task_rounded, '${patrol['targetCount'] ?? 1}', (patrol['counterLabel'] ?? 'Patrol rounds').toString())),
            const SizedBox(width: 10),
            Expanded(child: _metric(Icons.timer_outlined, '${patrol['expectedDurationMinutes'] ?? 30} min', 'Expected duration')),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saving ? null : () => _start(patrol), icon: const Icon(Icons.play_arrow_rounded), label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('START PATROL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .7))))),
        ]),
      )),
    )).toList();
  }

  Widget _activePanel() {
    final paused = activeSession?['status'] == 'Paused';
    final target = int.tryParse('${activePatrol?['targetCount'] ?? 1}') ?? 1;
    final progress = (counter / target).clamp(0.0, 1.0);
    return Column(children: [
      _glassCard(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: paused ? const Color(0xFFFFB74D) : const Color(0xFF39E58C), boxShadow: [BoxShadow(color: (paused ? const Color(0xFFFFB74D) : const Color(0xFF39E58C)).withOpacity(.5), blurRadius: 12)])),
            const SizedBox(width: 9),
            Text(paused ? 'PATROL PAUSED' : 'PATROL ACTIVE', style: TextStyle(color: paused ? const Color(0xFFFFC66D) : const Color(0xFF72F0B0), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
            const Spacer(),
            Text(DateFormat('h:mm a').format(DateTime.now()), style: const TextStyle(color: Colors.white38)),
          ]),
          const SizedBox(height: 22),
          Text(activePatrol?['patrolName']?.toString() ?? 'Vehicle Patrol', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(activePatrol?['vehicleLabel']?.toString() ?? 'Patrol Vehicle', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          Text(_duration(elapsedSeconds), style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w300, letterSpacing: 3)),
          const Text('LIVE PATROL DURATION', style: TextStyle(color: Color(0xFF79ECFF), fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 10)),
        ]),
      )),
      const SizedBox(height: 14),
      _glassCard(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ACTIVITY COUNTER', style: TextStyle(color: Color(0xFF79ECFF), fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 10)), const SizedBox(height: 5), Text(activePatrol?['counterLabel']?.toString() ?? 'Patrol rounds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17))])), Text('$counter / $target', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white10, color: const Color(0xFF20D9FF))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _counterButton(Icons.remove_rounded, counter > 0 ? () => setState(() => counter--) : null),
            Container(width: 112, alignment: Alignment.center, child: Text('$counter', style: const TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900))),
            _counterButton(Icons.add_rounded, () => setState(() => counter++)),
          ]),
          const Text('Tap + after each completed patrol activity', style: TextStyle(color: Colors.white38)),
        ]),
      )),
      const SizedBox(height: 14),
      _glassCard(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PATROL NOTES', style: TextStyle(color: Color(0xFF79ECFF), fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 10)),
          const SizedBox(height: 10),
          TextField(controller: notesController, minLines: 3, maxLines: 6, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Record vehicle condition, observations, issues or instructions followed...', hintStyle: const TextStyle(color: Colors.white30), filled: true, fillColor: Colors.black12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
        ]),
      )),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: saving ? null : () => _update(paused ? 'resume' : 'pause'), icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded), label: Text(paused ? 'RESUME' : 'PAUSE'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(onPressed: saving ? null : _complete, icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('COMPLETE'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF167D5A), padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
    ]);
  }

  Widget _metric(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.035), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.07))),
    child: Row(children: [Icon(icon, color: const Color(0xFF79ECFF), size: 20), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11))]))]),
  );

  Widget _counterButton(IconData icon, VoidCallback? onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(width: 60, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: onTap == null ? null : const LinearGradient(colors: [Color(0xFF2B7FFF), Color(0xFF20D9FF)]), color: onTap == null ? Colors.white10 : null), child: Icon(icon, color: Colors.white, size: 30)),
  );

  Widget _glassCard({required Widget child}) => Container(
    decoration: BoxDecoration(color: const Color(0xFF0D1E2F), borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0xFF1F4565)), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 12))]),
    child: child,
  );
}
