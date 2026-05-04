# Trazas de audio de oraciones y envío por correo

Documentación del módulo de **pruebas en dispositivo (APK)** que registra el flujo del audio guiado en `PrayScreen`, escribe un log persistente **solo mientras el audio principal está encendido** y, al apagarlo, **envía el log por correo** (en varias partes si el texto es muy largo), usando la misma infraestructura que los reportes de error (`ErrorReporter` + `assets/env/app.env`).

Incluye también el **orden de arranque audio en `PrayScreen`** y el comportamiento de **`playPrayer`** en `AudioService`, porque afectan lo que ves en el trace (p. ej. `trust` vs `ProcessingState.completed`) y el avance automático de oraciones.

---

## 1. Objetivo

- Entender el comportamiento real en el celular: activación de audio, `initAudio`, estados de `just_audio`, `ProcessingState.completed`, flags `trust` / `incrementing`, avance a la siguiente oración o bloqueos.
- Conservar evidencia en **archivo** durante la sesión de audio y volcarla por **email al terminar** esa sesión (sin depender del depurador de Chrome).

---

## 2. Ventana de registro (sesión)

- **Inicio:** cuando el usuario **activa** el audio con el botón de volumen en la pantalla de oración (`playPause` → `_playPausePostFrameAudioAndTrace` con `_isplaying == true`).
  - `await PrayerAudioTrace.beginAudioTraceSession()`: primero **espera la cola de escritura** (`await _writeQueue`) para no solaparse con un cierre de sesión anterior, luego vacía archivo y buffer, activa `sessionActive` y registra “sesión iniciada”.
- **Fin:** cuando el usuario **desactiva** el mismo audio. Tras `await stopAudioBackground()` y `await stopAudio()`, `PrayerAudioTrace.endAudioTraceSessionAndSendEmails(reason: 'audio_off_usuario')`: pone `sessionActive` en falso, **`await _writeQueue`** hasta que no queden escrituras pendientes, lee el log completo desde disco (o buffer en web), vacía archivo/buffer y envía los correos.
- **Salir de la pantalla con el audio aún encendido:** en `dispose`: `PrayerAudioTrace.bumpPrayScreenCloseGeneration()` (invalida un `beginAudioTraceSession` que todavía esté en un `await`), luego `unawaited(onPrayScreenDisposed())` → `endAudioTraceSessionAndSendEmails(reason: 'dispose_PrayScreen')` si seguía había sesión activa.

Mientras `sessionActive` es falso, `PrayerAudioTrace.line` / `error` / `warning` / `prayerPlayerStateDelta` no persisten nada.

---

## 3. Orden al encender audio (`PrayScreen`)

En **`_playPausePostFrameAudioAndTrace`** (rama `_isplaying == true`), tras `beginAudioTraceSession()` y comprobar `mounted` y `_isplaying`:

1. **`initAudio()` primero** si las oraciones guiadas están activas — evita dejar un **`await` largo** de música de fondo antes de arrancar la pista de oración (reducía casos de `initAudio` abandonado con `!_isplaying` tras su `delay`).
2. **`_loadBackgroundMusic()`** se lanza con **`unawaited(...)`** en paralelo cuando la música de fondo está activa; no bloquea el arranque del MP3 guiado.
3. Línea de traza opcional con snapshot `bgMusicTriggered` / `prayersTriggered`.

Esto es independiente del módulo `lib/debug/` en cuanto a lógica de producto, pero **sí aparece en el log** y condiciona qué ves en orden temporal.

---

## 4. `AudioService.playPrayer` y el trace de `trust` / `completed`

En Android, **`await _prayerPlayer.play()`** (just_audio) puede **resolver el Future solo cuando termina toda la pista**, no al iniciar reproducción. Consecuencia que el trace evidenció:

- Llegaba **`ProcessingState.completed`** al listener m **`_trustPrayerPlaybackCompleted` seguía en `false`**, porque `initAudio` aún estaba bloqueado **dentro** de `await play()`.
- Inmediatamente después se ponía `trust→true`; el avance automático **no ocurría**.

**Corrección en código:** después de **`setAsset`**, la reproducción se arranca con **`unawaited(_prayerPlayer.play().catchError(...))`** sin esperar el fin de pista desde `playPrayer`. Así **`playPrayer` retorna** y `initAudio` puede establecer **`_trustPrayerPlaybackCompleted = true`** **antes** de que llegue el `completed` natural, alineando el diseño previsto del listener sobre `playerStateStream`.

Las trazas en `audio_service.dart` mencionan “play() despachado” y errores posibles del `Future` en consola (`debugPrint`), sin bloquear el flujo UI.

---

## 5. Archivos del módulo (`lib/debug/`)

| Archivo | Descripción |
|---------|-------------|
| `prayer_audio_trace_config.dart` | Constantes: traza ON/OFF, email ON/OFF, reserva de cabecera, tamaño máximo por correo, pausa entre partes, nombre del archivo. |
| `prayer_audio_trace.dart` | Sesión, cola **`_writeQueue`**, `_persist`, troceo por líneas para email, envío secuencial. |
| `prayer_audio_trace_storage.dart` | Export condicional `dart.library.io`. |
| `prayer_audio_trace_storage_io.dart` | `appendPrayerAudioTraceLine`, `clearPrayerAudioTraceLogFile`, `readFullPrayerAudioTraceLog`. |
| `prayer_audio_trace_storage_stub.dart` | Web: `append` → `debugPrint`; `clear` / lectura sin archivo físico. |

**Instrumentación adicional:**

- `lib/presentations/screens/pray_screen.dart` — rutas ya citadas más listener, `initAudio`, `stopAudio`, menú, contadores, `handleCuentaHighlighted`, ciclo de vida, `dispose`.
- `lib/services/audio_service.dart` — trazas y lógica de `playPrayer` (véase §4).
- `lib/services/error_reporter.dart` — `submitDiagnosticLog`.

