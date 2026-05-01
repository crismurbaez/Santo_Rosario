import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:santo_rosario/models/app_error.dart';

/// Fallo explícito al enviar el reporte (mensaje pensado para el usuario o logs).
class ErrorReporterException implements Exception {
  ErrorReporterException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Envío del informe de error al desarrollador por HTTP POST.
///
/// Variables en [dotenv] (archivo cargado desde `assets/env/app.env`):
///
/// **`ERROR_REPORT_PROVIDER`**
/// - `emailjs` (por defecto): usa la API pública de [EmailJS](https://www.emailjs.com/docs/rest-api/send/).
/// - `webhook`: POST JSON a [ERROR_REPORT_URL] (p. ej. tu backend con SendGrid).
/// - `none`: deshabilita el envío (útil en builds sin credenciales).
///
/// **EmailJS:** `EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`, `EMAILJS_PUBLIC_KEY`
/// (y opcional `EMAILJS_PRIVATE_KEY` / `accessToken` si tu cuenta lo requiere).
///
/// El template de EmailJS debe usar las variables `subject`, `message`, `to_email`,
/// `user_message`, `technical` (o mapear las que envíes en [template_params]).
///
/// **Webhook:** `ERROR_REPORT_URL`, opcional `ERROR_REPORT_BEARER_TOKEN` (header Bearer).
class ErrorReporter {
  ErrorReporter({http.Client? httpClient}) : _httpClient = httpClient;

  final http.Client? _httpClient;

  static const String developerEmail = 'cristinalauramurguia@gmail.com';
  static const String subjectPrefix = '[App Rosario]';

  static const Duration _timeout = Duration(seconds: 25);

  static const String _emailJsEndpoint =
      'https://api.emailjs.com/api/v1.0/email/send';

  http.Client _client() => _httpClient ?? http.Client();

  /// Asunto fijo solicitado por producto (`[App Rosario]`).
  String emailSubject(AppError _) => subjectPrefix;

  String _composeFullBody(String reportBody, StackTrace? stackTrace) {
    final b = StringBuffer(reportBody)
      ..writeln()
      ..writeln('---')
      ..writeln('App: Santo Rosario')
      ..writeln('Plataforma: ${defaultTargetPlatform.name}')
      ..writeln('Modo debug: $kDebugMode');

    if (stackTrace != null) {
      b
        ..writeln()
        ..writeln('Stack trace capturado:')
        ..writeln(stackTrace);
    }
    return b.toString();
  }

  /// POST del reporte. Lanza [ErrorReporterException] si falla configuración,
  /// red o respuesta HTTP no exitosa.
  Future<void> submitReport({
    required AppError error,
    required String screen,
    required String reportBody,
    StackTrace? stackTrace,
  }) async {
    final composed = _composeFullBody(reportBody, stackTrace);
    final provider =
        dotenv.env['ERROR_REPORT_PROVIDER']?.trim().toLowerCase() ?? 'emailjs';

    debugPrint('[ErrorReporter] provider=$provider destino=$developerEmail');

    switch (provider) {
      case 'none':
      case 'off':
      case 'disabled':
        throw ErrorReporterException(
          'El envío está desactivado (ERROR_REPORT_PROVIDER).',
        );
      case 'webhook':
      case 'http':
      case 'sendgrid_backend':
      case 'custom':
        await _postWebhook(
          error: error,
          screen: screen,
          composedBody: composed,
        );
        return;
      case 'emailjs':
      default:
        await _postEmailJs(
          error: error,
          composedBody: composed,
        );
        return;
    }
  }

  Future<void> _postEmailJs({
    required AppError error,
    required String composedBody,
  }) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID']?.trim();
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID']?.trim();
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY']?.trim();
    final privateKey = dotenv.env['EMAILJS_PRIVATE_KEY']?.trim();

    if (serviceId == null ||
        serviceId.isEmpty ||
        templateId == null ||
        templateId.isEmpty ||
        publicKey == null ||
        publicKey.isEmpty) {
      throw ErrorReporterException(
        'Falta EmailJS en app.env (EMAILJS_SERVICE_ID, EMAILJS_TEMPLATE_ID, EMAILJS_PUBLIC_KEY).',
      );
    }

    final subject = emailSubject(error);
    final payload = <String, dynamic>{
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': <String, String>{
        'to_email': developerEmail,
        'subject': subject,
        'message': composedBody,
        'user_message': error.userMessage,
        'technical': error.technicalMessage ?? '',
      },
    };

    if (privateKey != null && privateKey.isNotEmpty) {
      payload['accessToken'] = privateKey;
    }

    final client = _client();
    try {
      final response = await client
          .post(
            Uri.parse(_emailJsEndpoint),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ErrorReporterException(
          'No se pudo enviar el correo (${response.statusCode}). ${response.body}',
        );
      }
    } on ErrorReporterException {
      rethrow;
    } catch (e, st) {
      debugPrint('[ErrorReporter] EmailJS $e\n$st');
      throw ErrorReporterException(
        'Fallo de red al enviar: ${e.toString()}',
      );
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> _postWebhook({
    required AppError error,
    required String screen,
    required String composedBody,
  }) async {
    final urlStr = dotenv.env['ERROR_REPORT_URL']?.trim();
    final bearer = dotenv.env['ERROR_REPORT_BEARER_TOKEN']?.trim() ?? '';

    if (urlStr == null || urlStr.isEmpty) {
      throw ErrorReporterException(
        'Define ERROR_REPORT_URL en app.env para el modo webhook.',
      );
    }

    final uri = Uri.tryParse(urlStr);
    if (uri == null || !uri.hasScheme) {
      throw ErrorReporterException('ERROR_REPORT_URL no es válida.');
    }

    final payload = <String, dynamic>{
      'to': developerEmail,
      'subject': emailSubject(error),
      'text': composedBody,
      'screen': screen,
      'errorKind': error.kind.name,
      'severity': error.severity.name,
      'userMessage': error.userMessage,
      'technicalMessage': error.technicalMessage,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (bearer.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearer';
    }

    final client = _client();
    try {
      final response = await client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ErrorReporterException(
          'El servidor respondió ${response.statusCode}: ${response.body}',
        );
      }
    } on ErrorReporterException {
      rethrow;
    } catch (e, st) {
      debugPrint('[ErrorReporter] webhook $e\n$st');
      throw ErrorReporterException(
        'Fallo de red al enviar: ${e.toString()}',
      );
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }
}
