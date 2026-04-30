# Reporte de cambios implementados (Pantalla del Rosario)

Fecha: 2026-04-30  
Proyecto: `santo_rosario`  
Alcance: estilos de `PrayScreen`, botones glass, navbar, menú emergente, mensajes de ayuda/estado/error, tamaño intermedio de rosa/brillo.

---

## 1) Resumen ejecutivo

Se implementó una actualización completa de experiencia visual y mensajería en la pantalla del rosario (`PrayScreen`), con estos ejes:

1. **UI glassmorphism** para navbar y botones.
2. **Menú de audio unificado** con el mismo estilo glass.
3. **Control granular de mensajes de ayuda**: cada mensaje puede desactivarse de forma individual.
4. **Mensajes de estado movidos al área superior** (sin tapar el botón inferior).
5. **Errores siempre visibles + reporte para desarrollador** con persistencia de logs locales.
6. **Nuevo tamaño intermedio** entre `basic` y `large` para `rosa` y `brillo`.

---

## 2) Archivos modificados y propósito

## `lib/presentations/screens/pray_screen.dart`

### Qué se cambió
- Reestilizado del `AppBar` para efecto glass:
  - `extendBodyBehindAppBar: true`
  - `AppBar` transparente con `BackdropFilter` + degradé + borde.
  - tipografía y color de título/subtítulo ajustados al diseño.
- Se reemplazaron botones `ElevatedButton` por botones custom glass:
  - botón circular (`_prayGlassRoundButton`)
  - botón pastilla (`_prayGlassPillButton`)
- El botón inferior se configuró para:
  - ocupar el ancho útil de su fila (con `LayoutBuilder`)
  - tener la **misma altura que los botones redondos** (`AppPrayGlass.roundButtonSize`)
  - usar color de texto dorado igual al título del diálogo de oración.
- El ícono de info del botón inferior se igualó al color del texto.
- Menú hamburguesa:
  - se reemplazó `PopupMenuButton` por `showMenu` + panel custom glass (`_prayGlassAudioMenuPanel`).
  - se mantuvo compatibilidad con la versión de Flutter en uso (sin `barrierColor`).
- Mensajería:
  - se eliminó uso de `SnackBar` para ayudas/estado.
  - se añadieron overlays superiores:
    - ayuda (con desactivación individual)
    - info temporal
    - error (siempre visible hasta cerrar)
- Errores:
  - botón para “Enviar al desarrollador” en banner de error.
  - diálogo de reporte con opción de copiar al portapapeles.

### Funciones nuevas/ajustadas relevantes
- `_showPrayGlassAudioMenu()`
- `_prayGlassAudioMenuPanel(...)`
- `_prayGlassRoundButton(...)`
- `_prayGlassPillButton(...)`
- `_buildHelpMessageQueueOnce()`
- `_dismissActiveHelpMessage(...)`
- `_showTopInfoMessage(...)`
- `_showErrorReportDialog()`
- `_reportError(...)` (ahora también registra logs)
- `_showAudioStatusMessage()` (reemplazo de snackbar de audio)

---

## `lib/constants/app_constants.dart`

### Qué se cambió
- Se creó/amplió `AppPrayGlass` con constantes de estilo glass:
  - blur, tamaños, radios, tintes, bordes, colores de texto.
- Se agregaron constantes para personalizar iconos del menú de audio:
  - `menuIconMusic`
  - `menuIconPrayers`
- Se añadió tamaño intermedio de rosario:
  - `AppRosarySizes.medium`
- Se agregaron claves de preferencias/logs:
  - `helpMessageDismissedPrefix`
  - `errorLogs`

### Impacto
- Centraliza personalización visual.
- Evita “números mágicos” distribuidos por pantalla.

---

## `lib/services/preferences_service.dart`

### Qué se cambió
- Nuevas APIs para mensajes de ayuda por id:
  - `isHelpMessageDismissed(messageId)`
  - `setHelpMessageDismissed(messageId, dismissed)`
- Nuevas APIs para logs locales de error:
  - `getErrorLogs()`
  - `appendErrorLog(serializedLog)` (con tope de 200 entradas)

### Impacto
- Persistencia de preferencias por mensaje (granular).
- Base de datos local simple para diagnóstico de fallos.

---

## `lib/services/error_log_service.dart` (archivo nuevo)

