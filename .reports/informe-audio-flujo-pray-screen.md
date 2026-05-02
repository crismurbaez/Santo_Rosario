# Informe: sistema de audio en la pantalla de oración (`PrayScreen`)

**Proyecto:** Santo Rosario  
**Alcance:** flujo integral de música de fondo + audios guiados por oración, estado de UI, datos y puntos sensibles del ciclo de vida.  
**Fecha:** 2026  

Este documento describe el funcionamiento tal como está en el código de referencia (sin modificaciones aplicadas dentro del informe). Al final hay una **sección de diagnóstico** sobre el comportamiento irregular reportado por el usuario, **sin cambios propuestos en código** dentro de ese apartado más allá de la descripción causal.

---

## 1. Arquitectura general

Hay **dos fuentes sonoras simultáneas e independientes** en tiempo de ejecución:

| Rol | Implementación | Archivo |
|-----|----------------|---------|
| Música de fondo | `AudioPlayer _backgroundPlayer` | `lib/services/audio_service.dart` |
| Oración guiada | `AudioPlayer _prayerPlayer` | mismo archivo |

El **único punto de uso** actual de ese servicio en la app está en **`PrayScreen`** (`lib/presentations/screens/pray_screen.dart`). No hay singleton global: cada instancia del `State` de `PrayScreen` crea **`final _audioService = AudioService()`** como campo de instancia (`pray_screen.dart`, alrededor de la línea 42).

Las **preferencias persistentes** (ON/OFF de cada tipo de audio) están en **`PreferencesService`** (`lib/services/preferences_service.dart`), con claves en `AppPreferencesKeys` (`lib/constants/app_constants.dart`):

- `isPrayersAudioPlaying` ↔ `AppPreferencesKeys.prayersAudioPlaying`
- `isBackgroundMusicPlaying` ↔ `AppPreferencesKeys.backgroundMusicPlaying`

Los **asset paths** MP3 están en **`Data.prayersSounds`** (`lib/data/models/data.dart`): es un `Map<String, String>` donde la **clave** es el texto de la oración (debe coincidir con cómo están nombradas en las listas de oraciones por cuenta del rosario) y el valor es la ruta bajo `assets/sounds/...`.

Las **duraciones artificialmente impuestas** entre operaciones están en **`AppDelays`** (`lib/constants/app_constants.dart`):

- `delayAudio` = 100 ms  
- `delayMusic` = 15 s (uso especial al cruzar “Señal de la Cruz” con música de fondo activa)

Constantes relacionadas:

- **`AppAssets.soundSignalOfTheCross`** y **`AppAssets.soundAveMariaBackground`** líneas declaradas en `app_constants.dart` (rutas a MP3 concretos).
- **`AppAudio.backgroundMusicVolume`** = volumen de la música de fondo.

---

## 2. Capa `AudioService`: qué hace cada API

Archivo: `lib/services/audio_service.dart`

### 2.1 Reproductores y stream

```5:9:lib/services/audio_service.dart
  final AudioPlayer _prayerPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  Stream<PlayerState> get prayerPlayerStateStream =>
      _prayerPlayer.playerStateStream;
```

- **`playerStateStream`** (`just_audio`) emite continuamente `PlayerState` (incluye `processingState`, `playing`, etc.).
- **`PrayScreen` se suscribe una sola vez** en `initState` para reaccionar a **`ProcessingState.completed`** en el player de **oraciones** (ver sección 4).

### 2.2 Música de fondo

```11:16:lib/services/audio_service.dart
  Future<void> playBackgroundMusic() async {
    await _backgroundPlayer.setAsset(AppAssets.soundAveMariaBackground);
    await _backgroundPlayer.setLoopMode(LoopMode.all);
    await _backgroundPlayer.setVolume(AppAudio.backgroundMusicVolume);
    await _backgroundPlayer.play();
  }
```

- Carga **`Ave_Maria_Background.mp3`**, modo bucle infinito, volumen constante configurado por constante.

```18:20:lib/services/audio_service.dart
  Future<void> stopBackgroundMusic() async {
    await _backgroundPlayer.stop();
  }
```

