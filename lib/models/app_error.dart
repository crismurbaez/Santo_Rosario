enum ErrorSeverity { info, warning, error }

enum ErrorKind { audio, image, data, ui, unknown }

class AppError {
  const AppError({
    required this.kind,
    required this.severity,
    required this.userMessage,
    this.technicalMessage,
  });

  final ErrorKind kind;
  final ErrorSeverity severity;
  final String userMessage;
  final String? technicalMessage;
}
