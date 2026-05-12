import 'dart:convert';

enum AlarmType { guidedAudio, fullScreenAlarm, notificationOnly }

/// Una alarma guardada: fecha y hora locales; puede repetirse cada día o semana.
class RosaryAlarm {
  const RosaryAlarm({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    this.repeatWeekly = false,
    this.repeatDaily = false,
    this.daysOfWeek = const [],
    this.enabled = true,
    this.alarmType = AlarmType.fullScreenAlarm,
  });

  final String id;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final bool repeatWeekly;
  final bool repeatDaily;
  final List<int> daysOfWeek;
  final bool enabled;

  /// Tipo de comportamiento al activarse.
  final AlarmType alarmType;

  /// Para compatibilidad con código anterior.
  bool get openRosaryWithGuidedAudio => alarmType == AlarmType.guidedAudio;

  /// Id estable para [FlutterLocalNotificationsPlugin.cancel] / `zonedSchedule`.
  /// Si hay varios días, se usa un ID derivado para cada uno.
  int get notificationId => id.hashCode & 0x7fffffff;

  int notificationIdForDay(int weekday) {
    return (id.hashCode ^ weekday).hashCode & 0x7fffffff;
  }

  DateTime get anchorDate => DateTime(year, month, day);

  RosaryAlarm copyWith({
    String? id,
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    bool? repeatWeekly,
    bool? repeatDaily,
    List<int>? daysOfWeek,
    bool? enabled,
    AlarmType? alarmType,
  }) {
    return RosaryAlarm(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabled: enabled ?? this.enabled,
      alarmType: alarmType ?? this.alarmType,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'minute': minute,
        'repeatWeekly': repeatWeekly,
        'repeatDaily': repeatDaily,
        'daysOfWeek': daysOfWeek,
        'enabled': enabled,
        'alarmType': alarmType.name,
      };

  static RosaryAlarm? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      final repeatWeekly = raw['repeatWeekly'] as bool? ?? false;
      final daysOfWeekRaw = raw['daysOfWeek'] as List<dynamic>?;
      List<int> daysOfWeek = daysOfWeekRaw?.cast<int>() ?? [];

      // Migración: si era semanal y no tiene días, añadir el día de la fecha de anclaje
      if (repeatWeekly && daysOfWeek.isEmpty) {
        final y = raw['year'] as int;
        final m = raw['month'] as int;
        final d = raw['day'] as int;
        daysOfWeek = [DateTime(y, m, d).weekday];
      }

      // Manejo de la migración del tipo de alarma
      AlarmType type = AlarmType.fullScreenAlarm;
      if (raw['alarmType'] != null) {
        type = AlarmType.values.byName(raw['alarmType'] as String);
      } else if (raw['openRosaryWithGuidedAudio'] == true) {
        type = AlarmType.guidedAudio;
      }

      return RosaryAlarm(
        id: raw['id'] as String,
        year: raw['year'] as int,
        month: raw['month'] as int,
        day: raw['day'] as int,
        hour: raw['hour'] as int,
        minute: raw['minute'] as int,
        repeatWeekly: repeatWeekly,
        repeatDaily: raw['repeatDaily'] as bool? ?? false,
        daysOfWeek: daysOfWeek,
        enabled: raw['enabled'] as bool? ?? true,
        alarmType: type,
      );
    } catch (_) {
      return null;
    }
  }

  static List<RosaryAlarm> decodeList(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .whereType<RosaryAlarm>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<RosaryAlarm> alarms) {
    return jsonEncode(alarms.map((e) => e.toJson()).toList());
  }
}