### 2.3 Oraciones (bloque síncrono lógico: stop → cargar asset → play)

```22:26:lib/services/audio_service.dart
  Future<void> playPrayer(String assetPath) async {
    await _prayerPlayer.stop();
    await _prayerPlayer.setAsset(assetPath);
    await _prayerPlayer.play();
  }
```

Puntos relevantes para el **comportamiento en dispositivos reales**:

1. **Siempre** se llama a **`stop()`** antes de cargar el siguiente recurso.
2. En muchas plataformas y versiones del plugin **`just_audio`**, las transiciones **`stop`** / nueva fuente pueden **emitir eventos en `playerStateStream`** (por ejemplo estado `completed` o transiciones rápidas) que **no equivalen necesariamente** a “el usuario oyó hasta el final esta oración”.
3. No hay aquí ninguna forma de diferenciar en el propio servicio entre “completed por fin natural del MP3” y “completed/indirecto tras `stop()`”.

```28:30:lib/services/audio_service.dart
  Future<void> stopPrayer() async {
    await _prayerPlayer.stop();
  }
```

### 2.4 Liberación en cierre de pantalla

```32:37:lib/services/audio_service.dart
  Future<void> dispose() async {
    await _prayerPlayer.stop();
    await _prayerPlayer.dispose();
    await _backgroundPlayer.stop();
    await _backgroundPlayer.dispose();
  }
```

`PrayScreen.dispose` llama a **`_audioService.dispose()`** (aprox. líneas 139–146 de `pray_screen.dart`).

---

## 3. Estado de audio en `_PrayScreenState`

Archivo principal: **`lib/presentations/screens/pray_screen.dart`**

### 3.1 Flags y datos que gobiernan el audio

Referencias aproximadas (líneas pueden variar si el archivo creció; buscar los identificadores):

| Identificador | Propósito |
|---------------|-----------|
| **`_isplaying`** | Equivale al “motor maestro”: si el usuario “tiene audio encendido” en esa pantalla (botón volumen). No es igual a “solo oraciones”: enciende música + oraciones si sus sub-banderas lo permiten. |
| **`_isBackgroundMusicPlaying`** | Si debe sonar música de fondo mientras **`_isplaying`** es verdadero. Se persiste. |
| **`_isPrayersAudioPlaying`** | Si deben cargarse/reproducirse los MP3 por oración. Se persiste. |
| **`_audioRequestId`** | Contador usado dentro de **`initAudio()`** como “generation token”: cualquier llamada asíncrona obsoleta debería abandonar después de esperas si el íd cambió en el medio. |
| **`_isIncrementingInProgress`** | Semáforo usado junto al listener del stream de oraciones para evitar llamadas repetidas muy seguidas a **`_incrementCounter()`** cuando llega **`completed`**. |
| **`rosaryprayersSounds`** | Copia inicial de **`Data.prayersSounds`** (`Map<String,String>` local al State). Las claves son las etiquetas literales de oración. |
| **`prayerSound`** | **`late String`**: ruta MP3 efectiva seleccionada en la última pasada válida de **`initAudio`**. |

### 3.2 Carga y guardado de preferencias

El arranque de pantalla ejecuta **`_loadPrefs()`** después de inicializar otros servicios asíncronos (aprox. `initState` línea ~135):

- Lee **`getPrayerAudioPlaying()`** y **`getBackgroundMusicPlaying()`** en `PreferencesService`.
- Llama después a **`_buildHelpMessageQueueOnce()`**, **`_tryRestorePrayerProgress()`**.
- **`setState`** asignando **`_isPrayersAudioPlaying`** y **`_isBackgroundMusicPlaying`**.

Las escrituras están en **`_savePrefs()`** (aprox. 274–278), llamadas cuando el usuario muta música u oraciones desde el menú o toggles relacionados (**`_togglePrayersAudio`**, música de fondo, etc.).  
**Importante:** al abrir por primera vez, los defaults en `PreferencesService` son **`true`** para ambos si no existe clave almacenada.

---

## 4. Ciclo principal: iniciar audio general en la pantalla

### 4.1 Entrada típica: botón volumen circular (`playPause`)

