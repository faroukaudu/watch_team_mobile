enum RepeatType {
  none,
  daily,
  weekly,
}

class GuardReminder {
  final int id;
  final String service;
  final String title;
  final String note;
  final DateTime scheduledAt;
  final String repeat;
  final bool enabled;

  const GuardReminder({
    required this.id,
    required this.service,
    required this.title,
    required this.note,
    required this.scheduledAt,
    required this.repeat,
    this.enabled = true,
  });



  GuardReminder copyWith({
    int? id,
    String? service,
    String? title,
    String? note,
    DateTime? scheduledAt,
    String? repeat,
    bool? enabled,
  }) {
    return GuardReminder(
      id: id ?? this.id,
      service: service ?? this.service,
      title: title ?? this.title,
      note: note ?? this.note,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
    );
  }

  DateTime? nextOccurrence([DateTime? from]) {
    if (!enabled) return null;

    final now = from ?? DateTime.now();

    if (repeat == 'None') {
      return scheduledAt.isAfter(now) ? scheduledAt : null;
    }

    if (repeat == 'Daily') {
      DateTime next = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledAt.hour,
        scheduledAt.minute,
      );

      if (next.isBefore(scheduledAt)) next = scheduledAt;
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      return next;
    }

    if (repeat == 'Weekly') {
      DateTime next = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledAt.hour,
        scheduledAt.minute,
      );

      final daysAhead = (scheduledAt.weekday - next.weekday + 7) % 7;
      next = next.add(Duration(days: daysAhead));

      if (next.isBefore(scheduledAt)) next = scheduledAt;
      if (!next.isAfter(now)) next = next.add(const Duration(days: 7));
      return next;
    }

    return scheduledAt.isAfter(now) ? scheduledAt : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service,
      'title': title,
      'note': note,
      'scheduledAt': scheduledAt.toIso8601String(),
      'repeat': repeat,
      'enabled': enabled,
    };
  }



  factory GuardReminder.fromJson(Map<String, dynamic> json) {
    return GuardReminder(
      id: int.tryParse('${json['id']}') ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      service: json['service']?.toString() ?? 'General',
      title: json['title']?.toString() ?? 'Reminder',
      note: json['note']?.toString() ?? '',
      scheduledAt: DateTime.tryParse('${json['scheduledAt']}') ?? DateTime.now(),
      repeat: json['repeat']?.toString() ?? 'None',
      enabled: json['enabled'] != false,
    );
  }
}
