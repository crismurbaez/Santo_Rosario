import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/models/app_error.dart';
import 'package:santo_rosario/services/audio_service.dart';
import 'package:santo_rosario/services/preferences_service.dart';
import '../../data/models/data.dart'; 
import '../widgets/rosary_painter.dart';
import '../widgets/prayer_dialog.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/scheduler.dart';

class PrayScreen extends StatefulWidget {

  const PrayScreen({
    super.key,
    required this.mystery,

  });
  final String? mystery;
      @override
    State<PrayScreen> createState() => _PrayScreenState();
}


class _PrayScreenState extends State<PrayScreen> {
  Map<String, ui.Image>? _loadedImages;
  int _counter = 0;
  int rosaryBeadCount = Data.rosaryCircleBeadCount + Data.rosaryExtensionBeadCount;
  int rosaryCircleBeadCount = Data.rosaryCircleBeadCount;
  List<String> _currentPrayers = [''];
  int _orderPrayer=0;
  int _orderMystery=0;
  bool _isDecrement = false; // Variable para controlar el decremento
  int _oldOrderPrayer=0;
  int _oldCounter = 0;
  
  Map<String, String> rosaryprayersSounds = Data.prayersSounds;
  late String prayerSound;
  final _audioService = AudioService();
  final _preferencesService = PreferencesService();
  bool _isplaying = false; //variable para controlar el audio
  bool _isBackgroundMusicPlaying = true; // Nuevo: controla si la música de fondo está activa
  bool _isPrayersAudioPlaying = true; // Nuevo: controla si el audio de las oraciones está activo
  bool _isIncrementingInProgress = false; //evita que se incremente dos veces al completar el audio automáticamente
  int _audioRequestId = 0; // Evita errores por carreras al tocar muy rapido.
  
  
  late String message;
  AppError? _currentError;

  bool _isBatterySaverActive = false; // Variable para controlar el wakelock

  /// Clave fijada al botón del menú (☰) para calcular dónde abrir [showMenu]:
  /// se usa el [RenderBox] del botón y el del [Overlay] y así el panel queda
  /// alineado bajo el icono (esquina superior derecha del botón).
  final GlobalKey _prayAudioMenuButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Activa el wakelock (pantalla siempre encendida)
    _loadAllImages(); // Inicia la carga de todas las imágenes  

