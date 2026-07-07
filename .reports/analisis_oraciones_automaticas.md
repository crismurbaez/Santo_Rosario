# Análisis del Avance Automático de Oraciones (con Audio Activado)

El avance automático de las oraciones (oraciones guiadas por voz) en la aplicación del Santo Rosario funciona a través de un mecanismo de eventos del ciclo de vida del audio centralizado en el servicio `RosaryAudioHandler`. A continuación, se detalla el flujo profundo de su funcionamiento:

## 1. El Servicio Gestor de Audio (`RosaryAudioHandler`)
El archivo principal que controla este comportamiento es `lib/services/rosary_audio_handler.dart`. Esta clase hereda de `BaseAudioHandler` del paquete `audio_service`, lo que permite que el control del audio se mantenga activo en segundo plano y controle la lógica del rosario. 
Utiliza el paquete `just_audio` mediante dos reproductores independientes:
- `_prayerPlayer`: Reproduce las oraciones (voz).
- `_backgroundPlayer`: Reproduce la música de fondo.

## 2. Suscripción a Eventos de Audio (El Detonante)
En el constructor de `RosaryAudioHandler`, se establece un listener sobre el estado de procesamiento (`processingStateStream`) del `_prayerPlayer`:

```dart
_prayerPlayer.processingStateStream.listen((state) {
  if (state == ProcessingState.completed) {
    _handlePlaybackCompleted();
  }
});
```
Cuando un archivo de audio (una oración) termina de reproducirse completamente, `just_audio` emite el estado `ProcessingState.completed`. Este es el detonante que produce el "avance automático".

## 3. Lógica de Cambio de Oración / Cuenta (`_handlePlaybackCompleted`)
Al finalizar la reproducción, se ejecuta `_handlePlaybackCompleted()`. Esta función evalúa:
1. **Verificación de Fin de Rosario**: Comprueba si se encuentra en la última cuenta (`_counter >= Data.rosaryBeadSteps.length - 1`) y en la última oración de esa cuenta (`_orderPrayer >= step.prayers.length - 1`). Si es así, se detiene el avance (dejando la música de fondo).
2. **Avance**: Si el rosario no ha terminado, se invoca `_incrementCounter()` seguido de `_playCurrentStep()`.

## 4. Actualización del Estado Interno (`_incrementCounter`)
El método `_incrementCounter()` actualiza la posición del rosario en la lógica interna del handler:
- **Avanza la oración (`_orderPrayer++`)**: Si la cuenta actual (`step`) tiene más oraciones pendientes.
- **Avanza de cuenta (`_counter++`)**: Si ya se dijeron todas las oraciones de la cuenta actual, avanza a la siguiente cuenta y reinicia el índice de oración (`_orderPrayer = 0`).
- **Actualización del Misterio**: Se actualiza `_orderMystery` de acuerdo con el nuevo `step`.
- **Notificación al Sistema (`_updateMediaItem`)**: Se actualiza el `MediaItem` actual, enviando información en la propiedad `extras` (con `counter`, `orderPrayer`, y `orderMystery`).

## 5. Reproducción de la Siguiente Oración (`_playCurrentStep`)
Una vez actualizado el índice, se invoca a `_playCurrentStep()`:
- Identifica qué texto corresponde (`prayerLabel`).
- Busca el path del archivo de audio en la estructura `Data.prayersSounds`. (Maneja casos especiales como el archivo del "Misterio", que se compone dinámicamente).
- Si existe el archivo, se detiene cualquier reproducción previa, se carga el nuevo archivo (`_prayerPlayer.setAsset(assetPath)`), y se llama a `_prayerPlayer.play()`.

Esto inicia la reproducción de la nueva oración de manera continua y sin requerir interacción del usuario.

## 6. Reflejo en la Interfaz de Usuario (UI)
Aunque el avance lo maneja internamente el `RosaryAudioHandler`, la UI (`PrayScreen` y widgets relacionados) necesita sincronizarse. Esto se logra mediante el gestor de estados `Riverpod`:
- `lib/providers/audio_provider.dart` expone un `StreamProvider` llamado `currentMediaItemProvider` que escucha los cambios del `mediaItem` del `audioHandler`.
- Cuando el audio avanza automáticamente y actualiza el `mediaItem` (enviando el nuevo `counter` y `orderPrayer` en `extras`), los componentes de la interfaz que están suscritos a este provider se reconstruyen de forma reactiva.
- Como resultado, la cuenta actual (bolita del rosario) se resalta, y el texto de la oración que se muestra en pantalla cambia automáticamente de la mano del audio.

## Conclusión
El "avance automático" es una arquitectura reactiva (event-driven) impulsada por el reproductor de audio. No utiliza temporizadores abstractos (Timers), sino que usa el evento `ProcessingState.completed` de `just_audio` como señal inequívoca de que la voz ha terminado de recitar el texto actual. A partir de esa señal, la lógica central actualiza el estado interno, lanza la siguiente pista y emite un estado global que fuerza la actualización reactiva en la interfaz gráfica del usuario.
