# Informe: íconos play/stop y debounce del botón de sesión de audio

**Fecha:** 2026-05-04  
**Pantalla:** oración (`PrayScreen`)

## Objetivo

- Sustituir la **bocina tachada** (`Icons.volume_off`) por **play** cuando la sesión de audio está apagada (`_isplaying == false`).
- Sustituir la **bocina activa** (`Icons.volume_up`) por **stop** cuando la sesión está encendida (`_isplaying == true`).
- **Bloquear** el botón durante un intervalo configurable para evitar pulsaciones repetidas que desordenen el estado.

## Constante nueva

| Archivo | Símbolo | Valor |
|---------|---------|--------|
| `lib/constants/app_constants.dart` | `AppPrayGlass.audioSessionButtonDebounce` | `Duration(milliseconds: 500)` |

Comentario en código: indica uso en `PrayScreen` y propósito (antirrebote).

## Código modificado

### 1. `lib/constants/app_constants.dart`

- En la clase `AppPrayGlass`, después de `roundButtonSize`, se añadió `audioSessionButtonDebounce`.

### 2. `lib/presentations/screens/pray_screen.dart`

- **Estado:** `bool _audioSessionButtonLocked` y `Timer? _audioSessionButtonDebounceTimer`.
- **`dispose`:** cancelación de `_audioSessionButtonDebounceTimer`.
- **`playPause()`:** al inicio, si está bloqueado, `return`. Si no, pone `locked = true`, cancela timer anterior, programa un `Timer` por `AppPrayGlass.audioSessionButtonDebounce` que al vencer pone `locked = false` y `setState`. Luego el `setState` que alterna `_isplaying` y el `addPostFrameCallback` existentes (sin cambiar la lógica de audio).
- **UI del botón:** el `_prayGlassRoundButton` del ícono de sesión va envuelto en `Opacity` (0.45 cuando bloqueado) y `AbsorbPointer(absorbing: locked)` para no recibir toques durante el debounce.
- **Íconos:** `_isplaying ? Icons.stop_rounded : Icons.play_arrow_rounded`.
- **Comentario** del helper `_prayGlassRoundButton`: texto actualizado (ya no dice solo «volumen»).

## Comportamiento esperado

1. Con sesión apagada se ve **play**; al pulsar, arranca audio como antes y pasa a **stop**; el botón queda atenuado y sin respuesta ~500 ms.
2. Con sesión encendida se ve **stop**; al pulsar, detiene como antes y vuelve **play**; mismo bloqueo ~500 ms.

## Ajuste del retraso

Cambiar solo `AppPrayGlass.audioSessionButtonDebounce` en `app_constants.dart` (por ejemplo 300–800 ms según sensación en dispositivo real).
