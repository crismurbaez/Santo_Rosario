import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' show max, sin, pi, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/models/app_error.dart';
import 'package:santo_rosario/models/prayer_progress_snapshot.dart';
import 'package:santo_rosario/providers/audio_provider.dart';
import 'package:santo_rosario/services/error_log_service.dart';
import 'package:santo_rosario/services/error_reporter.dart';
import 'package:santo_rosario/services/preferences_service.dart';
import '../../data/models/data.dart';
import '../widgets/rosary_painter.dart';
import '../widgets/prayer_dialog.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../utils/snack_bar_utils.dart';

/// ============================================================================
/// 📐 MODO GUÍAS VISUALES DE DIAGNÓSTICO
/// Cambiá a `true` para ver en pantalla todos los recuadros de colores y dimensiones.
/// Cambiá a `false` (o comentá) para ocultarlo todo de una sola vez.
/// ============================================================================
const bool showRosaryDebugGuides = false;

class PrayScreen extends ConsumerStatefulWidget {
  const PrayScreen({
    super.key,
    required this.mystery,
    this.launchFromAlarmAutoStartGuidedAudio = false,
    this.voiceDelay = 0,
  });

  final String? mystery;

  /// Al abrir desde alarma programada: inicia sesión reproduciendo oraciones guiadas.
  final bool launchFromAlarmAutoStartGuidedAudio;

  /// Retardo en segundos antes de que empiece la voz.
  final int voiceDelay;

  @override
  ConsumerState<PrayScreen> createState() => _PrayScreenState();
}

