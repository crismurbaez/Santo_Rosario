import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:santo_rosario/app.dart';
import 'package:santo_rosario/providers/audio_provider.dart';
import 'package:santo_rosario/services/alarm_notification_service.dart';
import 'package:santo_rosario/services/alarm_storage_service.dart';
import 'package:santo_rosario/services/rosary_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el servicio de audio en segundo plano
  final audioHandler = await AudioService.init(
    builder: () => RosaryAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.santo_rosario.channel.audio',
      androidNotificationChannelName: 'Reproducción del Rosario',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  try {
    await dotenv.load(fileName: 'assets/env/app.env');
  } catch (e, st) {
    debugPrint('[main] Sin app.env, intentando app.env.example: $e');
    debugPrint('$st');
    try {
      await dotenv.load(fileName: 'assets/env/app.env.example');
    } catch (e2) {
      debugPrint('[main] No se cargó ningún archivo de entorno: $e2');
    }
  }

  await AlarmNotificationService.instance.initialize(
    navigatorKey: appRootNavigatorKey,
  );

  // Sin permisos de notificación / alarmas (API 33+, 31+) el schedule falla o no muestra nada.
  await AlarmNotificationService.instance.requestRuntimePermissions();

  try {
    final alarms = await AlarmStorageService().loadAlarms();
    await AlarmNotificationService.instance.syncAll(alarms);
  } catch (e, st) {
    debugPrint('[main] Sync alarmas al arrancar: $e\n$st');
  }

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const SantoRosarioApp(),
    ),
  );
}

