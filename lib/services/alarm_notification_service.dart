import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:santo_rosario/models/rosary_alarm.dart';
import 'package:santo_rosario/presentations/screens/alarm_ringing_screen.dart';
import 'package:santo_rosario/presentations/screens/pray_screen.dart';
import 'package:santo_rosario/services/alarm_background_handler.dart';
import 'package:santo_rosario/services/alarm_storage_service.dart';
import 'package:santo_rosario/utils/mystery_utils.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Programa y cancela notificaciones de alarma (Android / iOS).
class AlarmNotificationService {
  AlarmNotificationService._();
  static final AlarmNotificationService instance = AlarmNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  bool? _lastFullScreenIntentPermissionGranted;

  static const _channelId = 'rosario_alarm_v1';
  static const _channelName = 'Recordatorios del rosario';
  static const _channelDescription =
      'Alarmas para recordar el rezo del Santo Rosario.';

  static bool get supportsNativeSchedule =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String payloadFor(RosaryAlarm alarm) => 'alarm:${alarm.notificationId}';

  static int? parseNotificationIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('alarm:')) return null;
    return int.tryParse(payload.substring('alarm:'.length));
  }

  Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    if (_initialized) {
      _navigatorKey = navigatorKey;
      return;
    }
    _navigatorKey = navigatorKey;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final name = info.identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e, st) {
      debugPrint('[AlarmNotificationService] Zona horaria local no disponible: $e\n$st');
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: alarmNotificationTapBackground,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }

    _initialized = true;

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final id = parseNotificationIdFromPayload(
        launch!.notificationResponse?.payload,
      );
      if (id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_openAlarmFlow(id));
        });
      }
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final id = parseNotificationIdFromPayload(response.payload);
    if (id == null) return;
    unawaited(_openAlarmFlow(id));
  }

  /// Decide entre pantalla de alarma simple o rosario con audio guiado (según la alarma guardada).
  Future<void> _openAlarmFlow(int notificationId) async {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    RosaryAlarm? alarm;
    try {
      final list = await AlarmStorageService().loadAlarms();
      for (final a in list) {
        if (a.notificationId == notificationId) {
          alarm = a;
          break;
        }
      }
    } catch (e, st) {
      debugPrint('[AlarmNotificationService] No se pudieron cargar alarmas: $e\n$st');
    }

    if (alarm != null && alarm.openRosaryWithGuidedAudio) {
      await AlarmNotificationService.instance.cancelNotification(notificationId);
      final mystery =
          MysteryUtils.mysteryForWeekday(DateTime.now().weekday);
      if (!nav.mounted) return;
      await nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PrayScreen(
            mystery: mystery,
            launchFromAlarmAutoStartGuidedAudio: true,
          ),
        ),
      );
      return;
    }

    if (!nav.mounted) return;
    await nav.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlarmRingingScreen(notificationId: notificationId),
      ),
    );
  }

  /// Permisos de aviso (y en Android, alarmas exactas si aplica).
  Future<void> requestRuntimePermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      _lastFullScreenIntentPermissionGranted =
          await android?.requestFullScreenIntentPermission();
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == false) {
        await android?.requestExactAlarmsPermission();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Estado útil para explicar por qué una alarma puede no autoabrir el rosario.
  Future<AndroidAutoStartDiagnostic> getAndroidAutoStartDiagnostic() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const AndroidAutoStartDiagnostic(
        supportedPlatform: false,
        notificationsEnabled: true,
        exactAlarmAllowed: true,
        fullScreenIntentGranted: true,
      );
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notificationsEnabled = await android?.areNotificationsEnabled();
    final exactAllowed = await android?.canScheduleExactNotifications();
    return AndroidAutoStartDiagnostic(
      supportedPlatform: true,
      notificationsEnabled: notificationsEnabled ?? true,
      exactAlarmAllowed: exactAllowed ?? true,
      fullScreenIntentGranted: _lastFullScreenIntentPermissionGranted ?? false,
    );
  }

  Future<void> cancelAlarms(Iterable<RosaryAlarm> alarms) async {
    for (final a in alarms) {
      await _plugin.cancel(id: a.notificationId);
    }
  }

  Future<void> syncAll(List<RosaryAlarm> alarms) async {
    if (!supportsNativeSchedule) return;
    for (final a in alarms) {
      // Cancelar todas las posibles notificaciones asociadas a este ID (7 días + el original)
      await _plugin.cancel(id: a.notificationId);
      for (int i = 1; i <= 7; i++) {
        await _plugin.cancel(id: a.notificationIdForDay(i));
      }
    }
    for (final a in alarms) {
      if (a.enabled) {
        await _scheduleOne(a);
      }
    }
  }

  /// Para ordenar la lista por próxima activación (null al final si no programa).
  DateTime? nextFireAsDateTime(RosaryAlarm alarm) {
    final t = _nextFire(alarm);
    return t;
  }

  tz.TZDateTime? _nextFire(RosaryAlarm a) {
    final now = tz.TZDateTime.now(tz.local);
    if (a.repeatDaily) {
      var daily = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        a.hour,
        a.minute,
      );
      if (!daily.isAfter(now)) {
        daily = daily.add(const Duration(days: 1));
      }
      return daily;
    }
    if (a.daysOfWeek.isNotEmpty) {
      tz.TZDateTime? earliest;
      for (final day in a.daysOfWeek) {
        final occurrence = _nextWeeklyOccurrence(
          anchorWeekday: day,
          hour: a.hour,
          minute: a.minute,
          now: now,
        );
        if (earliest == null || occurrence.isBefore(earliest)) {
          earliest = occurrence;
        }
      }
      return earliest;
    }
    if (a.repeatWeekly) {
      return _nextWeeklyOccurrence(
        anchorWeekday: a.anchorDate.weekday,
        hour: a.hour,
        minute: a.minute,
        now: now,
      );
    }
    final once = tz.TZDateTime(
      tz.local,
      a.year,
      a.month,
      a.day,
      a.hour,
      a.minute,
    );
    if (!once.isAfter(now)) return null;
    return once;
  }

  /// Próxima ocurrencia del [weekday] (DateTime.monday..sunday = 1..7) a [hour]:[minute].
  tz.TZDateTime _nextWeeklyOccurrence({
    required int anchorWeekday,
    required int hour,
    required int minute,
    required tz.TZDateTime now,
  }) {
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var deltaDays = anchorWeekday - candidate.weekday;
    if (deltaDays < 0) deltaDays += 7;
    candidate = candidate.add(Duration(days: deltaDays));
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return const NotificationDetails(android: android, iOS: darwin);
  }

  Future<void> _scheduleOne(RosaryAlarm alarm) async {
    final now = tz.TZDateTime.now(tz.local);

    // Si es diaria o no tiene días específicos, usamos el ID original y el comportamiento previo.
    if (alarm.repeatDaily || (alarm.daysOfWeek.isEmpty && !alarm.repeatWeekly)) {
      final when = _nextFire(alarm);
      if (when == null) return;
      await _zonedScheduleInternal(
        id: alarm.notificationId,
        when: when,
        alarm: alarm,
        repeatDaily: alarm.repeatDaily,
        repeatWeekly: false,
      );
      return;
    }

    // Si tiene días específicos o es el antiguo semanal, programamos uno por cada día.
    final days = alarm.daysOfWeek.isNotEmpty
        ? alarm.daysOfWeek
        : [alarm.anchorDate.weekday];

    for (final day in days) {
      final when = _nextWeeklyOccurrence(
        anchorWeekday: day,
        hour: alarm.hour,
        minute: alarm.minute,
        now: now,
      );
      await _zonedScheduleInternal(
        id: alarm.notificationIdForDay(day),
        when: when,
        alarm: alarm,
        repeatDaily: false,
        repeatWeekly: true,
      );
    }
  }

  Future<void> _zonedScheduleInternal({
    required int id,
    required tz.TZDateTime when,
    required RosaryAlarm alarm,
    required bool repeatDaily,
    required bool repeatWeekly,
  }) async {
    AndroidScheduleMode androidMode = alarm.openRosaryWithGuidedAudio
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == false) {
        androidMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: androidMode,
        title: 'Santo Rosario',
        body: repeatDaily
            ? 'Hora del rosario (cada día)'
            : repeatWeekly
                ? 'Hora del rosario (cada semana)'
                : 'Recordatorio del rosario',
        payload: payloadFor(alarm),
        matchDateTimeComponents: repeatDaily
            ? DateTimeComponents.time
            : repeatWeekly
                ? DateTimeComponents.dayOfWeekAndTime
                : null,
      );
    } catch (e, st) {
      debugPrint('[AlarmNotificationService] Fallo zonedSchedule: $e\n$st');
      // Fallback a inexacto...
      if (defaultTargetPlatform == TargetPlatform.android &&
          (androidMode == AndroidScheduleMode.exactAllowWhileIdle ||
              androidMode == AndroidScheduleMode.alarmClock)) {
        try {
          await _plugin.zonedSchedule(
            id: id,
            scheduledDate: when,
            notificationDetails: _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: 'Santo Rosario',
            body: repeatDaily
                ? 'Hora del rosario (cada día)'
                : repeatWeekly
                    ? 'Hora del rosario (cada semana)'
                    : 'Recordatorio del rosario',
            payload: payloadFor(alarm),
            matchDateTimeComponents: repeatDaily
                ? DateTimeComponents.time
                : repeatWeekly
                    ? DateTimeComponents.dayOfWeekAndTime
                    : null,
          );
        } catch (_) {}
      }
    }
  }
}

class AndroidAutoStartDiagnostic {
  const AndroidAutoStartDiagnostic({
    required this.supportedPlatform,
    required this.notificationsEnabled,
    required this.exactAlarmAllowed,
    required this.fullScreenIntentGranted,
  });

  final bool supportedPlatform;
  final bool notificationsEnabled;
  final bool exactAlarmAllowed;
  final bool fullScreenIntentGranted;

  bool get canLikelyAutoOpen =>
      supportedPlatform &&
      notificationsEnabled &&
      exactAlarmAllowed &&
      fullScreenIntentGranted;
}
