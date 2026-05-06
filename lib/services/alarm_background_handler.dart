import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Requerido por [FlutterLocalNotificationsPlugin] para toques en segundo plano.
/// El arranque en frío con la notificación se maneja con [getNotificationAppLaunchDetails].
@pragma('vm:entry-point')
void alarmNotificationTapBackground(NotificationResponse notificationResponse) {}