**Dependencia:** `path_provider` en `pubspec.yaml`.

---

## 6. Configuración (`prayer_audio_trace_config.dart`)

| Constante | Valor por defecto | Efecto |
|-----------|-------------------|--------|
| `kPrayerAudioTraceEnabled` | `true` | Si es `false`, no hay sesión ni persistencia ni envío. |
| `kPrayerAudioTraceSendEmail` | `true` | Si es `false`, al cerrar sesión solo se limpia y `debugPrint`; no hay HTTP. |
| `kPrayerAudioTraceEmailHeaderReserve` | `900` | Se usa al calcular el tamaño de cada trozo de log por correo. |
| `kPrayerAudioTraceEmailMaxChars` | `45000` | Tamaño máximo del **cuerpo completo** de cada correo (cabecera + trozo). |
| `kPrayerAudioTraceEmailBetweenParts` | `500` ms | Pausa entre envíos cuando hay varias partes. |
| `kPrayerAudioTraceLogFileName` | `prayer_audio_trace.log` | Archivo bajo el directorio de documentos de la app. |

---

## 7. Guardado de logs: cola serializada (`_writeQueue`)

Cada línea pasa por **`_persist`**, que encadena operaciones con **`_writeQueue`**:

- Una llamada termina de actualizar **buffer en memoria** y **append al archivo** antes de que la siguiente empiece.
- Evita **líneas partidas o mezcladas** que aparecían cuando muchos `unawaited(PrayerAudioTrace.line(...))` provocaban escrituras concurrentes sobre el mismo archivo en Android.

**Al abrir sesión:** `await _writeQueue` antes de borrar/truncar log en disco.

**Al cerrar sesión:** `await _writeQueue` antes de `readFullPrayerAudioTraceLog()` para enviar contenido estable.

Los **trozos del email** preferentemente **entre saltos de línea** (`\n`), agrupando líneas hasta el límite de caracteres por parte; líneas muy largas se pueden partir de todos modos como último recurso.

---

## 8. Envío por correo (varias partes)

1. Por cada parte: **`ErrorReporter.submitDiagnosticLog`** (`ErrorKind.unknown`, `ErrorSeverity.info`).
2. Misma configuración que **`assets/env/app.env`** (EmailJS o webhook). Si `ERROR_REPORT_PROVIDER` es `none`, el envío falla y se registra en consola.
3. Trozos según **`max(4096, kPrayerAudioTraceEmailMaxChars - kPrayerAudioTraceEmailHeaderReserve)`** caracteres de contenido, con cabecera que incluye **`_sessionSeq`**, razón de cierre, **parte k/n** y plataforma.
4. **Destinatario:** `ErrorReporter.developerEmail`.

**Momento:** no hay cron ni debounce; solo al **apagar el volumen principal** (`audio_off_usuario`) o al **dispose** de `PrayScreen` con sesión aún abierta (`dispose_PrayScreen`).

**Plantilla EmailJS:** si el correo repite bloques (“DATOS TÉCNICOS” + mismo log dos veces), suele ser **mapeo duplicado** de variables (`message`, `technical`, etc.) en la plantilla; no lo controla el código Dart del trace.

---

## 9. Formato de cada línea de log

```text
[2026-05-04T15:00:01.234567] lib/presentations/screens/pray_screen.dart `initAudio` — ... | vars: ...
```

Los cambios de **`processingState` + `playing`** van por **`prayerPlayerStateDelta`** solo cuando cambia la clave, para no inundar eventos repetidos.

---

## 10. Archivo local en el móvil

- **Android / iOS / escritorio:** append por sesión sobre `kPrayerAudioTraceLogFileName`; al cerrar sesión se lee todo, se envía y se vacía.
- **Web:** sin archivo físico en stub; puede usarse buffer si el archivo leído está vacío.

---

## 11. Desactivar o eliminar el sistema

### Solo desactivar

En `lib/debug/prayer_audio_trace_config.dart`: `kPrayerAudioTraceEnabled = false`, y opcional `kPrayerAudioTraceSendEmail = false`.

### Quitar código

1. Carpeta **`lib/debug/`**.
2. **`pray_screen.dart`**: trazas, `bumpPrayScreenCloseGeneration`, hooks de `_playPausePostFrameAudioAndTrace` relacionados solo con trace (mantener orden producto **`initAudio`** / **`unawaited(_loadBackgroundMusic())`** si deseas ese comportamiento sin email).
3. **`audio_service.dart`**: trazas; **decisión aparte**: mantener o revertir **`unawaited(play())`** si quieres conservar solo el fix de avance sin logs.
4. Opcional: `submitDiagnosticLog` en `error_reporter.dart`, `path_provider` en `pubspec.yaml`.

---

## 12. Comprobaciones si no llega el correo

1. Credenciales en `app.env`; `ERROR_REPORT_PROVIDER` ≠ `none`.
2. Red al **cerrar sesión** (apagar volumen o salir de pantalla con audio ON).
3. Consola / Logcat: `[PrayerAudioTrace] fallo envío email`.
4. Plantilla EmailJS: tamaño del cuerpo y campos repetidos no dupliquen el mismo texto tres veces.

---

## 13. Privacidad

- El log puede incluir rutas de assets y estado del rosario. Mantén **`kPrayerAudioTraceEnabled` en `false`** en builds de producción destinados al público.

---

*Documento actualizado: sesión alineada con volumen, cola de escritura, troceo por líneas para email, orden `initAudio`/música en `PrayScreen`, y `playPrayer` sin esperar fin de pista en Android.*