class _PrayScreenState extends ConsumerState<PrayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Map<String, ui.Image>? _loadedImages;
  int _counter = 0;
  int rosaryBeadCount =
      Data.rosaryCircleBeadCount + Data.rosaryExtensionBeadCount;
  int rosaryCircleBeadCount = Data.rosaryCircleBeadCount;
  List<String> _currentPrayers = [''];
  int _orderPrayer = 0;
  int _orderMystery = 0;
  bool _isDecrement = false; // Variable para controlar el decremento
  int _oldOrderPrayer = 0;
  int _oldCounter = 0;

  Map<String, String> rosaryprayersSounds = Data.prayersSounds;
  String? prayerSound;
  final _preferencesService = PreferencesService();
  bool _isplaying = false; //variable para controlar el audio
  bool _isBackgroundMusicPlaying =
      true; // Nuevo: controla si la música de fondo está activa
  bool _isPrayersAudioPlaying =
      true; // Nuevo: controla si el audio de las oraciones está activo

  // Debounce para el botón de audio
  bool _audioSessionButtonLocked = false;
  Timer? _audioSessionButtonDebounceTimer;

  AppError? _currentError;
  final List<_HelpMessageDefinition> _helpMessageQueue = [];
  _HelpMessageDefinition? _activeHelpMessage;
  bool _didBuildHelpQueue = false;

  bool _isBatterySaverActive = false; // Variable para controlar el wakelock
  late final dynamic _audioHandler;

  /// Tras cargar estado guardado; la primera cuenta resaltada no debe pisar `_orderPrayer`.
  bool _pendingProgressRestore = false;

  /// Tras un salto misterio→misterio: la primera actualización del pintor no debe poner `_orderPrayer` en 0.
  bool _explicitOrderPrayerAfterHighlight = false;
  int _explicitOrderPrayerTargetIndex = 0;

  /// Texto «Nº misterio»: sólo se actualiza cuando [_currentPrayers]/[_orderPrayer] es «Misterio».
  bool _mysteryGlassLabelReady = false;
  int _mysteryGlassLabelOrder = 1;

  /// Una sola vez: arranque automático tras alarma cuando imágenes y prefs están listos.
  bool _alarmGuidedVoiceAutoStartApplied = false;

  final GlobalKey _wakelockButtonKey = GlobalKey();

  /// Origen para convertir [GlobalKey] del AppBar / body a coordenadas del
  /// [Stack] del [Scaffold.body]; [Positioned] del body no usa coordenadas globales.
  final GlobalKey _prayBodyStackKey = GlobalKey();
  final GlobalKey _playPauseButtonKey = GlobalKey();
  final GlobalKey _prevButtonKey = GlobalKey();
  final GlobalKey _nextButtonKey = GlobalKey();
  final GlobalKey _pillButtonKey = GlobalKey();
  final GlobalKey _mysteryNavTripleButtonKey = GlobalKey();
  final GlobalKey _playbackTripleButtonKey = GlobalKey();

  /// Clave fijada al botón del menú (☰) para calcular dónde abrir [showMenu]:
  /// se usa el [RenderBox] del botón y el del [Overlay] y así el panel queda
  /// alineado bajo el icono (esquina superior derecha del botón).
  final GlobalKey _prayAudioMenuButtonKey = GlobalKey();
  final _errorLogService = ErrorLogService();
  final _errorReporter = ErrorReporter();

  late final AnimationController _tutorialArrowPulseController;
  late final Animation<double> _tutorialArrowPulse;

  void _syncTutorialArrowAnimation() {
    if (!mounted) return;
    final showArrows = _activeHelpMessage != null;
    if (showArrows) {
      if (!_tutorialArrowPulseController.isAnimating) {
        _tutorialArrowPulseController.repeat(reverse: true);
      }
    } else {
      _tutorialArrowPulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void initState() {
    super.initState();
    _audioHandler = ref.read(audioHandlerProvider);
    WidgetsBinding.instance.addObserver(this);
    _tutorialArrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tutorialArrowPulse = CurvedAnimation(
      parent: _tutorialArrowPulseController,
      curve: Curves.easeInOut,
    );
    WakelockPlus.enable(); // Activa el wakelock (pantalla siempre encendida)
    _loadAllImages(); // Inicia la carga de todas las imágenes
    _loadPrefs(); // Carga las preferencias guardadas

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncHandlerParams();
    });
  }

  void _syncHandlerParams() {
    if (!mounted) return;
    ref
        .read(audioHandlerProvider)
        .updateParams(
          counter: _counter,
          orderPrayer: _orderPrayer,
          orderMystery: _orderMystery,
          mystery: widget.mystery,
          isBackgroundMusicPlaying: _isBackgroundMusicPlaying,
          isPrayersAudioPlaying: _isPrayersAudioPlaying,
        );
  }

  // Limpia los recursos del reproductor cuando el widget se desecha y el bloqueo de pantalla se desactiva
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistProgressSnapshotFromState();
    _audioSessionButtonDebounceTimer?.cancel();
    _audioSessionButtonDebounceTimer = null;
    _tutorialArrowPulseController.dispose();
    WakelockPlus.disable(); // Desactiva el wakelock (pantalla se apagará)

    // Detener el audio al salir de la pantalla (botón atrás)
    _audioHandler.stop();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _persistProgressSnapshotFromState();
        break;
      case AppLifecycleState.detached:
        _persistProgressSnapshotFromState();
        // Detener el audio completamente cuando la app se cierra
        _audioHandler.stop();
        break;
      case AppLifecycleState.resumed:
        final currentItem = _audioHandler.mediaItem.value;
        if (currentItem != null && currentItem.extras != null) {
          final hCounter = currentItem.extras!['counter'] as int?;
          final hOrderPrayer = currentItem.extras!['orderPrayer'] as int?;
          final hOrderMystery = currentItem.extras!['orderMystery'] as int?;
          if (hCounter != null && hOrderPrayer != null) {
            if (hCounter != _counter || hOrderPrayer != _orderPrayer) {
              setState(() {
                _counter = hCounter;
                _orderPrayer = hOrderPrayer;
                if (hOrderMystery != null) _orderMystery = hOrderMystery;
                _currentPrayers = Data.rosaryBeadSteps[hCounter].prayers;
                _maybeUpdateMysteryGlassLabelFromPill();
              });
            }
          }
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Rotación o cambios de tamaño/viewPadding: tras el layout hay que recomputar
  /// anchors de [_rectInPrayBodyStack]; durante el mismo [build] el [RenderBox]
  /// puede ser aún el del frame anterior.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _refreshTutorialArrowsAfterLayout(doublePostFrame: true);
  }

  bool _hasMeaningfulPrayers() {
    if (_currentPrayers.isEmpty) return false;
    if (_currentPrayers.length > 1) return true;
    return _currentPrayers[0].trim().isNotEmpty;
  }

  /// [_orderPrayer] puede quedar fuera de rango al restaurar avance antes de que el
  /// pintor asigne [_currentPrayers] de la cuenta actual (evita [RangeError] en UI/audio).
  int get _safeOrderPrayerIndex {
    if (_currentPrayers.isEmpty) return 0;
    final max = _currentPrayers.length - 1;
    return _orderPrayer.clamp(0, max);
  }

  String get _safeCurrentPrayerLabel =>
      _currentPrayers.isEmpty ? '' : _currentPrayers[_safeOrderPrayerIndex];

  bool _isRosaryComplete() {
    return PrayerProgressSnapshot.computeComplete(
      counter: _counter,
      orderPrayer: _orderPrayer,
      rosaryBeadCount: rosaryBeadCount,
      currentPrayersLength: _currentPrayers.length,
      prayersMeaningful: _hasMeaningfulPrayers(),
    );
  }

  void _persistProgressSnapshotFromState() {
    final mysteryStr = widget.mystery ?? '';
    if (mysteryStr.isEmpty || _loadedImages == null) return;
    final capturedCounter = _counter;
    final capturedOrderPrayer = _orderPrayer;
    final capturedOrderMystery = _orderMystery;
    final plist = List<String>.from(_currentPrayers);
    final beadTotal = rosaryBeadCount;
    Future.microtask(() async {
      try {
        if (!(await _preferencesService.getSavePrayerProgressEnabled())) {
          return;
        }
        final meaningful =
            plist.isNotEmpty &&
            (plist.length > 1 || plist.first.trim().isNotEmpty);
        final complete = PrayerProgressSnapshot.computeComplete(
          counter: capturedCounter,
          orderPrayer: capturedOrderPrayer,
          rosaryBeadCount: beadTotal,
          currentPrayersLength: plist.length,
          prayersMeaningful: meaningful,
        );
        if (complete) {
          await _preferencesService.clearPrayerProgressSnapshot();
          return;
        }
        await _preferencesService.savePrayerProgressSnapshot(
          PrayerProgressSnapshot(
            mystery: mysteryStr,
            counter: capturedCounter.clamp(0, beadTotal - 1),
            orderPrayer: capturedOrderPrayer,
            orderMystery: capturedOrderMystery,
          ),
        );
      } catch (_) {
        /* no bloquear cierre ni navegación */
      }
    });
  }

  Future<void> _tryRestorePrayerProgress() async {
    final mysteryStr = widget.mystery;
    if (mysteryStr == null || mysteryStr.isEmpty) return;
    if (!(await _preferencesService.getSavePrayerProgressEnabled())) return;
    final snap = await _preferencesService.loadPrayerProgressSnapshot();
    if (snap == null || snap.mystery != mysteryStr) return;
    final maxBeadIndex = rosaryBeadCount - 1;
    final c = snap.counter.clamp(0, maxBeadIndex);
    if (!mounted) return;
    setState(() {
      _counter = c;
      _orderPrayer = snap.orderPrayer;
      _orderMystery = snap.orderMystery;
      _pendingProgressRestore = true;
      _oldCounter = c;
      _oldOrderPrayer = snap.orderPrayer;
    });
  }

  Future<void> _loadPrefs() async {
    final prayersAudioPlaying = await _preferencesService
        .getPrayerAudioPlaying();
    final backgroundMusicPlaying = await _preferencesService
        .getBackgroundMusicPlaying();
    await _buildHelpMessageQueueOnce();
    await _tryRestorePrayerProgress();
    if (!mounted) return;
    setState(() {
      _isPrayersAudioPlaying = prayersAudioPlaying;
      _isBackgroundMusicPlaying = backgroundMusicPlaying;
      if (widget.launchFromAlarmAutoStartGuidedAudio) {
        _isPrayersAudioPlaying = true;
        _isplaying = true;
      }
    });
    _maybeAutoStartAlarmGuidedSession();
  }

  void _maybeAutoStartAlarmGuidedSession() {
    if (!widget.launchFromAlarmAutoStartGuidedAudio) return;
    if (_alarmGuidedVoiceAutoStartApplied) return;
    if (_loadedImages == null) return;
    if (!_isplaying || !_isPrayersAudioPlaying) return;
    _alarmGuidedVoiceAutoStartApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Aplicar retardo si existe
      if (widget.voiceDelay > 0) {
        await Future.delayed(Duration(seconds: widget.voiceDelay));
        if (!mounted || !_isplaying) return;
      }

      _syncHandlerParams();
      ref.read(audioHandlerProvider).play();
    });
  }

  Future<void> _savePrefs() async {
    await _preferencesService.setPrayerAudioPlaying(_isPrayersAudioPlaying);
    await _preferencesService.setBackgroundMusicPlaying(
      _isBackgroundMusicPlaying,
    );
  }

  Future<void> _buildHelpMessageQueueOnce() async {
    if (_didBuildHelpQueue) return;
    _didBuildHelpQueue = true;
    final helpCatalog = <_HelpMessageDefinition>[
      const _HelpMessageDefinition(
        id: AppHelpMessageIds.prayNavigation,
        text:
            'Tip: Haz click en el botón central para leer la oración y usa las flechas para avanzar o volver cuenta por cuenta.',
      ),
      const _HelpMessageDefinition(
        id: AppHelpMessageIds.prayAudioBehavior,
        text:
            'Usa el botón de play para activar el audio. Y las oraciones guiadas por voz realizarán un avance automático. Si lo desactivas con el botón de stop, el avance es manual.',
      ),
      const _HelpMessageDefinition(
        id: AppHelpMessageIds.prayAudioMenu,
        text:
            'Tip: en el menú puedes activar o desactivar por separado la música de fondo y las oraciones guiadas por voz. Si desactivas la voz, el avance es manual.',
      ),
      const _HelpMessageDefinition(
        id: AppHelpMessageIds.prayMysteryNavigation,
        text:
            'Tip: usa los botones «Misterio anterior» y «Misterio siguiente » para saltar entre misterios. Y haz click en el botón central en forma de libro para leer el misterio en cualquier momento.',
      ),
      const _HelpMessageDefinition(
        id: AppHelpMessageIds.prayKeepScreenOn,
        text:
            'Tip: esta pantalla queda siempre activa para acompañar la oración. Puedes cambiarlo con el ícono de bombilla, y se apagará la pantalla de acuerdo a tu configuración.',
      ),
    ];

    final pending = <_HelpMessageDefinition>[];
    for (final helpMessage in helpCatalog) {
      final dismissed = await _preferencesService.isHelpMessageDismissed(
        helpMessage.id,
      );
      if (!dismissed) {
        pending.add(helpMessage);
      }
    }
    if (!mounted || pending.isEmpty) return;
    setState(() {
      _helpMessageQueue
        ..clear()
        ..addAll(pending);
      _activeHelpMessage = _helpMessageQueue.first;
    });
    _syncTutorialArrowAnimation();
    _refreshTutorialArrowsAfterLayout(doublePostFrame: false);
  }

  Future<void> _dismissActiveHelpMessage({
    required bool disablePermanently,
  }) async {
    final activeMessage = _activeHelpMessage;
    if (activeMessage == null) return;
    if (disablePermanently) {
      await _preferencesService.setHelpMessageDismissed(activeMessage.id, true);
    }
    if (!mounted) return;
    setState(() {
      if (_helpMessageQueue.isNotEmpty) {
        _helpMessageQueue.removeAt(0);
      }
      _activeHelpMessage = _helpMessageQueue.isNotEmpty
          ? _helpMessageQueue.first
          : null;
    });
    _syncTutorialArrowAnimation();
    _refreshTutorialArrowsAfterLayout(doublePostFrame: false);
  }

  /// Fuerza un [setState] **después** del layout para re-leer posiciones por
  /// [GlobalKey] (tutorial y panel). [doublePostFrame] ayuda al pasar retrato ↔
  /// horizontal, donde una sola espera puede dejar anchors viejos.
  void _refreshTutorialArrowsAfterLayout({required bool doublePostFrame}) {
    void scheduleRebuild() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _activeHelpMessage == null) {
          return;
        }
        setState(() {
          // Sin campos: solo repaint con RenderBox ya actualizado.
        });
        _syncTutorialArrowAnimation();
      });
    }

    if (doublePostFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        scheduleRebuild();
      });
    } else {
      scheduleRebuild();
    }
  }

  /// Posición Y en el [Stack] del body equivalente a una Y en coordenadas globales.
  double _yGlobalToPrayBodyStack(BuildContext context, double yGlobal) {
    final stackBox =
        _prayBodyStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) {
      return yGlobal;
    }
    return stackBox.globalToLocal(Offset(0, yGlobal)).dy;
  }

  /// [Rect] del widget [targetKey] en coordenadas del [Stack] del body.
  Rect? _rectInPrayBodyStack(GlobalKey targetKey) {
    final stackContext = _prayBodyStackKey.currentContext;
    final targetContext = targetKey.currentContext;
    if (stackContext == null || targetContext == null) {
      return null;
    }
    final stackRender = stackContext.findRenderObject();
    final targetRender = targetContext.findRenderObject();
    if (stackRender is! RenderBox ||
        targetRender is! RenderBox ||
        !stackRender.hasSize ||
        !targetRender.hasSize) {
      return null;
    }
    final topLeft = stackRender.globalToLocal(
      targetRender.localToGlobal(Offset.zero),
    );
    final size = targetRender.size;
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
  }

  /// Flechas del tutorial según el tip activo (coords. del [Stack] del body).
  List<Widget> _buildTutorialArrowOverlays(BuildContext context) {
    final id = _activeHelpMessage?.id;
    if (id == null) {
      return const <Widget>[];
    }

    double clampW = MediaQuery.sizeOf(context).width;
    final stackRo = _prayBodyStackKey.currentContext?.findRenderObject();
    if (stackRo is RenderBox && stackRo.hasSize) {
      clampW = stackRo.size.width;
    }

    const double arrowSize = 44;
    const double arrowHalf = arrowSize / 2;
    const double belowIconGap = 8;
    const double aboveButtonOffset = 42;

    Widget arrowLayer({
      required double left,
      required double top,
      required IconData icon,
    }) {
      final arrowIcon = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: arrowSize,
          color: AppColors.colorCircularProgressIndicator,
        ),
      );
      return Positioned(
        left: left.clamp(8.0, clampW - arrowSize - 8.0),
        top: top,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _tutorialArrowPulse,
            builder: (context, _) {
              final w = sin(_tutorialArrowPulse.value * 2 * pi);
              return Transform.translate(
                offset: Offset(0, -8 * w),
                child: Transform.scale(
                  scale: 1.0 + 0.12 * w.abs(),
                  child: arrowIcon,
                ),
              );
            },
          ),
        ),
      );
    }

    switch (id) {
      case AppHelpMessageIds.prayKeepScreenOn:
        final r = _rectInPrayBodyStack(_wakelockButtonKey);
        if (r == null) return const <Widget>[];
        return [
          arrowLayer(
            left: r.center.dx - arrowHalf,
            top: r.bottom + belowIconGap,
            icon: Icons.keyboard_arrow_up_rounded,
          ),
        ];
      case AppHelpMessageIds.prayAudioMenu:
        final r = _rectInPrayBodyStack(_prayAudioMenuButtonKey);
        if (r == null) return const <Widget>[];
        return [
          arrowLayer(
            left: r.center.dx - arrowHalf,
            top: r.bottom + belowIconGap,
            icon: Icons.keyboard_arrow_up_rounded,
          ),
        ];
      case AppHelpMessageIds.prayNavigation:
        final back = _rectInPrayBodyStack(_prevButtonKey);
        final next = _rectInPrayBodyStack(_nextButtonKey);
        final pill = _rectInPrayBodyStack(_pillButtonKey);
        return <Widget>[
          if (back != null)
            arrowLayer(
              left: back.center.dx - arrowHalf,
              top: back.top - aboveButtonOffset,
              icon: Icons.keyboard_arrow_down_rounded,
            ),
          if (next != null)
            arrowLayer(
              left: next.center.dx - arrowHalf,
              top: next.top - aboveButtonOffset,
              icon: Icons.keyboard_arrow_down_rounded,
            ),
          if (pill != null)
            arrowLayer(
              left: pill.center.dx - arrowHalf,
              top: pill.top - aboveButtonOffset,
              icon: Icons.keyboard_arrow_down_rounded,
            ),
        ];
      case AppHelpMessageIds.prayMysteryNavigation:
        final r = _rectInPrayBodyStack(_mysteryNavTripleButtonKey);
        if (r == null) return const <Widget>[];
        return <Widget>[
          arrowLayer(
            left: r.left + r.width * 0.2 - arrowHalf,
            top: r.top - aboveButtonOffset,
            icon: Icons.keyboard_arrow_down_rounded,
          ),
          arrowLayer(
            left: r.left + r.width * 0.8 - arrowHalf,
            top: r.top - aboveButtonOffset,
            icon: Icons.keyboard_arrow_down_rounded,
          ),
        ];
      case AppHelpMessageIds.prayAudioBehavior:
        final r = _rectInPrayBodyStack(_playPauseButtonKey);
        if (r == null) return const <Widget>[];
        return [
          arrowLayer(
            left: r.center.dx - arrowHalf,
            top: r.top - aboveButtonOffset,
            icon: Icons.keyboard_arrow_down_rounded,
          ),
        ];
      default:
        return const <Widget>[];
    }
  }

  // Activa o desactiva el wakelock según la variable _isBatterySaverActive
  void _toggleWakelock() {
    setState(() {
      _isBatterySaverActive = !_isBatterySaverActive;
      if (_isBatterySaverActive) {
        WakelockPlus.disable(); // Desactiva el wakelock (ahorro de batería)
        SnackBarUtils.showTopInfo(
          context,
          'Modo ahorro de bateria activado (la pantalla puede apagarse).',
        );
      } else {
        WakelockPlus.enable(); // Activa el wakelock (pantalla siempre encendida)
        SnackBarUtils.showTopInfo(
          context,
          'Modo pantalla siempre encendida activado.',
        );
      }
    });
  }

  void _dismissError() {
    setState(() {
      _currentError = null;
    });
  }

  /// Envía el informe completo por HTTP (EmailJS o webhook configurado en app.env).
  Future<void> _sendErrorReportToDeveloper() async {
    final error = _currentError;
    if (error == null || !mounted) return;
    try {
      final reportBody = await _errorLogService.buildReportBody(
        error,
        screen: 'PrayScreen',
      );
      if (!mounted) return;
      await _errorReporter.submitReport(
        error: error,
        screen: 'PrayScreen',
        reportBody: reportBody,
        stackTrace: StackTrace.current,
      );
      if (!mounted) return;
      _dismissError();
      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        'Información técnica enviada al desarrollador.',
      );
    } on ErrorReporterException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e, st) {
      debugPrint('[sendErrorReportToDeveloper] $e\n$st');
      if (!mounted) return;
      SnackBarUtils.showError(context, 'No se pudo enviar el reporte.');
    }
  }

  void _reportError(AppError error) {
    if (!mounted) return;
    _errorLogService.logError(error, screen: 'PrayScreen');
    if (error.severity == ErrorSeverity.error) {
      setState(() {
        _currentError = error;
      });
      return;
    }
    SnackBarUtils.showInfo(context, error.userMessage);
  }

  void playPause() {
    if (_audioSessionButtonLocked) return;
    _audioSessionButtonLocked = true;
    _audioSessionButtonDebounceTimer?.cancel();
    _audioSessionButtonDebounceTimer = Timer(
      AppPrayGlass.audioSessionButtonDebounce,
      () {
        _audioSessionButtonDebounceTimer = null;
        if (mounted) {
          setState(() => _audioSessionButtonLocked = false);
        }
      },
    );

    final handler = ref.read(audioHandlerProvider);
    if (_isplaying) {
      handler.stop();
    } else {
      if (!_isPrayersAudioPlaying && !_isBackgroundMusicPlaying) {
        SnackBarUtils.showInfo(
          context,
          'Atención: La voz y la música están desactivadas en el menú.',
        );
      }
      _syncHandlerParams();
      handler.play();
    }
  }

  // Función para alternar la reproducción de la música de fondo
  void _toggleBackgroundMusic() {
    setState(() {
      _isBackgroundMusicPlaying = !_isBackgroundMusicPlaying;
      _savePrefs(); // Guarda las preferencias
      _syncHandlerParams();
    });
  }

  // Función para alternar la reproducción del audio de las oraciones
  void _togglePrayersAudio() {
    setState(() {
      _isPrayersAudioPlaying = !_isPrayersAudioPlaying;
      _savePrefs(); // Guarda las preferencias
      _syncHandlerParams();
    });
  }

  void _incrementCounter() {
    // Usamos el handler como fuente de verdad única para evitar desincronización
    ref.read(audioHandlerProvider).skipToNext();
  }

  void _decrementCounter() {
    // Usamos el handler como fuente de verdad única
    ref.read(audioHandlerProvider).skipToPrevious();
  }

  // Esta función se llama cuando una cuenta es resaltada
  // y actualiza las oraciones actuales y el orden del misterio.
  void _handleCuentaHighlighted(List<String> prayers, int orderMystery) {
    // Si venimos de un salto explícito, debemos resetear el flag y ajustar la oración
    // independientemente de si los arrays de oraciones son idénticos o no.
    if (_explicitOrderPrayerAfterHighlight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentPrayers = prayers;
          _orderMystery = orderMystery;
          final maxPrayer = prayers.isEmpty ? 0 : prayers.length - 1;
          _orderPrayer = _explicitOrderPrayerTargetIndex.clamp(0, maxPrayer);
          _explicitOrderPrayerAfterHighlight = false;
          _isDecrement = false;
          _maybeUpdateMysteryGlassLabelFromPill();
        });
      });
    } else if (_currentPrayers.toString() != prayers.toString() ||
        (_orderMystery != orderMystery)) {
      // Cambio normal de cuenta por navegación manual o automática
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentPrayers = prayers;
          _orderMystery = orderMystery;
          if (_pendingProgressRestore &&
              prayers.isNotEmpty &&
              (prayers.length > 1 || prayers.first.trim().isNotEmpty)) {
            final maxPrayer = prayers.length - 1;
            _orderPrayer = _orderPrayer.clamp(0, maxPrayer);
            _pendingProgressRestore = false;
            _isDecrement = false;
          } else if (_isDecrement) {
            _orderPrayer = prayers.length - 1;
          } else {
            _orderPrayer = 0;
          }
          _maybeUpdateMysteryGlassLabelFromPill();
        });
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_oldOrderPrayer != _orderPrayer || _oldCounter != _counter) {
        _syncHandlerParams();
        setState(() {
          _oldOrderPrayer = _orderPrayer;
          _oldCounter = _counter;
          _maybeUpdateMysteryGlassLabelFromPill();
        });
      }
    });
  }

  /// Orden que debe mostrar el botón de misterio según la oración actual.
  ///
  /// Si en la cuenta actual estamos antes del ítem «Misterio», se considera aún
  /// el misterio anterior (útil al retroceder por oraciones dentro de la misma cuenta).
  int _mysteryOrderFromCurrentPrayerPosition() {
    final step = Data
        .rosaryBeadSteps[_counter.clamp(0, Data.rosaryBeadSteps.length - 1)];
    final currentPrayers = step.prayers;
    final decadeOrder = _decadeMeditationOrder();

    if (currentPrayers.isEmpty) return decadeOrder;

    final mysteryPrayerIndex = currentPrayers.indexOf('Misterio');
    if (mysteryPrayerIndex == -1) return decadeOrder;

    final safeOrder = _orderPrayer.clamp(0, currentPrayers.length - 1);
    if (safeOrder < mysteryPrayerIndex) {
      return max(1, decadeOrder - 1);
    }
    return decadeOrder;
  }

  /// Avanza la etiqueta en «Misterio»; al retroceder de década/oración baja aunque la pastilla no diga «Misterio».
  void _maybeUpdateMysteryGlassLabelFromPill() {
    final visibleOrder = _mysteryOrderFromCurrentPrayerPosition();
    if (_mysteryGlassLabelReady && visibleOrder < _mysteryGlassLabelOrder) {
      _mysteryGlassLabelOrder = visibleOrder;
      return;
    }

    final step = Data
        .rosaryBeadSteps[_counter.clamp(0, Data.rosaryBeadSteps.length - 1)];
    final currentPrayers = step.prayers;

    if (currentPrayers.isEmpty) return;

    final safeOrder = _orderPrayer.clamp(0, currentPrayers.length - 1);
    final currentLabel = currentPrayers[safeOrder];

    if (currentLabel != 'Misterio') return;

    _mysteryGlassLabelOrder = visibleOrder;
    _mysteryGlassLabelReady = true;
  }

  /// Mismo orden que muestra la etiqueta bajo el botón libro (y el diálogo asociado).
  int _effectiveMeditationOrderForMysteryGlass() => _mysteryGlassLabelReady
      ? _mysteryGlassLabelOrder
      : _decadeMeditationOrder();

  /// Orden de meditación (1–5) según la década resaltada; extensión usa `order` 6 → 5.
  int _decadeMeditationOrder() {
    final o = _orderMystery;
    if (o <= 0) return 1;
    if (o >= 6) return 5;
    return o.clamp(1, 5);
  }

  void _showDecadeMysteryDialog(BuildContext context) {
    final m = widget.mystery;
    if (m == null || !mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return PrayerDialog(
          prayer: 'Misterio',
          mystery: m,
          currentMysteryOrder: _effectiveMeditationOrderForMysteryGlass(),
          errorMessage: _currentError?.userMessage ?? '',
        );
      },
    );
  }

  RosaryMysteryAnchorInfo? _previousMisterioAnchorPosition() {
    RosaryMysteryAnchorInfo? best;
    for (final a in Data.rosaryMysteryAnchors) {
      if (a.beadIndex < _counter ||
          (a.beadIndex == _counter && a.misterioPrayerIndex < _orderPrayer)) {
        best = a;
      }
    }
    return best;
  }

  RosaryMysteryAnchorInfo? _nextMisterioAnchorPosition() {
    for (final a in Data.rosaryMysteryAnchors) {
      if (a.beadIndex > _counter ||
          (a.beadIndex == _counter && a.misterioPrayerIndex > _orderPrayer)) {
        return a;
      }
    }
    return null;
  }

  void _applyMisterioAnchorJump(RosaryMysteryAnchorInfo anchor) {
    if (_loadedImages == null) return;

    final sameBead = anchor.beadIndex == _counter;
    if (sameBead) {
      setState(() {
        final maxIx = _currentPrayers.isEmpty ? 0 : _currentPrayers.length - 1;
        _orderPrayer = anchor.misterioPrayerIndex.clamp(0, maxIx);
        _orderMystery = Data.rosaryBeadSteps[anchor.beadIndex].orderMystery;
        _isDecrement = false;
        _pendingProgressRestore = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncHandlerParams();
        if (_isplaying) {
          ref.read(audioHandlerProvider).play();
        }
      });
      return;
    }

    _explicitOrderPrayerAfterHighlight = true;
    _explicitOrderPrayerTargetIndex = anchor.misterioPrayerIndex;
    setState(() {
      _counter = anchor.beadIndex.clamp(0, rosaryBeadCount - 1);
      _orderPrayer = anchor.misterioPrayerIndex;
      _orderMystery = Data.rosaryBeadSteps[_counter].orderMystery;
      _isDecrement = false;
      _pendingProgressRestore = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncHandlerParams();
      if (_isplaying) {
        ref.read(audioHandlerProvider).play();
      }
    });
  }

  void _onJumpToAdjacentMisterio(int direction) {
    if (widget.mystery == null || _loadedImages == null) return;
    final target = direction < 0
        ? _previousMisterioAnchorPosition()
        : _nextMisterioAnchorPosition();
    if (target == null) return;
    HapticFeedback.selectionClick();
    _applyMisterioAnchorJump(target);
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
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
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
    _maybeAutoStartAlarmGuidedSession();
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

    final RenderBox button = buttonContext.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(buttonContext).context.findRenderObject()! as RenderBox;

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
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final double topBelowAppBarGlobal =
        MediaQuery.paddingOf(context).top + AppLayout.appBarToolbarHeight + 8;
    final double tutorialTop = _yGlobalToPrayBodyStack(
      context,
      topBelowAppBarGlobal,
    );

    // Baja el panel de texto cuando hay flecha bajo iconos del AppBar para no taparla.
    double helpPanelTop = tutorialTop;
    final helpId = _activeHelpMessage?.id;
    if (helpId == AppHelpMessageIds.prayKeepScreenOn) {
      final r = _rectInPrayBodyStack(_wakelockButtonKey);
      if (r != null) {
        helpPanelTop = max(tutorialTop, r.bottom + 8 + 44 + 14);
      }
    } else if (helpId == AppHelpMessageIds.prayAudioMenu) {
      final r = _rectInPrayBodyStack(_prayAudioMenuButtonKey);
      if (r != null) {
        helpPanelTop = max(tutorialTop, r.bottom + 8 + 44 + 14);
      }
    }

    // Escuchar cambios en el estado de reproducción (play/pause)
    ref.listen<AsyncValue<PlaybackState>>(playbackStateProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        final state = next.value!;
        if (state.playing != _isplaying) {
          setState(() {
            _isplaying = state.playing;
          });
        }
      }
    });

    // Escuchar cambios en el elemento actual (posición del rosario)
    ref.listen<AsyncValue<MediaItem?>>(currentMediaItemProvider, (
      previous,
      next,
    ) {
      if (next.hasValue && next.value != null) {
        final item = next.value!;
        final int? hCounter = item.extras?['counter'];
        final int? hOrderPrayer = item.extras?['orderPrayer'];
        final int? hOrderMystery = item.extras?['orderMystery'];

        if (hCounter != null && hOrderPrayer != null) {
          if (hCounter != _counter || hOrderPrayer != _orderPrayer) {
            setState(() {
              _counter = hCounter;
              _orderPrayer = hOrderPrayer;
              if (hOrderMystery != null) _orderMystery = hOrderMystery;
              _currentPrayers = Data.rosaryBeadSteps[hCounter].prayers;
              _maybeUpdateMysteryGlassLabelFromPill();
            });
            _savePrefs();
            _persistProgressSnapshotFromState();
          }
        }
      }
    });

    final bool mysteryNavAnchorsAllowed =
        widget.mystery != null &&
        _loadedImages != null &&
        !_explicitOrderPrayerAfterHighlight;
    RosaryMysteryAnchorInfo? prevMysteryAnchorNav;
    RosaryMysteryAnchorInfo? nextMysteryAnchorNav;
    if (mysteryNavAnchorsAllowed) {
      prevMysteryAnchorNav = _previousMisterioAnchorPosition();
      nextMysteryAnchorNav = _nextMisterioAnchorPosition();
    }
    final bool canJumpPreviousMisterio =
        mysteryNavAnchorsAllowed && prevMysteryAnchorNav != null;
    final bool canJumpNextMisterio =
        mysteryNavAnchorsAllowed && nextMysteryAnchorNav != null;

    return WillPopScope(
      onWillPop: () async {
        ref.read(audioHandlerProvider).stop();
        return true;
      },
      child: Scaffold(
        // Permite que el [body] (imagen de la Virgen) dibuje detrás del AppBar;
        // así el blur del flexibleSpace ve el mismo fondo que el resto de la pantalla.
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: isLandscape ? 46.0 : AppLayout.appBarToolbarHeight,
          centerTitle: !isLandscape,
          // Iconos de estado (batería, hora…) en claro sobre fondo oscuro.
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppPrayGlass.onGlassText,
            onPressed: () {
              ref.read(audioHandlerProvider).stop();
              Navigator.maybePop(context);
            },
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
          title: isLandscape
              ? Row(
                  children: [
                    Text(
                      'Santo Rosario',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.colorCircularProgressIndicator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '—  Misterios ${widget.mystery}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppPrayGlass.onGlassTextMuted,
                      ),
                    ),
                  ],
                )
              : Column(
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
                        color: AppColors.colorCircularProgressIndicator,
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
              key: _wakelockButtonKey,
              icon: Icon(
                _isBatterySaverActive ? Icons.battery_saver : Icons.highlight,
                color: AppPrayGlass.onGlassText,
              ),
              onPressed: _toggleWakelock, // Cambia el estado del wakelock
              tooltip: _isBatterySaverActive
                  ? 'Activar Ahorro Batería'
                  : 'Pantalla Siempre Encendida',
            ),
            IconButton(
              key: _prayAudioMenuButtonKey,
              icon: const Icon(Icons.menu, color: AppPrayGlass.onGlassText),
              tooltip: 'Opciones de audio',
              onPressed: _showPrayGlassAudioMenu,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double statusBarTop = MediaQuery.paddingOf(context).top;
            final double toolbarHeight = isLandscape
                ? 46.0
                : AppLayout.appBarToolbarHeight;
            final double topSafe = statusBarTop + toolbarHeight;
            final double bottomSafe = MediaQuery.paddingOf(context).bottom;

            return Stack(
              key: _prayBodyStackKey,
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(color: AppColors.colorBackgroundBody),
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppAssets.imageVirgenLourdes),
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
                // Area de contenido principal: exactamente desde el borde donde termina el AppBar hasta la base de la pantalla
                Positioned(
                  top: isLandscape ? 46.0 : AppLayout.appBarToolbarHeight,
                  bottom: MediaQuery.paddingOf(context).bottom,
                  left: 0,
                  right: 0,
                  child: isLandscape
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // LADO IZQUIERDO: Rosario.
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, contentConstraints) {
                                    // El rosario ocupa el máximo espacio posible (94%) del hueco SEGURO disponible
                                    final size =
                                        contentConstraints.maxWidth <
                                            contentConstraints.maxHeight
                                        ? contentConstraints.maxWidth
                                        : contentConstraints.maxHeight;
                                    return Center(
                                      child: _buildRosaryArea(
                                        width: size * 0.94,
                                        height: size * 0.94,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // LADO DERECHO: Grupo de botones (misterios + play).
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: _buildLandscapeControlsColumn(
                                      canJumpPreviousMisterio:
                                          canJumpPreviousMisterio,
                                      canJumpNextMisterio: canJumpNextMisterio,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, contentConstraints) {
                            return _buildPortraitRosaryStack(
                              constraints: contentConstraints,
                              canJumpPreviousMisterio: canJumpPreviousMisterio,
                              canJumpNextMisterio: canJumpNextMisterio,
                            );
                          },
                        ),
                ),
                if (showRosaryDebugGuides) ...[
                  // 🟧 Recuadro Naranja: Barra superior (Status Bar + AppBar)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topSafe,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF5722),
                            width: 2.0,
                          ),
                          color: const Color(0x33FF5722),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          '🟧 APPBAR: ${topSafe.toStringAsFixed(1)} px (Status: ${statusBarTop.toStringAsFixed(1)} + Bar: ${toolbarHeight.toStringAsFixed(1)}) | Ancho: ${mediaQuery.size.width.toStringAsFixed(1)} px',
                          style: const TextStyle(
                            color: Color(0xFFFFCCBC),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 📋 HUD de diagnóstico en modo HORIZONTAL
                  if (isLandscape)
                    Positioned(
                      bottom: bottomSafe + 6,
                      right: 12,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE60D1B2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00E5FF),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '📐 DIAGNÓSTICO (HORIZONTAL)',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '📱 Pantalla total: ${mediaQuery.size.width.toStringAsFixed(1)} x ${mediaQuery.size.height.toStringAsFixed(1)} px',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '🟧 Barra sup: ${topSafe.toStringAsFixed(1)} px (Status: ${statusBarTop.toStringAsFixed(1)} + Bar: ${toolbarHeight.toStringAsFixed(1)})',
                                style: const TextStyle(
                                  color: Color(0xFFFFCCBC),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Barra inf (Safe): ${bottomSafe.toStringAsFixed(1)} px',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Alto disp: ${(mediaQuery.size.height - topSafe - bottomSafe).toStringAsFixed(1)} px',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                Positioned(
                  top: helpPanelTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLandscape
                            ? 450
                            : mediaQuery.size.width - 32,
                      ),
                      child: IgnorePointer(
                        ignoring: _activeHelpMessage == null,
                        child: AnimatedOpacity(
                          opacity: _activeHelpMessage == null ? 0 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: _activeHelpMessage == null
                              ? const SizedBox.shrink()
                              : Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        29,
                                        64,
                                        76,
                                        0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppPrayGlass.borderLight
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _activeHelpMessage!.text,
                                          style: const TextStyle(
                                            color: AppPrayGlass.onGlassText,
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors
                                                    .colorCircularProgressIndicator,
                                              ),
                                              onPressed: () =>
                                                  _dismissActiveHelpMessage(
                                                    disablePermanently: false,
                                                  ),
                                              child: const Text('Cerrar'),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors
                                                    .colorCircularProgressIndicator,
                                              ),
                                              onPressed: () =>
                                                  _dismissActiveHelpMessage(
                                                    disablePermanently: true,
                                                  ),
                                              child: const Text(
                                                'No mostrar de nuevo',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                ..._buildTutorialArrowOverlays(context),
                if (_currentError != null &&
                    _currentError!.severity == ErrorSeverity.error)
                  Positioned(
                    top: tutorialTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLandscape
                              ? 550
                              : mediaQuery.size.width - 32,
                        ),
                        child: Material(
                          elevation: 8,
                          shadowColor: Colors.black45,
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.colorBackgroundDialogError,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentError!.userMessage,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Si quieres colaborar con el desarrollador para mejorar esta aplicación, pulse el ícono de enviar.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    tapTargetSize: MaterialTapTargetSize.padded,
                                    minimumSize: const Size(48, 48),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  icon: const Icon(
                                    Icons.send_outlined,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    _sendErrorReportToDeveloper();
                                  },
                                  tooltip:
                                      'Enviar información técnica al desarrollador',
                                ),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    tapTargetSize: MaterialTapTargetSize.padded,
                                    minimumSize: const Size(48, 48),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  icon: const Icon(Icons.close, size: 22),
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
              ],
            );
          },
        ),
      ),
    );
  }

  /// Área central del rosario dibujado.
  Widget _buildRosaryArea({required double width, required double height}) {
    if (_loadedImages == null) {
      return const CircularProgressIndicator(
        color: AppColors.colorCircularProgressIndicator,
      );
    }
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
          showDebugGuides: showRosaryDebugGuides,
        ),
      ),
    );
  }

  /// Stack del rosario en modo retrato con la pastilla de la oración actual
  /// ubicada en el **hueco vacío del aro**, de modo que nunca tape perlas,
  /// medalla ni rosa.
  ///
  /// La geometría replica la de [CuentasPainter] en orientación vertical:
  /// - `radius = min(anchoRosario / 2, 0.33 * altoRosario)`
  /// - el centro del aro está desplazado hacia arriba `radius` respecto del
  ///   centro del área del rosario.
  /// El rosario se dibuja centrado en el Stack, por lo que el centro del aro
  /// en coordenadas del Stack es `(W/2, H/2 - radius)`. La pastilla se coloca
  /// centrada en ese punto, dentro del aro y por encima de la medalla.
  Widget _buildPortraitRosaryStack({
    required BoxConstraints constraints,
    required bool canJumpPreviousMisterio,
    required bool canJumpNextMisterio,
  }) {
    final double rosaryW = constraints.maxWidth;
    final double rosaryH = constraints.maxHeight;

    // Factores geométricos del conjunto completo (aro + extensión):
    // - Distancia hacia arriba (centro -> borde superior del aro): 1.10 * radius
    // - Distancia hacia abajo (centro -> base inferior de la cruz): 2.942 * radius
    const double topSpanFactor = 1.10;
    const double bottomSpanFactor = 2.942;
    const double totalVerticalFactor =
        topSpanFactor + bottomSpanFactor; // 4.042

    // 1. En horizontal se tiene en cuenta el círculo solamente:
    final double maxRadiusByWidth = (rosaryW / 2) * 0.88;
    // 2. En vertical se considera el conjunto completo (círculo + extensión):
    final double maxRadiusByHeight = (rosaryH - 16.0) / totalVerticalFactor;
    final double radius = maxRadiusByWidth < maxRadiusByHeight
        ? maxRadiusByWidth
        : maxRadiusByHeight;

    // Radio de las cuentas básicas (igual que el painter: 0.20 * radius) y
    // radio interior del aro (borde interno de las cuentas).
    final double beadR = radius * 0.20;
    final double innerR = radius - beadR;

    // Centro del aro en coordenadas del Stack (centrado vertical de todo el conjunto):
    final double loopCenterY =
        rosaryH / 2 - ((bottomSpanFactor - topSpanFactor) / 2) * radius;

    // Altura fija de la pastilla.
    final double pillHeight = 90.0;

    // ┌──────────────────────────────────────────────────────────────────────┐
    // │ 👇 AJUSTE MANUAL DE LA PASTILLA DE ORACIÓN (BOTÓN CENTRAL) 👇         │
    // │ Cambiá estos dos valores para modificar la pastilla a mano:          │
    // │  • pillVerticalOffsetPercentage: desplazamiento vertical respecto al │
    // │    centro vertical del aro del rosario.                              │
    // │    0.20 = 20% hacia abajo del centro vertical (valor solicitado).    │
    // │    (0.0 = centrado vertical exacto; + baja la pastilla, - la sube).   │
    // │  • pillWidthFactor: ancho de la pastilla (0.8 = 80% de la cuerda).   │
    // └──────────────────────────────────────────────────────────────────────┘
    const double pillVerticalOffsetPercentage =
        0.40; // 20% hacia abajo del centro vertical
    final double pillCenterOffset = radius * pillVerticalOffsetPercentage;

    // Ancho = cuerda interior a la altura del centro de la pastilla, de modo
    // que sus costados queden armónicos respecto a las cuentas.
    final double halfChord = sqrt(
      max(0, innerR * innerR - pillCenterOffset * pillCenterOffset),
    );

    const double pillWidthFactor = 0.99;
    final double pillWidth = (halfChord * 2 * pillWidthFactor).clamp(
      120.0,
      320.0,
    );

    final double conjuntoTop = loopCenterY - radius * topSpanFactor;
    final double conjuntoBottom = loopCenterY + radius * bottomSpanFactor;
    final double conjuntoHeight = conjuntoBottom - conjuntoTop;
    final double margenArriba = conjuntoTop;
    final double margenAbajo = rosaryH - conjuntoBottom;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Rosario alineado en la parte superior (justo debajo del AppBar).
        Align(
          alignment: Alignment.topCenter,
          child: _buildRosaryArea(width: rosaryW, height: rosaryH),
        ),
        if (showRosaryDebugGuides)
          Positioned(
            top: 4,
            left: 10,
            right: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE60D1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00E5FF),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '📐 DIAGNÓSTICO VISUAL DE CÁLCULOS (MODO VERTICAL)',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📱 Pantalla total: ${MediaQuery.of(context).size.width.toStringAsFixed(1)} x ${MediaQuery.of(context).size.height.toStringAsFixed(1)} px | Status: ${MediaQuery.paddingOf(context).top.toStringAsFixed(1)} px',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      '🟦 Lienzo disponible: ${rosaryW.toStringAsFixed(1)} x ${rosaryH.toStringAsFixed(1)} px',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '🟨 Radio aro: ${radius.toStringAsFixed(1)} px (Lim. ancho: ${maxRadiusByWidth.toStringAsFixed(1)} | Lim. alto: ${maxRadiusByHeight.toStringAsFixed(1)})',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '🟨 Centro aro Y: ${loopCenterY.toStringAsFixed(1)} px',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '🟪 Conjunto: Top: ${conjuntoTop.toStringAsFixed(1)} | Bottom: ${conjuntoBottom.toStringAsFixed(1)} | Alto: ${conjuntoHeight.toStringAsFixed(1)} px',
                      style: const TextStyle(
                        color: Color(0xFFFF4081),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Margen arriba: ${margenArriba.toStringAsFixed(1)} px | Margen abajo: ${margenAbajo.toStringAsFixed(1)} px',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      '⬜ Mitad vertical lienzo: ${(rosaryH / 2).toStringAsFixed(1)} px',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Pastilla de la oración actual, ubicada en la parte baja del hueco del
        // aro, con sus costados pegados a las cuentas (sin espacio).
        Positioned(
          left: (constraints.maxWidth - pillWidth) / 2,
          top: loopCenterY + pillCenterOffset - pillHeight / 2,
          child: _prayGlassPillButton(
            widgetKey: _pillButtonKey,
            width: pillWidth,
            height: pillHeight,
            label: _safeCurrentPrayerLabel.isEmpty
                ? '…'
                : _safeCurrentPrayerLabel,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  final label = _safeCurrentPrayerLabel;
                  final isMisterio = label == 'Misterio';
                  return PrayerDialog(
                    prayer: label.isEmpty ? '…' : label,
                    mystery: widget.mystery,
                    currentMysteryOrder: isMisterio && widget.mystery != null
                        ? _effectiveMeditationOrderForMysteryGlass()
                        : null,
                    errorMessage: _currentError?.userMessage ?? '',
                  );
                },
              );
            },
            trailing: const Icon(
              Icons.info_outline,
              size: AppLayout.infoIconSize,
              color: AppColors.colorCircularProgressIndicator,
            ),
          ),
        ),
        // Controles a la altura de la medalla, uno a cada lado (simétricos),
        // sin tapar las perlas del aro.
        ..._buildPortraitMedalSideControls(
          stackWidth: constraints.maxWidth,
          loopCenterY: loopCenterY,
          radius: radius,
          beadR: beadR,
          canJumpPreviousMisterio: canJumpPreviousMisterio,
          canJumpNextMisterio: canJumpNextMisterio,
        ),
      ],
    );
  }

  /// Coloca los grupos de misterios (izquierda) y reproducción (derecha) a la
  /// altura de la medalla, simétricos respecto al centro horizontal, fuera del
  /// aro para no tapar las perlas.
  ///
  /// Los **bordes externos** de cada grupo se alinean con los **bordes externos
  /// de la cadena del rosario** (el borde más externo de las perlas del aro),
  /// igual que la cadena se adapta para no tocar los bordes de la pantalla.
  /// Cada grupo se envuelve en un [FittedBox] con [BoxFit.scaleDown] y se le da
  /// como ancho máximo el espacio disponible entre el borde externo de la
  /// cadena y el borde interior junto a la medalla. Así, en pantallas angostas
  /// los grupos se reducen proporcionalmente en lugar de recortarse.
  List<Widget> _buildPortraitMedalSideControls({
    required double stackWidth,
    required double loopCenterY,
    required double radius,
    required double beadR,
    required bool canJumpPreviousMisterio,
    required bool canJumpNextMisterio,
  }) {
    // ┌──────────────────────────────────────────────────────────────────────┐
    // │ 👇 AJUSTE MANUAL DE LA UBICACIÓN DE LOS GRUPOS 👇                     │
    // │ Cambiá estos dos valores para mover los grupos a mano:                │
    // │  • groupsVerticalOffset:  + baja los grupos, - los sube (px).         │
    // │    0.0 = el borde superior del recuadro blur toca exactamente el     │
    // │    borde inferior del recuadro amarillo que enmarca el círculo.       │
    // │  • groupsHorizontalOffset: - los acerca al centro, + los aleja (px).  │
    // │    (se aplica simétricamente a ambos grupos).                         │
    // └──────────────────────────────────────────────────────────────────────┘
    const double groupsVerticalOffset =
        8.0; // px (0.0 = justo debajo del recuadro amarillo)
    const double groupsHorizontalOffset = -30.0; // px (horizontal, simétrico)

    // Borde inferior del recuadro amarillo que enmarca el círculo del rosario:
    // (loopCenterY + radius). Los grupos tocan exactamente esa línea:
    final double yellowBoxBottom = loopCenterY + radius;
    final double groupTop = yellowBoxBottom + groupsVerticalOffset;

    // Ancho aproximado de la medalla y separación respecto a ella.
    final double medalHalfWidth = beadR * 1.6;
    const double medalGap = 8.0;

    // Centro horizontal del Stack (el rosario va centrado).
    final double centerX = stackWidth / 2;

    // Borde interior de cada grupo respecto al centro: mitad de la medalla +
    // separación + ajuste horizontal manual. Los grupos se anclan a ese borde y
    // crecen hacia afuera.
    final double innerEdge = medalHalfWidth + medalGap + groupsHorizontalOffset;

    // Borde EXTERNO de la cadena del rosario respecto al centro: radio del aro
    // más el radio de la perla (borde más externo de las perlas). Los grupos se
    // alinean a este borde, igual que la cadena se adapta a la pantalla.
    final double chainOuterEdge = radius + beadR;

    // Espacio horizontal disponible para cada grupo (desde el borde externo de
    // la cadena hasta el borde interior junto a la medalla).
    final double availablePerSide = (chainOuterEdge - innerEdge).clamp(
      0.0,
      double.infinity,
    );

    // Envuelve un grupo para que se reduzca si no cabe en [availablePerSide].
    Widget fitGroup({required Widget child, required Alignment alignment}) {
      return SizedBox(
        width: availablePerSide,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: child,
        ),
      );
    }

    return [
      // Grupo de misterios a la IZQUIERDA de la medalla. Su borde externo
      // izquierdo queda alineado con el borde externo izquierdo de la cadena.
      Positioned(
        top: groupTop,
        right: stackWidth - (centerX - innerEdge),
        child: fitGroup(
          alignment: Alignment.centerRight,
          child: Opacity(
            opacity: widget.mystery != null ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: widget.mystery == null,
              child: _prayGlassMysteryTripleBar(
                widgetKey: _mysteryNavTripleButtonKey,
                clusterEnabled: widget.mystery != null && _loadedImages != null,
                bottomCaption: _mysteryGlassLabelReady
                    ? '$_mysteryGlassLabelOrderº misterio'
                    : 'Misterios',
                canGoPrevious: canJumpPreviousMisterio,
                canGoNext: canJumpNextMisterio,
                onPrevious: canJumpPreviousMisterio
                    ? () => _onJumpToAdjacentMisterio(-1)
                    : null,
                onBook: () => _showDecadeMysteryDialog(context),
                onNext: canJumpNextMisterio
                    ? () => _onJumpToAdjacentMisterio(1)
                    : null,
              ),
            ),
          ),
        ),
      ),
      // Grupo de reproducción a la DERECHA de la medalla.
      Positioned(
        top: groupTop,
        left: centerX + innerEdge,
        child: fitGroup(
          alignment: Alignment.centerLeft,
          child: Opacity(
            opacity: _audioSessionButtonLocked ? 0.45 : 1,
            child: AbsorbPointer(
              absorbing: _audioSessionButtonLocked,
              child: _prayGlassPlaybackTripleBar(
                widgetKey: _playbackTripleButtonKey,
                prevButtonKey: _prevButtonKey,
                playButtonKey: _playPauseButtonKey,
                nextButtonKey: _nextButtonKey,
                isPlaying: _isplaying,
                bottomCaption: 'Oraciones',
                onPrevious: _decrementCounter,
                onPlayPause: playPause,
                onNext: _incrementCounter,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// Controles en horizontal: los grupos de misterios y reproducción en una
  /// fila, y debajo la pastilla con la oración actual, del mismo ancho que
  /// ambos grupos juntos. Todo el conjunto queda centrado.
  Widget _buildLandscapeControlsColumn({
    required bool canJumpPreviousMisterio,
    required bool canJumpNextMisterio,
  }) {
    // Ancho total = misterios + separación + reproducción.
    const double groupsGap = 16.0;
    const double pillWidth = _prayGlassMysteryTripleTotalWidth * 2 + groupsGap;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fila con los dos grupos (mismos widgets que en vertical).
          _buildControlsLayer(
            isLandscape: true,
            canJumpPreviousMisterio: canJumpPreviousMisterio,
            canJumpNextMisterio: canJumpNextMisterio,
          ),
          const SizedBox(height: 8),
          // Pastilla de la oración actual, del ancho de ambos grupos juntos.
          // Misma altura que en vertical (90) para que entren dos líneas de texto.
          _prayGlassPillButton(
            widgetKey: _pillButtonKey,
            width: pillWidth,
            height: 90,
            label: _safeCurrentPrayerLabel.isEmpty
                ? '…'
                : _safeCurrentPrayerLabel,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  final label = _safeCurrentPrayerLabel;
                  final isMisterio = label == 'Misterio';
                  return PrayerDialog(
                    prayer: label.isEmpty ? '…' : label,
                    mystery: widget.mystery,
                    currentMysteryOrder: isMisterio && widget.mystery != null
                        ? _effectiveMeditationOrderForMysteryGlass()
                        : null,
                    errorMessage: _currentError?.userMessage ?? '',
                  );
                },
              );
            },
            trailing: const Icon(
              Icons.info_outline,
              size: AppLayout.infoIconSize,
              color: AppColors.colorCircularProgressIndicator,
            ),
          ),
        ],
      ),
    );
  }

  /// Capa de controles (botones de navegación y progreso).
  Widget _buildControlsLayer({
    required bool isLandscape,
    required bool canJumpPreviousMisterio,
    required bool canJumpNextMisterio,
  }) {
    final horizontalPadding = isLandscape ? 0.0 : AppLayout.sectionPadding;
    final verticalPadding = isLandscape
        ? 0.0
        : AppLayout.prayScreenGlassControlsRowPaddingV;

    return SafeArea(
      top: false,
      bottom: isLandscape ? false : true,
      left: false,
      right: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              isLandscape
                  ? verticalPadding
                  : AppLayout.prayScreenGlassControlsBottomInset,
            ),
            child: Row(
              mainAxisAlignment: isLandscape
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              mainAxisSize: isLandscape ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Grupo de misterios a la IZQUIERDA.
                Opacity(
                  opacity: widget.mystery != null ? 1 : 0.45,
                  child: IgnorePointer(
                    ignoring: widget.mystery == null,
                    child: _prayGlassMysteryTripleBar(
                      widgetKey: _mysteryNavTripleButtonKey,
                      clusterEnabled:
                          widget.mystery != null && _loadedImages != null,
                      // Antes de empezar cualquier misterio muestra «Misterios»;
                      // al avanzar al 1, 2, 3… se reemplaza por «Nº misterio».
                      bottomCaption: _mysteryGlassLabelReady
                          ? '$_mysteryGlassLabelOrderº misterio'
                          : 'Misterios',
                      canGoPrevious: canJumpPreviousMisterio,
                      canGoNext: canJumpNextMisterio,
                      onPrevious: canJumpPreviousMisterio
                          ? () => _onJumpToAdjacentMisterio(-1)
                          : null,
                      onBook: () => _showDecadeMysteryDialog(context),
                      onNext: canJumpNextMisterio
                          ? () => _onJumpToAdjacentMisterio(1)
                          : null,
                    ),
                  ),
                ),
                if (isLandscape) const SizedBox(width: 16),
                // Grupo de reproducción a la DERECHA.
                Opacity(
                  opacity: _audioSessionButtonLocked ? 0.45 : 1,
                  child: AbsorbPointer(
                    absorbing: _audioSessionButtonLocked,
                    child: _prayGlassPlaybackTripleBar(
                      widgetKey: _playbackTripleButtonKey,
                      prevButtonKey: _prevButtonKey,
                      playButtonKey: _playPauseButtonKey,
                      nextButtonKey: _nextButtonKey,
                      isPlaying: _isplaying,
                      // Mismo estilo y altura que el grupo de misterios.
                      bottomCaption: 'Oraciones',
                      onPrevious: _decrementCounter,
                      onPlayPause: playPause,
                      onNext: _incrementCounter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpMessageDefinition {
  const _HelpMessageDefinition({required this.id, required this.text});

  final String id;
  final String text;
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
              onTap: () =>
                  Navigator.pop<String>(menuContext, 'toggleBackgroundMusic'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
              onTap: () =>
                  Navigator.pop<String>(menuContext, 'togglePrayersAudio'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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

// --- Tamaño del control triple de misterios (prev · libro · sig.) ------------
//
// Texto inferir “Nº misterio”: va dentro del botón (`bottomCaption`).
// `_prayGlassMysteryTripleTotalWidth`: ancho de la banda de iconos.
//
// • [_prayGlassMysteryTripleBarSize] — alto de la píldora y diámetro del círculo del libro.
// • [_prayGlassMysteryTripleChevronSlot] — ancho de cada zona táctil de la flecha.
// • [_prayGlassMysteryTripleBookGap] — separación flecha ↔ libro (sin líneas divisorias).
// [_prayGlassMysteryTripleTotalWidth] se deriva para alinear el texto de arriba.
//
const double _prayGlassMysteryTripleBarSize = AppPrayGlass.roundButtonSize;
const double _prayGlassMysteryTripleChevronSlot = 28;
const double _prayGlassMysteryTripleBookGap = 0;
const double _prayGlassMysteryTripleTotalWidth =
    _prayGlassMysteryTripleChevronSlot * 2 +
    _prayGlassMysteryTripleBookGap * 2 +
    _prayGlassMysteryTripleBarSize;

/// Prev · ver misterio (libro) · sig.; texto dorado opcional arriba de la línea inferior.
Widget _prayGlassMysteryTripleBar({
  Key? widgetKey,
  required bool clusterEnabled,
  required String? bottomCaption,
  required bool canGoPrevious,
  required bool canGoNext,
  required VoidCallback? onPrevious,
  required VoidCallback onBook,
  required VoidCallback? onNext,
}) {
  final double h = _prayGlassMysteryTripleBarSize;
  final double w = _prayGlassMysteryTripleTotalWidth;
  final double slot = _prayGlassMysteryTripleChevronSlot;
  final double gap = _prayGlassMysteryTripleBookGap;
  final bool showCaption =
      bottomCaption != null && bottomCaption.trim().isNotEmpty;
  // Tamaño constante: el contenedor reserva siempre el espacio del texto inferior
  // («Nº misterio») y usa siempre [AppPrayGlass.pillRadius], de modo que mide lo
  // mismo desde el inicio que cuando muestra la etiqueta.
  final BorderRadius outerClip = BorderRadius.circular(AppPrayGlass.pillRadius);

  Widget sideTap({
    required String tooltip,
    required IconData icon,
    required bool active,
    required VoidCallback? onTap,
    required BorderRadius splashRadius,
    required Alignment iconAlignment,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: slot,
        height: h,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: clusterEnabled && active ? onTap : null,
            borderRadius: splashRadius,
            child: Align(
              alignment: iconAlignment,
              child: IconTheme(
                data: const IconThemeData(
                  color: AppPrayGlass.onGlassText,
                  size: 24,
                ),
                child: Opacity(
                  opacity: clusterEnabled && active ? 1 : 0.42,
                  child: Icon(icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Material(
    key: widgetKey,
    color: Colors.transparent,
    child: ClipRRect(
      borderRadius: outerClip,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: AppPrayGlass.blurSigma,
          sigmaY: AppPrayGlass.blurSigma,
        ),
        child: Container(
          width: w,
          decoration: BoxDecoration(
            color: AppPrayGlass.frostedTint,
            borderRadius: outerClip,
            border: Border.all(color: AppPrayGlass.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: h,
                width: w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    sideTap(
                      tooltip: 'Misterio anterior',
                      icon: Icons.chevron_left,
                      active: canGoPrevious,
                      onTap: onPrevious,
                      splashRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppPrayGlass.pillRadius),
                        bottomLeft: Radius.zero,
                        topRight: Radius.zero,
                        bottomRight: Radius.zero,
                      ),
                      iconAlignment: Alignment.centerRight,
                    ),
                    SizedBox(width: gap),
                    SizedBox(
                      width: h - 30,
                      height: h,
                      child: Tooltip(
                        message: 'Ver meditación del misterio',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: clusterEnabled ? onBook : null,
                            child: Center(
                              child: IconTheme(
                                data: IconThemeData(
                                  color: AppPrayGlass.onGlassText.withValues(
                                    alpha: clusterEnabled ? 1 : 0.42,
                                  ),
                                  size: 22,
                                ),
                                child: const Icon(Icons.menu_book_rounded),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    sideTap(
                      tooltip: 'Misterio siguiente',
                      icon: Icons.chevron_right,
                      active: canGoNext,
                      onTap: onNext,
                      splashRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppPrayGlass.pillRadius),
                        bottomRight: Radius.zero,
                        topLeft: Radius.zero,
                        bottomLeft: Radius.zero,
                      ),
                      iconAlignment: Alignment.centerLeft,
                    ),
                  ],
                ),
              ),
              // Siempre reservamos el espacio del texto inferior para que el
              // contenedor mida lo mismo con o sin la etiqueta «Nº misterio».
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: SizedBox(
                  width: w,
                  // Alto fijo para 2 líneas (13px × 1.08 × 2 ≈ 28px): así el
                  // contenedor mide igual aunque no haya etiqueta.
                  height: 28,
                  child: Text(
                    showCaption ? bottomCaption : '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.08,
                      color: AppColors.colorCircularProgressIndicator,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Contenedor glass unificado de reproducción: anterior · play/stop · siguiente.
///
/// Replica **exactamente** el estilo del contenedor de misterios
/// ([_prayGlassMysteryTripleBar]): mismo ancho ([_prayGlassMysteryTripleTotalWidth]),
/// alto ([AppPrayGlass.roundButtonSize]), [AppPrayGlass.pillRadius], tinte
/// [AppPrayGlass.frostedTint], borde [AppPrayGlass.borderLight] y el mismo
/// [BackdropFilter] con [AppPrayGlass.blurSigma]. Así ambos contenedores quedan
/// simétricos a izquierda y derecha de la fila inferior.
///
/// Los iconos van **sin fondo circular individual** (transparentes), centrados y
/// distribuidos con [MainAxisAlignment.spaceEvenly].
Widget _prayGlassPlaybackTripleBar({
  Key? widgetKey,
  required Key prevButtonKey,
  required Key playButtonKey,
  required Key nextButtonKey,
  required bool isPlaying,
  String? bottomCaption,
  required VoidCallback onPrevious,
  required VoidCallback onPlayPause,
  required VoidCallback onNext,
}) {
  final double h = _prayGlassMysteryTripleBarSize;
  final double w = _prayGlassMysteryTripleTotalWidth;
  final BorderRadius outerClip = BorderRadius.circular(AppPrayGlass.pillRadius);

  final double slot = _prayGlassMysteryTripleChevronSlot;
  final double gap = _prayGlassMysteryTripleBookGap;

  // Mismo esquema que el grupo de misterios: slots laterales estrechos
  // ([slot]) para las flechas y un slot central para play/stop. Así no hay
  // overflow dentro del ancho fijo ([w]) del contenedor.
  Widget sideTap({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    required BorderRadius splashRadius,
    required Alignment iconAlignment,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: slot,
        height: h,
        child: Material(
          key: key,
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: splashRadius,
            child: Align(
              alignment: iconAlignment,
              child: IconTheme(
                data: const IconThemeData(
                  color: AppPrayGlass.onGlassText,
                  size: 24,
                ),
                child: Icon(icon),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget centerTap({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: h - 30,
      height: h,
      child: Tooltip(
        message: tooltip,
        child: Material(
          key: key,
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: IconTheme(
                data: const IconThemeData(
                  color: AppPrayGlass.onGlassText,
                  size: 22,
                ),
                child: Icon(icon),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Material(
    key: widgetKey,
    color: Colors.transparent,
    child: ClipRRect(
      borderRadius: outerClip,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: AppPrayGlass.blurSigma,
          sigmaY: AppPrayGlass.blurSigma,
        ),
        // Sin altura fija: el contenedor se ajusta a su [Column] igual que el
        // de misterios (fila de iconos h + texto 28 + padding 6), evitando
        // cualquier overflow vertical y quedando simétrico.
        child: Container(
          width: w,
          decoration: BoxDecoration(
            color: AppPrayGlass.frostedTint,
            borderRadius: outerClip,
            border: Border.all(color: AppPrayGlass.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: h,
                width: w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    sideTap(
                      key: prevButtonKey,
                      tooltip: 'Oración anterior',
                      icon: Icons.chevron_left,
                      onTap: onPrevious,
                      splashRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppPrayGlass.pillRadius),
                        bottomLeft: Radius.zero,
                        topRight: Radius.zero,
                        bottomRight: Radius.zero,
                      ),
                      iconAlignment: Alignment.centerRight,
                    ),
                    SizedBox(width: gap),
                    centerTap(
                      key: playButtonKey,
                      tooltip: isPlaying ? 'Detener' : 'Reproducir',
                      icon: isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      onTap: onPlayPause,
                    ),
                    SizedBox(width: gap),
                    sideTap(
                      key: nextButtonKey,
                      tooltip: 'Oración siguiente',
                      icon: Icons.chevron_right,
                      onTap: onNext,
                      splashRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppPrayGlass.pillRadius),
                        bottomRight: Radius.zero,
                        topLeft: Radius.zero,
                        bottomLeft: Radius.zero,
                      ),
                      iconAlignment: Alignment.centerLeft,
                    ),
                  ],
                ),
              ),
              // Etiqueta inferior opcional. Si no se pasa [bottomCaption] el
              // contenedor queda con la altura justa de los botones (h), sin
              // reservar espacio de texto.
              if (bottomCaption != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  child: SizedBox(
                    width: w,
                    height: 28,
                    child: Text(
                      bottomCaption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                        color: AppColors.colorCircularProgressIndicator,
                      ),
                    ),
                  ),
                ),
            ],
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
  Key? widgetKey,
  required String label,
  required VoidCallback onPressed,
  Widget? trailing,
  double? width,
  double? height,
}) {
  const TextStyle pillTextStyle = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 20,
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
    key: widgetKey,
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
            // Altura configurable: por defecto la de los botones circulares;
            // se puede igualar a la columna de grupos (play + misterios).
            height: height ?? AppPrayGlass.roundButtonSize,
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
