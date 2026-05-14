import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SnackBarUtils {
  /// Muestra una notificación de éxito (azul traslúcido, icono check).
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppHomeColors.switchActiveGradientTop.withValues(alpha: 0.9),
      duration: const Duration(milliseconds: 2200),
    );
  }

  /// Muestra una notificación de error (rojo suave, icono alerta).
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      backgroundColor: Colors.red.shade400.withValues(alpha: 0.95),
      duration: const Duration(seconds: 4),
    );
  }

  /// Muestra una notificación informativa en la parte superior (cerca de la barra de acciones).
  static void showTopInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppHomeColors.titleText.withValues(alpha: 0.85),
      duration: const Duration(seconds: 3),
      isTop: true,
    );
  }

  /// Muestra una notificación informativa (gris/oscuro traslúcido, icono info).
  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    _show(
      context,
      message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppHomeColors.titleText.withValues(alpha: 0.85),
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    bool isTop = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Ocultar la actual para que la nueva sea inmediata
    messenger.hideCurrentSnackBar();
    
    // Calcular el margen para posicionar arriba si es necesario
    // 80 es una altura aproximada para quedar cerca de la AppBar
    final margin = isTop
        ? EdgeInsets.only(
            bottom: mediaQuery.size.height - mediaQuery.padding.top - 120,
            left: 16,
            right: 16,
          )
        : const EdgeInsets.fromLTRB(16, 0, 16, 24);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        // Bordes más redondeados tipo píldora
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // Margen para que no toque los bordes y parezca flotar más alto
        margin: margin,
        elevation: 6,
      ),
    );
  }
}
