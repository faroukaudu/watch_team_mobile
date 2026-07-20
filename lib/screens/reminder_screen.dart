import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_team/models/guard_reminder.dart';
import 'package:watch_team/services/reminder_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const List<String> services = <String>[
    'Events',
    'Dispatch',
    'Vehicle Patrol',
    'Parking Manager',
    'Schedule',
    'Open Shifts',
    'Watch Mode',
    'Availability',
    'Time Clock',
    'Reports',
    'Site Tours',
    'Checklists',
    'Tasks',
    'Notes',
    'Visitors',
    'Passdown',
    'DAR',
    'Post Orders',
    'Messenger',
    'Docs & Policies',
    'General Duty',
  ];

  List<GuardReminder> reminders = <GuardReminder>[];
  bool loading = true;
  bool saving = false;
  Timer? _ticker;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await ReminderService.loadReminders();
    items.sort((a, b) {
      final aNext = a.nextOccurrence(now);
      final bNext = b.nextOccurrence(now);
      if (aNext == null && bNext == null) return 0;
      if (aNext == null) return 1;
      if (bNext == null) return -1;
      return aNext.compareTo(bNext);
    });

    if (!mounted) return;
    setState(() {
      reminders = items;
      loading = false;
    });
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? const Color(0xFFB42318) : const Color(0xFF0E7490),
        content: Text(message),
      ),
    );
  }

  Future<void> _createReminder() async {
    String selectedService = services.first;
    String repeat = 'None';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(minutes: 5)),
    );

    final titleController = TextEditingController();
    final noteController = TextEditingController();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final scheduledAt = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .92,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF081724),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF22D3EE),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(
                                Icons.add_alarm_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Create Guard Reminder',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Choose a Watch Team service and alarm time.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(false),
                              icon: const Icon(Icons.close, color: Colors.white60),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedService,
                          dropdownColor: const Color(0xFF102538),
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                            'Purpose / App Service',
                            Icons.apps_rounded,
                          ),
                          items: services
                              .map(
                                (service) => DropdownMenuItem<String>(
                                  value: service,
                                  child: Text(service),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => selectedService = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(
                            'Alarm title *',
                            Icons.title_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: noteController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(
                            'Instructions or note',
                            Icons.notes_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _pickerTile(
                                icon: Icons.calendar_month_rounded,
                                label: 'Date',
                                value: DateFormat('EEE, MMM d, yyyy')
                                    .format(selectedDate),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: sheetContext,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 3650)),
                                  );
                                  if (date != null) {
                                    setSheetState(() => selectedDate = date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _pickerTile(
                                icon: Icons.schedule_rounded,
                                label: 'Time',
                                value: selectedTime.format(sheetContext),
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: sheetContext,
                                    initialTime: selectedTime,
                                  );
                                  if (time != null) {
                                    setSheetState(() => selectedTime = time);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: repeat,
                          dropdownColor: const Color(0xFF102538),
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                            'Repeat alarm',
                            Icons.repeat_rounded,
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'None',
                              child: Text('Do not repeat'),
                            ),
                            DropdownMenuItem(
                              value: 'Daily',
                              child: Text('Repeat every day'),
                            ),
                            DropdownMenuItem(
                              value: 'Weekly',
                              child: Text('Repeat every week'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() => repeat = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2232),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1B4055)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFF67E8F9),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  '${DateFormat('EEEE, MMM d').format(scheduledAt)} at '
                                  '${DateFormat('h:mm a').format(scheduledAt)}'
                                  '${repeat == 'None' ? '' : ' • $repeat'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) {
                                _message('Enter an alarm title.', error: true);
                                return;
                              }

                              if (repeat == 'None' &&
                                  !scheduledAt.isAfter(DateTime.now())) {
                                _message(
                                  'Choose a future date and time.',
                                  error: true,
                                );
                                return;
                              }

                              Navigator.of(sheetContext).pop(true);
                            },
                            icon: const Icon(Icons.alarm_add_rounded),
                            label: const Text('Set Reminder'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
          },
        );
      },
    );

    if (created != true) return;

    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final reminder = GuardReminder(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      service: selectedService,
      title: titleController.text.trim(),
      note: noteController.text.trim(),
      scheduledAt: scheduledAt,
      repeat: repeat,
    );

    setState(() => saving = true);
    try {
      await ReminderService.addReminder(reminder);
      await _load();
      _message('Reminder scheduled successfully.');
    } catch (error) {
      _message('Could not schedule reminder: $error', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteReminder(GuardReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1A29),
        title: const Text(
          'Delete reminder?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '“${reminder.title}” will be removed and its alarm cancelled.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ReminderService.deleteReminder(reminder.id);
    await _load();
    _message('Reminder deleted.');
  }

  String _countdown(GuardReminder reminder) {
    final next = reminder.nextOccurrence(now);
    if (next == null) return 'Completed';

    final duration = next.difference(now);
    if (duration.isNegative) return 'Due now';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}h '
          '${minutes.toString().padLeft(2, '0')}m';
    }

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06111D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Guard Reminders'),
        actions: <Widget>[
          // Test button
          FilledButton(
            onPressed: () async {
              await ReminderService.testAlarmSound();
            },
            child: const Text('Test alarm sound'),
          ),

          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saving ? null : _createReminder,
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text(
          'New Reminder',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: <Widget>[
          if (loading)
            const Center(child: CircularProgressIndicator())
          else
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: <Color>[
                          Color(0xFF123458),
                          Color(0xFF0A7185),
                        ],
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x3300C8FF),
                          blurRadius: 26,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF79ECFF),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SMART DUTY ALARMS',
                              style: TextStyle(
                                color: Color(0xFF79ECFF),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Never miss a duty.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Create multiple alarms for Watch Team services. '
                          'Each reminder can sound, vibrate, repeat, and show '
                          'a live countdown.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Your alarms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102538),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${reminders.length} total',
                          style: const TextStyle(
                            color: Color(0xFF67E8F9),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (reminders.isEmpty)
                    _emptyState()
                  else
                    ...reminders.map(_reminderCard),
                ],
              ),
            ),
          if (saving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C2A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF20394D)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.alarm_off_rounded, size: 48, color: Colors.white30),
          SizedBox(height: 12),
          Text(
            'No reminder created',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap New Reminder to schedule your first duty alarm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(GuardReminder reminder) {
    final next = reminder.nextOccurrence(now);
    final active = reminder.enabled && next != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C2A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active ? const Color(0xFF1B4055) : const Color(0xFF24313D),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0EA5E9).withOpacity(.14)
                      : Colors.white.withOpacity(.06),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  color: active ? const Color(0xFF67E8F9) : Colors.white38,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white54,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: reminder.enabled,
                          activeColor: const Color(0xFF22D3EE),
                          onChanged: (value) async {
                            await ReminderService.setEnabled(reminder, value);
                            await _load();
                          },
                        ),
                      ],
                    ),
                    Text(
                      reminder.service,
                      style: const TextStyle(
                        color: Color(0xFF67E8F9),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    if (reminder.note.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        reminder.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF081621),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'NEXT ALARM',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        next == null
                            ? 'No upcoming alarm'
                            : DateFormat('EEE, MMM d • h:mm a').format(next),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: <Color>[
                              Color(0xFF0E7490),
                              Color(0xFF1D4ED8),
                            ],
                          )
                        : null,
                    color: active ? null : const Color(0xFF263541),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _countdown(reminder),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              Icon(
                reminder.repeat == 'None'
                    ? Icons.looks_one_rounded
                    : Icons.repeat_rounded,
                size: 17,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                reminder.repeat == 'None'
                    ? 'One-time alarm'
                    : 'Repeats ${reminder.repeat.toLowerCase()}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Delete reminder',
                onPressed: () => _deleteReminder(reminder),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFF87171),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF102538),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF203B50)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF67E8F9), size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: const Color(0xFF67E8F9)),
      filled: true,
      fillColor: const Color(0xFF102538),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF203B50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF22D3EE)),
      ),
    );
  }
}