```691:708:lib/presentations/screens/pray_screen.dart
  void playPause() {
    setState(() {
      _isplaying = !_isplaying;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Carga la música de fondo al iniciar el audio o lo detiene si se desactiva
      if (_isplaying) {
        if (_isBackgroundMusicPlaying) {
          _loadBackgroundMusic();
        }
        if (_isPrayersAudioPlaying) {
          initAudio();
        }
      } else {
        stopAudioBackground(); // Detiene la música de fondo
        stopAudio(); // Detiene el audio de la oración
      }
    });
  }
```

Orden efectivo cuando el usuario **activa** el audio:

1. **`setState`** invierte **`_isplaying`**.
2. Post-frame (**`addPostFrameCallback`**):
   - Si **`_isBackgroundMusicPlaying`**: **`_loadBackgroundMusic()`** → `AudioService.playBackgroundMusic()` en try/catch con informe **`AppError`** de tipo audio si falla (mensaje usuario: “No se pudo iniciar la música de fondo.”).
   - Si **`_isPrayersAudioPlaying`**: **`initAudio()`**.

Cuando **desactiva**:

- **`stopAudioBackground`** y **`stopAudio`** (**`stopAudio`** además incrementa **`_audioRequestId++`** antes de **`stopPrayer()`**).

El uso de **`addPostFrameCallback`** evita leer inconsistencias dentro del mismo ciclo síncrono de **`setState`**, garantizando que la lectura de **`_isplaying`** y afines coincide con el nuevo árbol.

### 4.2 Menú hamburguesa de opciones (`_showPrayGlassAudioMenu` + panel `_prayGlassAudioMenuPanel`)

Este flujo no introduce un segundo **`AudioService`**. Solo ejecuta métodos sobre el mismo estado:

- Opción música de fondo → **`_toggleBackgroundMusic()`** (~712–719).
- Opción oraciones → **`_togglePrayersAudio`** (~725+) con **`setState`** y **`stopPrayer()`** cuando se desactiva oraciones pero el usuario puede seguir con **`_isplaying`** verdadero solo con música si lo permitiese la combinación actual.

---

## 5. `initAudio()` en profundidad: selección del MP3 y colisiones asíncronas

Función **`void initAudio() async`** — aproximadamente líneas **569–613** (`pray_screen.dart`).

### 5.1 Primer guardian: ¿oraciones están habilitadas?

```569:572:lib/presentations/screens/pray_screen.dart
  void initAudio() async {
    if (!_isPrayersAudioPlaying)
      return; // Si el audio de las oraciones no está activo, salimos
```

Si **`false`**, ni siquiera se encola nueva reproducción. **Sin bloque **`finally`** en esta versión del código**, ningún recurso paralelo dentro de **`initAudio`** “desbloquea” semáforos externos salvo donde se asignan explícitamente (véase **`_isIncrementingInProgress`** al final del bloque **`if (_isplaying)`**).

### 5.2 Id de petición + delay fijo inicial

```572:575:lib/presentations/screens/pray_screen.dart
    final requestId = ++_audioRequestId;
    // Introduce un pequeño retraso
    // Esto le da tiempo al reproductor para finalizar cualquier proceso interno
    await Future.delayed(AppDelays.delayAudio);
```

- **`delayAudio`** = 100 ms (constante en `AppDelays`).
- Tras el **`await`**, se revalida la petición (siguiente bloque **`try`**).

Si entre medias **`stopAudio`** incrementó `_audioRequestId`, la siguiente comprobación hace **`return`** y evita ejecutar trabajo obsoleto.

### 5.3 Resolución de la etiqueta de oración y del archivo

```579:587:lib/presentations/screens/pray_screen.dart
      final prayerLabel = _safeCurrentPrayerLabel;
      if (rosaryprayersSounds[prayerLabel] != null) {
        prayerSound = rosaryprayersSounds[prayerLabel]!;
      }

      if (prayerLabel == 'Misterio') {
        String soundMystery = '${widget.mystery}${_orderMystery.toString()}';
        prayerSound = rosaryprayersSounds[soundMystery]!;
      }
```

Cadena conceptual:

