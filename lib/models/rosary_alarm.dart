import 'dart:convert';

/// Una alarma guardada: fecha y hora locales; puede repetirse cada semana.
class RosaryAlarm {
  const RosaryAlarm({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.repeatWeekly,
    this.enabled = true,
    this.openRosaryWithGuidedAudio = false,
  });

  final String id;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final bool repeatWeekly;
  final bool enabled;

  /// Si es true: al disparar la alarma la app va al rosario y arranca el audio guiado.
  final bool openRosaryWithGuidedAudio;

  /// Id estable para [FlutterLocalNotificationsPlugin.cancel] / `zonedSchedule`.
  int get notificationId => id.hashCode & 0x7fffffff;

  DateTime get anchorDate => DateTime(year, month, day);

  RosaryAlarm copyWith({
    String? id,
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    bool? repeatWeekly,
    bool? enabled,
    bool? openRosaryWithGuidedAudio,
  }) {
    return RosaryAlarm(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      enabled: enabled ?? this.enabled,
      openRosaryWithGuidedAudio:
          openRosaryWithGuidedAudio ?? this.openRosaryWithGuidedAudio,
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
        'enabled': enabled,
        'openRosaryWithGuidedAudio': openRosaryWithGuidedAudio,
      };

  static RosaryAlarm? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return RosaryAlarm(
        id: raw['id'] as String,
        year: raw['year'] as int,
        month: raw['month'] as int,
        day: raw['day'] as int,
        hour: raw['hour'] as int,
        minute: raw['minute'] as int,
        repeatWeekly: raw['repeatWeekly'] as bool? ?? false,
        enabled: raw['enabled'] as bool? ?? true,
        openRosaryWithGuidedAudio:
            raw['openRosaryWithGuidedAudio'] as bool? ?? false,
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
