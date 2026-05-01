import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:santo_rosario/models/app_error.dart';
import 'package:santo_rosario/services/preferences_service.dart';

class ErrorLogService {
  ErrorLogService({PreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? PreferencesService();

  final PreferencesService _preferencesService;

  /// Persiste la entrada para diagnóstico y la escribe en consola / device log (desarrollo).
  /// No muestra UI al usuario: los datos están pensados para el desarrollador.
  Future<void> logError(AppError error, {required String screen}) async {
    final payload = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'screen': screen,
      'kind': error.kind.name,
      'severity': error.severity.name,
      'userMessage': error.userMessage,
      'technicalMessage': error.technicalMessage ?? '',
    };
    final serialized = jsonEncode(payload);
    debugPrint('[AppErrorLog] $serialized');
    await _preferencesService.appendErrorLog(serialized);
  }

  Future<String> buildReportBody(AppError error, {required String screen}) async {
    final logs = await _preferencesService.getErrorLogs();
    final lastLogs = logs.length <= 10 ? logs : logs.sublist(logs.length - 10);
    final lines = <String>[
      'Pantalla: $screen',
      'Tipo: ${error.kind.name}',
      'Severidad: ${error.severity.name}',
      'Mensaje usuario: ${error.userMessage}',
      'Detalle técnico: ${error.technicalMessage ?? 'Sin detalle'}',
      '',
      'Ultimos logs registrados:',
      ...lastLogs,
    ];
    return lines.join('\n');
  }
}
