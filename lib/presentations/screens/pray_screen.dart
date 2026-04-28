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
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: AppLayout.appBarToolbarHeight,
         title: 
             Column(
              children: [
                ListTile(
                  title: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Santo Rosario',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.left
                    ),
                  ),
                  subtitle: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Misterios ${widget.mystery}',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBatterySaverActive ? Icons.battery_saver : Icons.highlight,
              color: Theme.of(context).textTheme.displaySmall!.color,
            ),
            onPressed: _toggleWakelock, // Cambia el estado del wakelock
            tooltip: _isBatterySaverActive ? 'Activar Ahorro Batería' : 'Pantalla Siempre Encendida',
          ),
          // Nuevo: Botón de menú de configuración de audio
          PopupMenuButton<String>(
            icon: Icon(
              Icons.menu, // Ícono de configuración
              color: Theme.of(context).textTheme.displaySmall!.color,
            ),
            onSelected: (value) {
              if (value == 'toggleBackgroundMusic') {
                _toggleBackgroundMusic();
              } else if (value == 'togglePrayersAudio') {
                _togglePrayersAudio();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'toggleBackgroundMusic',
                child: Row(
                  children: [
                    Icon(_isBackgroundMusicPlaying ? Icons.music_note : Icons.music_off),
                    const SizedBox(width: 8),
                    Text(_isBackgroundMusicPlaying ? 'Música de Fondo: ON' : 'Música de Fondo: OFF'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'togglePrayersAudio',
                child: Row(
                  children: [
                    Icon(_isPrayersAudioPlaying ? Icons.record_voice_over : Icons.volume_mute),
                    const SizedBox(width: 8),
                    Text(_isPrayersAudioPlaying ? 'Audios Oraciones: ON' : 'Audios Oraciones: OFF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
          Center(
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
                final double width = AppLayout.rosaryWidthFactor * constraints.maxWidth;
                final double height = AppLayout.rosaryHeightFactor * constraints.maxHeight;  

                return 
                SizedBox(
                  width: width,
                  height: height,
                  child: 
                  CustomPaint(
                    painter : CuentasPainter(
                      cuentas: _loadedImages!,
                      counter: _counter,
                      rosaryBeadCount: rosaryBeadCount,
                      rosaryCircleBeadCount: rosaryCircleBeadCount,
                      onCuentaHighlighted: _handleCuentaHighlighted, 
                      orderPrayer: _orderPrayer, 
                      onDrawingError: _handleDrawingError,
                    )
                  ),
                );
            }),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min, // La columna solo ocupa el espacio que necesitan sus hijos
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppLayout.sectionPadding),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children:[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorButtonPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppLayout.buttonHorizontalPadding,
                              vertical: AppLayout.buttonVerticalPadding,
                            ),
                          ),
                          onPressed: playPause,
                          //se cambia el ícono de acuerdo a si el audio está activado o no
                          child: Icon(_isplaying ? Icons.volume_up : Icons.volume_off),
                        ),
                      ]
                    )
                  ),
                  Padding(
                        padding: const EdgeInsets.all(AppLayout.sectionPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.colorButtonPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppLayout.buttonHorizontalPadding,
                                  vertical: AppLayout.buttonVerticalPadding,
                                ),
                              ),
                              onPressed: _decrementCounter,
                              child: const Icon(Icons.arrow_back),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.colorButtonPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppLayout.buttonHorizontalPadding,
                                  vertical: AppLayout.buttonVerticalPadding,
                                ),
                              ),
                              onPressed: _incrementCounter,
                              child: const Icon(Icons.arrow_forward),
                            ),
                          ]
                        ),
                  ),
                  Padding(
                        padding: const EdgeInsets.all(AppLayout.sectionPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.colorButtonPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppLayout.buttonHorizontalPadding,
                                  vertical: AppLayout.buttonVerticalPadding,
                                ),
                              ),
                              onPressed: () {
                                // Muestra el diálogo con las oraciones actuales
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return PrayerDialog(
                                      prayer: _currentPrayers[_orderPrayer], 
                                      mystery: widget.mystery,
                                      currentMysteryOrder:_orderMystery, 
                                      errorMessage: _currentError?.userMessage ?? '',
                                    );
                                  },
                                );
                              },
                              child: Row(
                                children: [
                                  Text(_currentPrayers[_orderPrayer]),
                                  const SizedBox(width: AppLayout.rowItemSpacing), // Espacio entre el texto y el ícono
                                  const Icon(Icons.info_outline, size: AppLayout.infoIconSize), //  ícono
                                ],
                              ),
                            ),
                          ]
                        ),
                  ),
                ],
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