1. **`_safeCurrentPrayerLabel`** viene de **`_currentPrayers[_safeOrderPrayerIndex]`** con clamp de índice ( getters ~181–187). La lista **`_currentPrayers`** surge del **dibujo del rosario** mediante **`onCuentaHighlighted`** (sección 6).
2. Si la etiqueta existe en **`rosaryprayersSounds`**, **`prayerSound`** se sobrescribe.
3. Si la etiqueta textual es **`'Misterio'`**, **ignora ese mapa inicial** para el nombre “visible” de la cuenta y arma una clave compuesta **`'${widget.mystery}${_orderMystery}'`** (ej. `gozosos1`, definido también en **`Data.prayersSounds`** junto con claves **`gozosos1`**, etc.).

**Riesgo lógico (documental, sin parche aquí):** si una etiqueta de oración aparece en el rosario pero **no** tiene entrada en **`prayersSounds`**, **`prayerSound` puede quedar con el valor de la llamada anterior** (`late String` sólo garantiza inicialización después de primera asignación; no “reseteo” aquí antes de reproducir si no entró ningún **`if`**).

### 5.4 Coexistencia música de fondo + “Señal de la Cruz”

```590:596:lib/presentations/screens/pray_screen.dart
      if (_isplaying) {
        //retraso de 15 segundos si el sonido es 'Señal de la Cruz' y la música de fondo está activa
        prayerSound == AppAssets.soundSignalOfTheCross &&
                _isBackgroundMusicPlaying
            ? await Future.delayed(AppDelays.delayMusic)
            : null;
        await _audioService.playPrayer(prayerSound);
```

- Comparación **`prayerSound == AppAssets.soundSignalOfTheCross`**: mismo string que en **`AppAssets`** (`Senal_de_la_cruz.mp3`).
- **`delayMusic` = 15000 ms** inserta hasta **15 s** antes de lanzar ese MP3 concreto, **solo** cuando la música de fondo también está marcada como activa desde preferencias/UI.

Este bloque aumenta enormemente la **ventana** en la que puede ocurrir **cualquier otra llamada asíncrona** que mute el player o cambie **`_audioRequestId`**.

### 5.5 Llamada concreta al servicio + reset del semáforo de incremento

```596:598:lib/presentations/screens/pray_screen.dart
        await _audioService.playPrayer(prayerSound);

        _isIncrementingInProgress = false;
```

- **`await playPrayer`** encadena **`stop`** + **`setAsset`** + **`play`** (véase §2).
- **Solo** si se entra en **`if (_isplaying)`** y no hay **`return`** intermedio, se vuelve a **`false`** el flag que el listener utilizó antes de incrementar (sección siguiente).

### 5.6 Errores e interrupciones “esperadas”

```600:611:lib/presentations/screens/pray_screen.dart
    } catch (e) {
      if (_isExpectedAudioInterruption(e)) {
        return;
      }
      _reportError(
        AppError(
          ...
          userMessage: 'No se pudo reproducir el audio de la oración actual.',
...
```

**`_isExpectedAudioInterruption`** (~626–628) filtra texto de error conocido relacionado con interrupción de carga.

**`_reportError`**: errores graves van a **`_currentError`** y UI de error persistente; **warnings** (como muchos errores audio en este flujo) se convierten en **`_showTopInfoMessage`** (banner superior tipo snackbar contextual).

Si hubo **`return`** antes de ejecutar **`_isIncrementingInProgress = false`**, ese flag puede **mantener el valor **`true`**** que estableció el listener de **`completed`** antes de lanzar **`_incrementCounter`** (diagrama causal en §8).

---

## 6. Sincronización rosario dibujado ↔ lista de textos ↔ `initAudio`

### 6.1 Dónde nace **`_currentPrayers`**

`CustomPaint` con **`CuentasPainter`** (aprox. líneas ~1229–1240):

- Pasa **`counter: _counter`**, **`orderPrayer: _orderPrayer`**, **`onCuentaHighlighted: _handleCuentaHighlighted`**.