### Qué se implementó
- Servicio dedicado para errores:
  - serializa y guarda errores con metadatos (`timestamp`, pantalla, tipo, severidad, mensaje usuario/técnico).
  - construye cuerpo de reporte con últimos logs para enviar soporte.

### Métodos
- `logError(AppError error, {required String screen})`
- `buildReportBody(AppError error, {required String screen})`

### Impacto
- Aísla lógica de logging y reporte.
- Facilita migración futura a backend (Crashlytics/Sentry/API propia).

---

## `lib/presentations/widgets/rosary_painter.dart`

### Qué se cambió
- Se agregó tamaño intermedio:
  - `imageWidthMedium`
  - `imageHeightMedium`
- Se incorporó soporte de `AppRosarySizes.medium` en:
  - cálculo de tamaño para cuentas
  - posición/espaciado en extensión
  - tamaño del `brillo` para cuentas `medium`

### Escalado implementado
- `basic`: `radius * 0.20`
- `medium`: `radius * 0.32`  **(nuevo)**
- `large`: `radius * 0.50`
- `largest`: existente (según orientación)

### Impacto
- Mejor diferenciación visual de `rosa` respecto de `perla`.
- Ajuste fino sin saltar directamente de `basic` a `large`.

---

## `lib/data/models/data.dart`

### Qué se cambió
- Las cuentas `rosa` que estaban en `basic` pasaron a `medium`:
  - en el círculo principal
  - en la extensión

### Impacto
- El cambio de tamaño intermedio se usa de forma real en el rosario actual.

---

## 3) Sistema de mensajes: diseño final

## Tipos de mensaje
1. **Ayuda funcional (onboarding dentro de pantalla)**
   - posición: superior
   - acciones:
     - `Cerrar` (solo ahora)
     - `No mostrar de nuevo` (persistente por id)
   - desactivación: **individual**, no global.

2. **Info/estado**
   - posición: superior
   - duración corta automática
   - no bloquea interacción inferior.

3. **Error**
   - visible arriba
   - no desactivable permanentemente
   - cerrable manualmente
   - permite generar/copiAR reporte para desarrollador.

## Persistencia
- Ayudas: `SharedPreferences` por clave `help_message_dismissed_<id>`
- Logs error: lista `error_logs` en `SharedPreferences` (cap 200)

---

## 4) Compatibilidad y decisiones técnicas

- Se evitó depender de `showMenu.barrierColor` porque la versión actual de Flutter no lo expone en este entorno.
- Se usó `PopupMenuItem.height` con valor fijo (en vez de `null`) por compatibilidad de SDK.
- Todo quedó validado con:
  - `dart analyze`
  - sin errores de lint en archivos modificados.

---

## 5) Cómo personalizar rápido (guía práctica)

## Visual glass
- Archivo: `lib/constants/app_constants.dart`
- Clase: `AppPrayGlass`
- Ajustar:
  - `blurSigma`
  - `frostedTint`
  - `borderLight`
  - `roundButtonSize`
  - `pillRadius`
  - `menuBorderRadius`
  - `menuIconMusic`, `menuIconPrayers`

## Botón inferior
- Archivo: `lib/presentations/screens/pray_screen.dart`
- Función: `_prayGlassPillButton`
- Propiedades clave:
  - `height: AppPrayGlass.roundButtonSize`
  - `padding` horizontal
  - estilo de texto (`pillTextStyle`)

## Mensajes de ayuda
- Archivo: `lib/presentations/screens/pray_screen.dart`
- Función: `_buildHelpMessageQueueOnce()`
- Agregar mensajes nuevos:
  - sumar `id` y `text` en el catálogo local.

---

## 6) Consideraciones para Play Store (siguiente etapa)

Hoy el reporte de errores es **local + copiable** (ideal para beta y QA manual).  
Para producción masiva se recomienda:

1. Integrar SDK de crash/log remoto (Firebase Crashlytics o Sentry).
2. Enviar los logs del `ErrorLogService` a endpoint HTTPS propio.
3. Asociar logs con versión de app y dispositivo (sin datos sensibles).
4. Mantener opción de “Enviar reporte” para casos no crash.

---

## 7) Conclusión

La app pasó de un esquema con snackbars inferiores (invasivos) a un sistema superior más usable, con onboarding controlable por usuario, errores robustos y base de observabilidad para soporte técnico.  
Además, la visual de la pantalla del rosario quedó coherente con estilo glass en navbar, botones y menú, y se añadió tamaño intermedio para rosario (`medium`) con aplicación real en `rosa` y su `brillo`.