    // Configura un listener que detecta cuando termina la reproducción
    _audioService.prayerPlayerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        if (!_isIncrementingInProgress) {
        // Se adelanta una oración cuando el audio termina
          _isIncrementingInProgress = true;
          _incrementCounter();
        }
      }
    });  
    _loadPrefs(); // Carga las preferencias guardadas
  }

  @override
  void didChangeDependencies() { //se llama inmediatamente después de initState() y también cada vez que las dependencias del StatefulWidget cambian
    super.didChangeDependencies();
    // Programa el SnackBar para que se muestre después de que el frame actual se haya construido
  SchedulerBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modo Pantalla Siempre Encendida'))
    );
  });
  }

    // Limpia los recursos del reproductor cuando el widget se desecha y el bloqueo de pantalla se desactiva
    @override
    void dispose() {
      _audioService.dispose();
      WakelockPlus.disable(); // Desactiva el wakelock (pantalla se apagará)
      super.dispose();
    }

    Future<void> _loadPrefs() async {
      final prayersAudioPlaying = await _preferencesService.getPrayerAudioPlaying();
      final backgroundMusicPlaying =
          await _preferencesService.getBackgroundMusicPlaying();
      setState(() {
        _isPrayersAudioPlaying = prayersAudioPlaying;
        _isBackgroundMusicPlaying = backgroundMusicPlaying;
      });
    }

    Future<void> _savePrefs() async {
      await _preferencesService.setPrayerAudioPlaying(_isPrayersAudioPlaying);
      await _preferencesService.setBackgroundMusicPlaying(_isBackgroundMusicPlaying);
    }

    // Activa o desactiva el wakelock según la variable _isBatterySaverActive
    void _toggleWakelock() {
      setState(() {
        _isBatterySaverActive = !_isBatterySaverActive;
        if (_isBatterySaverActive) {
          WakelockPlus.disable(); // Desactiva el wakelock (ahorro de batería)
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modo Ahorro de Batería: Activado (pantalla se apagará)'))
        );
        } else {
          WakelockPlus.enable(); // Activa el wakelock (pantalla siempre encendida)
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modo Pantalla Siempre Encendida'))
        );
      }
      });
    }

    Future<void> _loadBackgroundMusic() async {
      if (!_isBackgroundMusicPlaying) return; // Si la música de fondo no está activa, salimos

      try {
        await _audioService.playBackgroundMusic();
      } catch (e) {
        if (_isExpectedAudioInterruption(e)) {
          return;
        }
        _reportError(
          AppError(
            kind: ErrorKind.audio,
            severity: ErrorSeverity.warning,
            userMessage: 'No se pudo iniciar la música de fondo.',
            technicalMessage: e.toString(),
          ),
        );
      }
    }

    void initAudio() async {
      if (!_isPrayersAudioPlaying) return; // Si el audio de las oraciones no está activo, salimos
      final requestId = ++_audioRequestId;
      // Introduce un pequeño retraso
      // Esto le da tiempo al reproductor para finalizar cualquier proceso interno
      await Future.delayed(AppDelays.delayAudio);
      try {
        if (requestId != _audioRequestId || !_isplaying) {
          return;
        }
        if (rosaryprayersSounds[_currentPrayers[_orderPrayer]] != null) {
          prayerSound = rosaryprayersSounds[_currentPrayers[_orderPrayer]]!;
        }

        if (_currentPrayers[_orderPrayer] == 'Misterio') {
          String soundMystery = '${widget.mystery}${_orderMystery.toString()}';
          prayerSound = rosaryprayersSounds[soundMystery]!;
        }

        if (_isplaying) {
          //retraso de 15 segundos si el sonido es 'Señal de la Cruz' y la música de fondo está activa
          prayerSound == AppAssets.soundSignalOfTheCross && _isBackgroundMusicPlaying?
          await Future.delayed(AppDelays.delayMusic)
          : null;
          await _audioService.playPrayer(prayerSound);
          
          _isIncrementingInProgress = false;
        }
      } catch (e) {
        if (_isExpectedAudioInterruption(e)) {
          return;
        }
        _reportError(
          AppError(
            kind: ErrorKind.audio,
            severity: ErrorSeverity.warning,
            userMessage: 'No se pudo reproducir el audio de la oración actual.',
            technicalMessage: e.toString(),
          ),
        );
      }
    }

    void stopAudioBackground() async {
      await _audioService.stopBackgroundMusic();
      await Future.delayed(AppDelays.delayAudio);
    }

    void stopAudio() async {
      _audioRequestId++;
      await _audioService.stopPrayer();
      await Future.delayed(AppDelays.delayAudio);
    }

    bool _isExpectedAudioInterruption(Object error) {
      final text = error.toString().toLowerCase();
      return text.contains('loading interrupted') ||
          text.contains('playerinterruptedexception');
    }

    void _dismissError() {
      setState(() {
        _currentError = null;
      });
    }

    void _reportError(AppError error) {
      if (!mounted) return;
      setState(() {
        _currentError = error;
      });
      if (error.severity != ErrorSeverity.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
      }
      if (error.technicalMessage != null) {
        debugPrint(
          '[${error.kind.name}:${error.severity.name}] ${error.technicalMessage}',
        );
      }
    }

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
          _showAudioStatusSnackBar();
        });

    }
    
    // SnackBar unificado para el estado del audio
  void _showAudioStatusSnackBar() {
    if (!_isplaying) {
      message = 'Audio Desactivado (avance de oraciones manual)';
    } else {
      List<String> activeAudios = [];
      if (_isPrayersAudioPlaying) {
        activeAudios.add('Oraciones');
      }
      if (_isBackgroundMusicPlaying) {
        activeAudios.add('Música de fondo');
      }

      if (activeAudios.isEmpty) {
        message = 'Audio Activado pero sin Oraciones ni Música de fondo!!';
      } else if (activeAudios.length == 2 || 
                 (activeAudios.length == 1 && activeAudios[0] == 'Oraciones')) {
        message = 'Audio Activado (avance de oraciones automática)';
      } else  {
        message = 'Audio Activado, sólo Música de fondo (avance de oraciones manual)';
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    
  }
    
    // Función para alternar la reproducción de la música de fondo
    void _toggleBackgroundMusic() {
      setState(() {
        _isBackgroundMusicPlaying = !_isBackgroundMusicPlaying;
        _savePrefs(); // Guarda las preferencias
        if (_isBackgroundMusicPlaying && _isplaying) {
          _loadBackgroundMusic(); // Si se activa, la carga y reproduce
        } else {
          _audioService.stopBackgroundMusic(); // Si se desactiva, la detiene
        }
      });
      _showAudioStatusSnackBar();
    }

    // Función para alternar la reproducción del audio de las oraciones
    void _togglePrayersAudio() {
      setState(() {
        _isPrayersAudioPlaying = !_isPrayersAudioPlaying;
        _savePrefs(); // Guarda las preferencias
        if (_isPrayersAudioPlaying && _isplaying) { // Si se activa y el audio principal está encendido
          initAudio(); // Reproduce la oración actual
        } else {
          _audioService.stopPrayer(); // Si se desactiva, detiene el audio de la oración
        }
      });
      _showAudioStatusSnackBar();
    }



    void _incrementCounter() {
      setState(() {
          if (_orderPrayer < _currentPrayers.length-1) {
            _orderPrayer++;
            _isDecrement = false;
          } else {
            if (_counter < rosaryBeadCount-1) {
            _counter++; // Incrementa el contador
            _orderPrayer = 0;
            _isDecrement = false;
            }
          }
      });

    }
    void _decrementCounter() {
      setState(() {
        if (_orderPrayer > 0) {
          _orderPrayer--; // Decrementa el orden de oración
          _isDecrement = true;
        } else if (_counter > 0 && _orderPrayer == 0) {
          // Si estamos en la primera oración y el contador es mayor que 0, decrementamos el contador
          // y reiniciamos el orden de oración a 0.
          // Esto permite retroceder a la cuenta anterior.
          _counter--;  // Disminuye el contador
          _orderPrayer = 0;
          _isDecrement = true;
        }
      });
 
    }
    // Esta función se llama cuando una cuenta es resaltada
    // y actualiza las oraciones actuales y el orden del misterio.
    void _handleCuentaHighlighted(List<String> prayers, int orderMystery) {
      // Solo actualizamos si las oraciones son diferentes para evitar redibujados innecesarios
        if (_currentPrayers.toString() != prayers.toString() || 
          (_orderMystery != orderMystery) 
          )
        {
          // Usamos addPostFrameCallback para posponer la llamada a setState
          // hasta después de que el frame actual haya terminado de construirse.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentPrayers = prayers; // Actualiza las oraciones actuales
              _orderMystery = orderMystery; // Actualiza el orden del misterio
              if (_isDecrement) {
                _orderPrayer = prayers.length - 1; // Si es decremento, va al último elemento del array de oraciones
              } else {
                _orderPrayer = 0; // Si es incremento, reinicia el orden de oración
              }
            });
          });
        } 
        WidgetsBinding.instance.addPostFrameCallback((_) {
          //si cambia el orden de la oración en el array _currentPrayers
          // o si cambia el contador de avance de perla _counter
          if (_oldOrderPrayer!=_orderPrayer || _oldCounter != _counter) {
            initAudio();
            setState(() {
              _oldOrderPrayer = _orderPrayer;
              _oldCounter = _counter;
            });
          }
        });
    }

   // Función asíncrona para cargar todas las imágenes
  Future<void> _loadAllImages() async {
    final Map<String, ui.Image> images = {};
    for (var entry in Data.images.entries) {
      final String key = entry.key;
      final String assetPath = entry.value;
      try {
        // Carga el asset como ByteData
        final ByteData data = await rootBundle.load(assetPath);
        // Decodifica la imagen
        final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        images[key] = frameInfo.image;
      } catch (e) {
        _reportError(
          AppError(
            kind: ErrorKind.image,
            severity: ErrorSeverity.error,
            userMessage: 'No se pudo cargar una imagen necesaria del rosario.',
            technicalMessage:
                'Error cargando imagen: $key desde $assetPath - $e',
          ),
        );
      }
    }

    setState(() {
      _loadedImages = images; // Actualiza el estado con las imágenes cargadas
    });
  }

  void _handleDrawingError(String message) {
  _reportError(
    AppError(
      kind: ErrorKind.ui,
      severity: ErrorSeverity.warning,
      userMessage: 'Hubo un problema visual al dibujar el rosario.',
      technicalMessage: message,
    ),
  );
  }

  /// Menú de audio (música de fondo / audios de oraciones) con estilo glass.
  ///
  /// No usamos [PopupMenuButton] aquí porque su superficie Material no deja
  /// aplicar bien blur + transparencia como el resto de la UI; en su lugar
  /// [showMenu] con `color: Colors.transparent` y un único ítem deshabilitado
  /// que contiene el panel personalizado (toques → [Navigator.pop] con un id).
  Future<void> _showPrayGlassAudioMenu() async {
    final BuildContext? buttonContext = _prayAudioMenuButtonKey.currentContext;
    if (buttonContext == null || !buttonContext.mounted) return;

    final RenderBox button =
        buttonContext.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(buttonContext)
        .context
        .findRenderObject()! as RenderBox;

    // Rectángulo del botón en coordenadas del overlay: Flutter coloca el menú
    // justo debajo de este ancla (comportamiento estándar de [showMenu]).
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final String? choice = await showMenu<String>(
      context: context,
      position: position,
      // Sin tinte opaco del Material del menú: solo se ve nuestro panel glass.
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      // Nota: en algunas versiones de Flutter [showMenu] no expone [barrierColor];
      // si la tuya lo permite, puedes añadir p. ej. `barrierColor: Colors.black54`
      // para atenuar el fondo al abrir el menú.
      // Solo redondeo aquí; el borde fino va en el panel para coincidir con botones glass.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPrayGlass.menuBorderRadius),
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          // El ítem en sí no envía valor al pulsarlo: cada fila hace pop manual.
          enabled: false,
          padding: EdgeInsets.zero,
          // Altura fija: en SDKs donde [height] no admite null, hay que reservar
          // espacio para las dos filas + divisor (ajústala si cambias paddings).
          height: 120,
          child: Builder(
            builder: (BuildContext menuContext) {
              return _prayGlassAudioMenuPanel(
                menuContext: menuContext,
                isBackgroundMusicPlaying: _isBackgroundMusicPlaying,
                isPrayersAudioPlaying: _isPrayersAudioPlaying,
              );
            },
          ),
        ),
      ],
    );

    if (!mounted) return;
    if (choice == 'toggleBackgroundMusic') {
      _toggleBackgroundMusic();
    } else if (choice == 'togglePrayersAudio') {
      _togglePrayersAudio();
    }
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // Permite que el [body] (imagen de la Virgen) dibuje detrás del AppBar;
      // así el blur del flexibleSpace ve el mismo fondo que el resto de la pantalla.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Sin color sólido: el “vidrio” lo pinta [flexibleSpace].
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AppLayout.appBarToolbarHeight,
        centerTitle: true,
        // Iconos de estado (batería, hora…) en claro sobre fondo oscuro.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppPrayGlass.onGlassText,
          onPressed: () => Navigator.maybePop(context),
        ),
        // Capa bajo los iconos y títulos: blur + degradé + línea inferior.
        flexibleSpace: ClipRect(
          // Evita que el blur se “salga” del rectángulo del AppBar.
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: AppPrayGlass.blurSigma,
              sigmaY: AppPrayGlass.blurSigma,
            ),
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppPrayGlass.borderLight.withValues(alpha: 0.45),
                  ),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppPrayGlass.navBarGradientTop,
                    AppPrayGlass.navBarGradientBottom,
                  ],
                ),
              ),
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Santo Rosario',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: AppPrayGlass.onGlassText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Misterios ${widget.mystery}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: AppPrayGlass.onGlassTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBatterySaverActive ? Icons.battery_saver : Icons.highlight,
              color: AppPrayGlass.onGlassText,
            ),
            onPressed: _toggleWakelock, // Cambia el estado del wakelock
            tooltip: _isBatterySaverActive ? 'Activar Ahorro Batería' : 'Pantalla Siempre Encendida',
          ),
          IconButton(
            key: _prayAudioMenuButtonKey,
            icon: const Icon(
              Icons.menu,
              color: AppPrayGlass.onGlassText,
            ),
            tooltip: 'Opciones de audio',
            onPressed: _showPrayGlassAudioMenu,
          ),
        ],
      ),
      // Fondo + rosario + controles en capas. El orden importa: lo primero queda detrás.
      body: Stack (
        children: <Widget>[
          Container(
            color: AppColors.colorBackgroundBody,
          ),
           Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AppAssets.imageVirgenLourdes),
                          fit: BoxFit.fitHeight,
                        ),
                      ),
          ),
          // Reserva espacio bajo el AppBar transparente para que el rosario no quede tapado.
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + AppLayout.appBarToolbarHeight,
            ),
            child: Center(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Muestra un indicador de carga si las imágenes aún no se han cargado
                  if (_loadedImages == null) {
                    return const CircularProgressIndicator(
                      color: AppColors.colorCircularProgressIndicator,
                    );
                  }

                  // se obtienen las dimensiones de la pantalla
                  //y se saca un porcentaje que se considera el margen adaptable a todas las pantallas
                  final double width =
                      AppLayout.rosaryWidthFactor * constraints.maxWidth;
                  final double height =
                      AppLayout.rosaryHeightFactor * constraints.maxHeight;

                  return SizedBox(
                    width: width,
                    height: height,
                    child: CustomPaint(
                      painter: CuentasPainter(
                        cuentas: _loadedImages!,
                        counter: _counter,
                        rosaryBeadCount: rosaryBeadCount,
                        rosaryCircleBeadCount: rosaryCircleBeadCount,
                        onCuentaHighlighted: _handleCuentaHighlighted,
                        orderPrayer: _orderPrayer,
                        onDrawingError: _handleDrawingError,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
            // Controles inferiores: mismo lenguaje visual glass que la AppBar.
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Column(
                // La columna solo ocupa el espacio que necesitan sus hijos
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppLayout.sectionPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _prayGlassRoundButton(
                          onPressed: playPause,
                          child: Icon(
                            _isplaying ? Icons.volume_up : Icons.volume_off,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppLayout.sectionPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _prayGlassRoundButton(
                          onPressed: _decrementCounter,
                          child: const Icon(Icons.arrow_back),
                        ),
                        _prayGlassRoundButton(
                          onPressed: _incrementCounter,
                          child: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppLayout.sectionPadding),
                    // Mismo ancho interior que la fila de flechas: de borde a borde
                    // de los dos círculos (LayoutBuilder = ancho tras el padding).
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return _prayGlassPillButton(
                          width: constraints.maxWidth,
                          label: _currentPrayers[_orderPrayer],
                          onPressed: () {
                            // Muestra el diálogo con las oraciones actuales
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return PrayerDialog(
                                  prayer: _currentPrayers[_orderPrayer],
                                  mystery: widget.mystery,
                                  currentMysteryOrder: _orderMystery,
                                  errorMessage:
                                      _currentError?.userMessage ?? '',
                                );
                              },
                            );
                          },
                          trailing: const Icon(
                            Icons.info_outline,
                            size: AppLayout.infoIconSize,
                            // Mismo color que el texto del botón inferior.
                            color: AppColors.colorCircularProgressIndicator,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ),
         Positioned(
            top: AppLayout.errorBannerInset,
            left: AppLayout.errorBannerInset,
            right: AppLayout.errorBannerInset,
            child: IgnorePointer(
              ignoring: !(_currentError != null &&
                  _currentError!.severity == ErrorSeverity.error),
              child: AnimatedSlide(
                offset: (_currentError != null &&
                        _currentError!.severity == ErrorSeverity.error)
                    ? Offset.zero
                    : const Offset(0, -0.2),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: (_currentError != null &&
                          _currentError!.severity == ErrorSeverity.error)
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.colorBackgroundDialogError,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentError?.userMessage ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _dismissError,
                            tooltip: 'Cerrar',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]
      )
    );
  }
}

/// Contenido visual del menú de audio: mismo patrón que los botones (blur + tinte + borde).
///
/// **Parámetros**
/// - [menuContext]: contexto del menú abierto por [showMenu]; obligatorio para que
///   [Navigator.pop] cierre el overlay del menú y devuelva el [String] a `_showPrayGlassAudioMenu`.
/// - [isBackgroundMusicPlaying] / [isPrayersAudioPlaying]: reflejan el estado actual;
///   si cambias los textos o iconos, hazlo aquí.
///
/// **Personalización rápida**
/// - Más aire entre filas: aumenta el `vertical` del [Padding] de cada [InkWell].
/// - Tipografía del menú: cambia [rowStyle] (por defecto Poppins como el subtítulo de la AppBar).
/// - Colores de los iconos: [AppPrayGlass.menuIconMusic] y [AppPrayGlass.menuIconPrayers].
Widget _prayGlassAudioMenuPanel({
  required BuildContext menuContext,
  required bool isBackgroundMusicPlaying,
  required bool isPrayersAudioPlaying,
}) {
  const TextStyle rowStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppPrayGlass.onGlassText,
  );

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppPrayGlass.menuBorderRadius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: AppPrayGlass.blurSigma,
        sigmaY: AppPrayGlass.blurSigma,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppPrayGlass.frostedTint,
          borderRadius: BorderRadius.circular(AppPrayGlass.menuBorderRadius),
          border: Border.all(color: AppPrayGlass.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => Navigator.pop<String>(
                menuContext,
                'toggleBackgroundMusic',
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isBackgroundMusicPlaying
                          ? Icons.music_note
                          : Icons.music_off,
                      color: AppPrayGlass.menuIconMusic,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBackgroundMusicPlaying
                            ? 'Música de Fondo: ON'
                            : 'Música de Fondo: OFF',
                        style: rowStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppPrayGlass.borderLight.withValues(alpha: 0.35),
            ),
            InkWell(
              onTap: () => Navigator.pop<String>(
                menuContext,
                'togglePrayersAudio',
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isPrayersAudioPlaying
                          ? Icons.record_voice_over
                          : Icons.volume_mute,
                      color: AppPrayGlass.menuIconPrayers,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPrayersAudioPlaying
                            ? 'Audios Oraciones: ON'
                            : 'Audios Oraciones: OFF',
                        style: rowStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Botón circular glass (volumen, anterior, siguiente).
///
/// Estructura: [Material] transparente → [InkWell] con hitTest circular → [ClipOval]
/// → [BackdropFilter] (desenfoque del contenido detrás) → [Container] con tinte y borde.
/// Los iconos heredan color y tamaño vía [IconTheme].
///
/// **Para modificar**
/// - Tamaño: [AppPrayGlass.roundButtonSize].
/// - Intensidad del efecto: [AppPrayGlass.blurSigma], [frostedTint], [borderLight].
Widget _prayGlassRoundButton({
  required VoidCallback onPressed,
  required Widget child,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppPrayGlass.blurSigma,
            sigmaY: AppPrayGlass.blurSigma,
          ),
          child: Container(
            width: AppPrayGlass.roundButtonSize,
            height: AppPrayGlass.roundButtonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPrayGlass.frostedTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppPrayGlass.borderLight),
            ),
            child: IconTheme(
              data: const IconThemeData(
                color: AppPrayGlass.onGlassText,
                size: 24,
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Botón ancho tipo “pastilla” para el nombre de la oración actual + icono de info.
///
/// Mismo stack que el circular pero con [ClipRRect] y [AppPrayGlass.pillRadius].
/// El texto usa Playfair para alinearlo con el título “Santo Rosario”.
///
/// Si pasas [width] (p. ej. el `maxWidth` de un [LayoutBuilder] con el mismo
/// [Padding] que la fila de flechas), la pastilla ocupa todo ese ancho: alineado
/// visualmente con el espacio entre los dos botones circulares.
///
/// **Para modificar**
/// - Márgenes internos del texto: `padding` del [Container] interior.
/// - Máximo de líneas del título: [Text.maxLines] (ahora 2 + ellipsis).
Widget _prayGlassPillButton({
  required String label,
  required VoidCallback onPressed,
  Widget? trailing,
  double? width,
}) {
  const TextStyle pillTextStyle = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    // Mismo dorado del título en PrayerDialog para mantener coherencia visual.
    color: AppColors.colorCircularProgressIndicator,
  );

  final Widget row = width != null
      ? Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: pillTextStyle,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppLayout.rowItemSpacing),
              trailing,
            ],
          ],
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: pillTextStyle,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppLayout.rowItemSpacing),
              trailing,
            ],
          ],
        );

  final Widget core = Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppPrayGlass.pillRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppPrayGlass.pillRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppPrayGlass.blurSigma,
            sigmaY: AppPrayGlass.blurSigma,
          ),
          child: Container(
            width: width != null ? double.infinity : null,
            // Igualamos la altura del pill con los botones circulares.
            height: AppPrayGlass.roundButtonSize,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppPrayGlass.pillRadius),
              color: AppPrayGlass.frostedTint,
              border: Border.all(color: AppPrayGlass.borderLight),
            ),
            child: row,
          ),
        ),
      ),
    ),
  );

  if (width != null) {
    return SizedBox(width: width, child: core);
  }
  return core;
}

