import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:santo_rosario/models/rosary_alarm.dart';
import 'package:santo_rosario/services/alarm_notification_service.dart';
import 'package:santo_rosario/services/alarm_storage_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Requerido por [FlutterLocalNotificationsPlugin] para toques en segundo plano.
@pragma('vm:entry-point')
void alarmNotificationTapBackground(NotificationResponse response) async {
  if (response.actionId == AlarmNotificationService.actionSnooze) {
    // 1. Inicializar zonas horarias (necesario en el isolate de background)
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC); 
    }

    final id = AlarmNotificationService.parseNotificationIdFromPayload(response.payload);
    if (id == null) return;

    // 2. Cargar la alarma para saber qué reprogramar
    final alarms = await AlarmStorageService().loadAlarms();
    final alarm = alarms.cast<RosaryAlarm?>().firstWhere(
      (a) => a?.notificationId == id,
      orElse: () => null,
    );

    if (alarm != null) {
      // 3. Reprogramar en 10 minutos
      final now = tz.TZDateTime.now(tz.local);
      final snoozeTime = now.add(const Duration(minutes: 10));

      await AlarmNotificationService.instance.scheduleSnooze(
        id: id,
        when: snoozeTime,
        alarm: alarm,
      );
    }
  }
}