En **`CuentasPainter.paint`**, al final dibuja el brillo de la cuenta **`allRosaryElements[counter]`** y **siempre** invoca **`onCuentaHighlighted(prayersAsListOfNames, detail.order)`** (~259–261 en `rosary_painter.dart`).

### 6.2 `shouldRepaint` del pintor — qué fuerza repaint

```323:328:lib/presentations/widgets/rosary_painter.dart
    bool shouldRepaint(covariant CuentasPainter oldDelegate) {
      return  oldDelegate.cuentas != cuentas
           || oldDelegate.counter != counter ||
              oldDelegate.rosaryBeadCount != rosaryBeadCount ||
              oldDelegate.rosaryCircleBeadCount != rosaryCircleBeadCount;
    }
```

**Observación estructural crítica (para auditoría técnica):** **`orderPrayer`** se pasa como parámetro pero **no forma parte del criterio de `shouldRepaint`**.

Consecuencia teórica: si solo cambia **`_orderPrayer`** (misma **`_counter`**) y **`cuentas`** no cambió, **`CustomPainter`** **puede omitir ejecutar **`paint`** de nuevo**. En ese escenario **`onCuentaHighlighted`/`initAudio`** asociados a la reproducción al cambiar de sub-oración dentro de la **misma** cuenta física pueden **no re-dispararse** por el mismo mecanismo de pintura.

### 6.3 `_handleCuentaHighlighted` — doble uso de **`addPostFrameCallback`**

Implementación conceptual (~781–824):

**Rama condicional inicial** (**solo si** cambian las **listas textualizadas de oraciones** o el **`orderMystery`** del paso luminoso/doloroso/gozoso desde la cuenta):

```783:784:lib/presentations/screens/pray_screen.dart
    if (_currentPrayers.toString() != prayers.toString() ||
        (_orderMystery != orderMystery)) {
...
        setState(() {
          ...
          _currentPrayers = prayers;
...
          _orderPrayer = ... variantes restore / decrement / caso normal ...
```

Si **no hay cambio percibido** en las oraciones strings ni en orderMystery, **ese primer post-frame puede no registrar `setState`**.

Independientemente:

```812:822:lib/presentations/screens/pray_screen.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //si cambia el orden de la oración ...
      if (_oldOrderPrayer != _orderPrayer || _oldCounter != _counter) {
        initAudio();
        setState(() {
          _oldOrderPrayer = _orderPrayer;
          _oldCounter = _counter;
...
```

**Aquí sí** existe disparo de **`initAudio()``** cuando **`_orderPrayer` o **`_counter` divergen de **`_old*`** después de navegar por el rosario o restaurar estado.

**Interacción importante:** si **`paint`** **no ocurre**, **no se llama** **`_handleCuentaHighlighted`**, así que **nadie ejecuta ese segundo post-frame** que compara **`_oldOrderPrayer`**. El **`initAudio`** entonces debe venir por **otro camino**, típicamente **tras cambios de cuenta** que sí modifican **`counter`** o que disparan repaint por imágenes, no únicamente avance dentro de cuenta.

---

## 7. Avance automático al terminar MP3 (`playerStateStream`)

Suscripción (**`initState`**, líneas cercanas ~125–134):

```125:134:lib/presentations/screens/pray_screen.dart
    _audioService.prayerPlayerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        if (!_isIncrementingInProgress) {
          _isIncrementingInProgress = true;
          _incrementCounter();
        }
      }
    });
```

### 7.1 Qué hace `_incrementCounter()` (aprox. 739–760)

Sin citar todas las ramificaciones morfológicas: si dentro de **`_currentPrayers`** falta siguiente ítem, aumenta **`_counter`** para pasar físicamente la cuenta resaltada; si no, aumenta **`_orderPrayer`**.

Este método **NO llama él mismo a `initAudio()`**. Depende indirectamente del pipeline del rosario (repaint/`_handleCuentaHighlighted`), de la reproducción que se lanzó después, etc.

---

## 8. Narrativa integral del ciclo (flujo combinado narrado)

Aquí está el ciclo típico de “usuario tiene todo activo y avanza oraciones dentro de una misma cuenta resaltada”:

1. **Usuario activa** audio general → **`playPause`** habilitado → **`initAudio`** según texto actual (**§5**).
2. **`AudioService.playPrayer`** hace **`stop()`** sobre la última sesión antes de cargar nueva → **emisión posible intermedia del stream**.
3. Comienza reproducción; el stream alterna **`playing`/`processing`** varias veces.
4. Cuando llega **`ProcessingState.completed`**, **`listen`** ejecuta **`_incrementCounter`** si **`_isIncrementingInProgress`** estaba **`false`**.
5. **`_incrementCounter`** modifica **`_orderPrayer` o **`_counter`**** y **provoca **`setState`****.
6. Con el repaint coherente, **`CuentasPainter`** debería correr **`onCuentaHighlighted`**, ejecutando segunda post-frame que compara **`_oldOrderPrayer`/` _oldCounter`** y decide **`initAudio()`** cuando corresponde.

**Dos nodos donde el ciclo puede “saltar”:**
- (**A**) El stream marca **`completed`** en momentos donde **NO** culminó audiblemente una oración sino porque **hay un `stop()` programático** antes de cargar la siguiente (**§2.3**).
- (**B**) El pintor puede **omitir repaint** ante solo cambio **`orderPrayer`**, retardando/eliminando el camino habitual de **`initAudio`** vía **`_handleCuentaHighlighted`** hasta que algo más fuerza otro ciclo (**§6.2 vs §6.3**).

El mensaje **`_isIncrementingInProgress`** se pone **`true`** al incrementar desde el stream pero **solo vuelve a `false`** al final feliz dentro de **`initAudio`** bajo **`if (_isplaying)`** tras **`await playPrayer`** — si **`initAudio` no llega hasta ahí**, el **`listen`** puede quedar incapaz de lanzar nuevo increment automático porque cree que uno sigue en curso.

---

## 9. Map de archivos rápido (“ir y volver” en el proyecto)

| Tema | Archivo / símbolo |
|------|-------------------|
| Dos `AudioPlayer`, `playPrayer` | `lib/services/audio_service.dart` → `AudioService` |
| Flags audio + `initAudio` + `listen` completed | `lib/presentations/screens/pray_screen.dart` → `_PrayScreenState` |
| Map texto oración → ruta `.mp3` | `lib/data/models/data.dart` → `Data.prayersSounds` |
| Textos de oración por nombre | `lib/data/models/data.dart` → `Data.prayers` |
| Delay 100 ms / 15 s | `lib/constants/app_constants.dart` → `AppDelays` |
| Constantes rutas destacadas | mismo archivo → `AppAssets`, `AppAudio` |
| Preferencias ON/OFF | `lib/services/preferences_service.dart` + claves `AppPreferencesKeys.*` |
| Repaint + llamada recurrente cuenta | `lib/presentations/widgets/rosary_painter.dart` → `CuentasPainter` |
| Preferencias cargadas tras `initState` | `pray_screen.dart` → `_loadPrefs` |

---

## 10. Diagnóstico del problema reportado **(sin modificaciones)**

**Síntoma descrito históricamente:** en dispositivo real, reproducción alternante (una oración sí, siguiente fallo con mensaje “No se pudo reproducir el audio...”, siguiente vuelve a sonar…), o comportamiento relacionado donde la **etiqueta** de oración ya no coincide con el audio intentado cargar tras `stop`.

Este informe documenta código actual; los juicios siguientes son **hipótesis técnicas** compatible con ese código y biblioteca **just_audio**:

### Hipótesis A — **`completed` por `stop()` entre pistas**

Cada nueva oración ejecuta **`_prayerPlayer.stop()`** antes de cargar (**`audio_service.playPrayer`**).

El **`listen`** sólo observa **`ProcessingState.completed`** y no distingue el origen (**fin natural MP3 vs** transición tras **`stop`** programático ni estados intermedios en Android).

Por tanto es plausible que algunos **`completed`** aparezcan “de más”: disparan **`_incrementCounter`** moviendo **`_orderPrayer`** antes de que la UI/el mapa esperen el MP3 siguiente, causando combinaciones donde **`initAudio`** intenta cargar recurso equivocado para la posición efectiva percibida, o llega segunda petición corrida (**`_audioRequestId`**) abandonando trabajo intermedio. El resultado observado desde fuera puede ser **patrón en “dientes de sierra”** (algo acierta porque el siguiente `initAudio` queda estable, hasta el próximo ciclo rápido de `stop` + evento).

### Hipótesis B — **`CustomPainter`** no repinta al solo cambiar **`orderPrayer`**

Como **`shouldRepaint` no lista `orderPrayer`**, al avanzar oraciones dentro de una misma cuenta (mismo **`counter`**) **puede faltar nueva ejecución de `paint`** y de **`onCuentaHighlighted`** mientras otros caminos igual disparan llamadas asíncronas al player.

Esto **des sincroniza** “qué debería ser la etiqueta” vs **qué ejecuta efectivamente **`initAudio`**** en momentos muy concretos, sobre todo combinado con (**A**) o con **más de una** inicialización lanzada muy seguidas.

### Hipótesis C — **`_isIncrementingInProgress` queda prendido**

El flag sólo resetea dentro de **`initAudio`** al final bien resuelto bajo **`if (_isplaying)`** tras **`playPrayer`**.

Si existe **salida temprana**, **error silenciado categorizado esperado**, o **retorno ante mismatch de **`requestId`**** sin reiniciar ese flag después de una ruta que viene del stream, el listener ignora próximos **`completed`** porque cree que un increment está en proceso.

Este patrón puede traducirse en “a veces el auto-avance deja de alinearse hasta que algo más resetea estado” — la percepción final puede no ser estricamente uno-sí uno-no, pero **interfiere**.

### Hipótesis D — **mapas **`prayers`** / **`rosary`** no alineados con claves **`prayersSounds`****

Hay que que las **literales strings** configuradas como nombres de oración dentro de las estructuras de rosario (**`detail.prayers`** en datos de cuentas) coincidan carácter a carácter con las llaves **`Data.prayersSounds`**. Cualquier divergencia (acentos **`Pésame` vs **`Pesame`**, typo, texto normalizado) deja **`prayerSound` sin nueva asignación** y fuerza reproducir algo obsoleto o inválido antes de lanzar **`setAsset`**.

Este informe no audita todas las configuraciones físicas cuenta-a-cuenta, pero marca el punto de revisión (**`initAudio`** + datos `Data`) como **prioridad alta** ante síntomas de “solo ciertas etiquetas rompen siempre que las tocas”.

### Hipótesis E — **`delayMusic`** 15 segundos y concurrencias

Ventana muy larga ante **muchas combinaciones válidas**. No es causa por sí misma pero **multiplica probabilidad de carreras** si el usuario o la lógica togglean audio, si hay **extras `initAudio`**, o llegan errores tardíos antes de llegar al reset del semáforo.

---

### Conclusión diagnóstica (integrada)

Los puntos donde el sistema es **más sensible** ante fallos repetitivos están en las **interfaces entre tres dominios**:

1. **Eventos asíncronos de `just_audio` + `stop` siempre antes de nueva pista**.
2. **Avance determinista de texto en UI vía repaint del `CustomPainter` + **`_handleCuentaHighlighted`****.
3. **Semántica de **`_incrementCounter`/flags de concurrencia** vs **orden real de llegada de errores/async**.

Sin instrumentación adicional (**logs de orden de llamadas **`initAudio`**, **`completed`**, **`stop`**, **valores efectivos **`prayerSound`/`prayerLabel`/`requestId` en dispositivo) varias causas pueden coexistir. El problema **probable más global** ante el comportamiento tipo “saltos estrafalarios pero rítmicos” es (**A**) + (**B**) + potencial (**C**) en conjunto más que cualquier formato individual de archivo suelto.

---

## 11. Cierre

Este archivo está pensado como **referencia de lectura rápida** para orientarse en código y efectos indirectos antes de refactorizar (**p. ej. separar selección audio de repaint**, **enganchar **`processingState`/origen más fino desde `just_audio`**, etc.). Todo lo anterior intenta obedecer fielmente a la forma actual **declarativa** sin sugerencias de implementación ejecutables en código dentro de estas secciones.

---

_Fin del informe._
