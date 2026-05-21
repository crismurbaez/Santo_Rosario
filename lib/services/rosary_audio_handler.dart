import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/data/models/data.dart';

class RosaryAudioHandler extends BaseAudioHandler {
  final _prayerPlayer = AudioPlayer();
  final _backgroundPlayer = AudioPlayer();
  
  // Estado local para la secuencia
  int _counter = 0;
  int _orderPrayer = 0;
  int _orderMystery = 0;
  String? _mystery;
  bool _isBackgroundMusicPlaying = true;
  bool _isPrayersAudioPlaying = true;

  RosaryAudioHandler() {
    // Escuchar cambios en el estado del reproductor de oraciones
    _prayerPlayer.playbackEventStream.listen(_broadcastState);
    _prayerPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });
  }

  // --- Métodos de Control ---

  @override
  Future<void> play() async {
    if (_isPrayersAudioPlaying) {
      await _playCurrentStep();
    }
    if (_isBackgroundMusicPlaying) {
      await _startBackgroundMusic();
    }
  }

  @override
  Future<void> pause() async {
    await _prayerPlayer.pause();
    await _backgroundPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _prayerPlayer.stop();
    await _backgroundPlayer.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    final wasPlaying = _prayerPlayer.playing;
    _incrementCounter();
    if (wasPlaying && _isPrayersAudioPlaying) {
      await _playCurrentStep();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final wasPlaying = _prayerPlayer.playing;
    _decrementCounter();
    if (wasPlaying && _isPrayersAudioPlaying) {
      await _playCurrentStep();
    }
  }

  // --- Lógica Interna del Rosario ---

  void updateParams({
    int? counter,
    int? orderPrayer,
    int? orderMystery,
    String? mystery,
    bool? isBackgroundMusicPlaying,
    bool? isPrayersAudioPlaying,
  }) {
    if (counter != null) _counter = counter;
    if (orderPrayer != null) _orderPrayer = orderPrayer;
    if (orderMystery != null) _orderMystery = orderMystery;
    if (mystery != null) _mystery = mystery;
    if (isBackgroundMusicPlaying != null) _isBackgroundMusicPlaying = isBackgroundMusicPlaying;
    if (isPrayersAudioPlaying != null) _isPrayersAudioPlaying = isPrayersAudioPlaying;
    
    _updateMediaItem();
  }

  Future<void> _playCurrentStep() async {
    final step = Data.rosaryBeadSteps[_counter];
    final prayers = step.prayers;
    final prayerLabel = prayers[_orderPrayer.clamp(0, prayers.length - 1)];
    
    String? assetPath;
    if (Data.prayersSounds.containsKey(prayerLabel)) {
      assetPath = Data.prayersSounds[prayerLabel];
    }

    if (prayerLabel == 'Misterio') {
      String soundMystery = '${_mystery}${_orderMystery.toString()}';
      assetPath = Data.prayersSounds[soundMystery];
    }

    if (assetPath != null) {
      await _prayerPlayer.stop();
      try {
        await _prayerPlayer.setAsset(assetPath);
        await _prayerPlayer.seek(Duration.zero);
        _updateMediaItem(title: prayerLabel);
        _prayerPlayer.play();
      } catch (e) {
        print('Error setting asset: $e');
      }
    } else {
      // Si no hay asset, detener el audio y actualizar media item
      await _prayerPlayer.stop();
      _updateMediaItem(title: prayerLabel);
    }
  }

  Future<void> _startBackgroundMusic() async {
    if (_backgroundPlayer.playing) return;
    await _backgroundPlayer.setAsset(AppAssets.soundAveMariaBackground);
    await _backgroundPlayer.setLoopMode(LoopMode.all);
    await _backgroundPlayer.setVolume(AppAudio.backgroundMusicVolume);
    _backgroundPlayer.play();
  }

  void _handlePlaybackCompleted() {
    // Si estamos en la última cuenta y última oración, detenemos solo la oración.
    // Mantenemos la música de fondo activa.
    final step = Data.rosaryBeadSteps[_counter];
    if (_counter >= Data.rosaryBeadSteps.length - 1 && _orderPrayer >= step.prayers.length - 1) {
      _prayerPlayer.stop();
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.completed,
      ));
      return;
    }

    _incrementCounter();
    _playCurrentStep();
  }

  void _incrementCounter() {
    final step = Data.rosaryBeadSteps[_counter];
    if (_orderPrayer < step.prayers.length - 1) {
      _orderPrayer++;
    } else {
      if (_counter < Data.rosaryBeadSteps.length - 1) {
        _counter++;
        _orderPrayer = 0;
      }
    }
    // Sincronizar el misterio con la nueva cuenta
    _orderMystery = Data.rosaryBeadSteps[_counter].orderMystery;
    _updateMediaItem();
  }

  void _decrementCounter() {
    if (_orderPrayer > 0) {
      _orderPrayer--;
    } else if (_counter > 0) {
      _counter--;
      // Al volver atrás, empezamos por la última oración de la cuenta anterior
      final prevStep = Data.rosaryBeadSteps[_counter];
      _orderPrayer = prevStep.prayers.length - 1;
    }
    // Sincronizar el misterio con la nueva cuenta
    _orderMystery = Data.rosaryBeadSteps[_counter].orderMystery;
    _updateMediaItem();
  }

  void _updateMediaItem({String? title}) {
    final step = Data.rosaryBeadSteps[_counter];
    final label = title ?? step.prayers[_orderPrayer.clamp(0, step.prayers.length - 1)];
    
    mediaItem.add(MediaItem(
      id: 'rosary_step_$_counter\_$_orderPrayer',
      album: 'Santo Rosario - $_mystery',
      title: label,
      artist: 'Santo Rosario',
      duration: _prayerPlayer.duration,
      extras: {
        'counter': _counter,
        'orderPrayer': _orderPrayer,
        'orderMystery': _orderMystery,
      },
    ));
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_prayerPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_prayerPlayer.processingState]!,
      playing: _prayerPlayer.playing,
      updatePosition: _prayerPlayer.position,
      bufferedPosition: _prayerPlayer.bufferedPosition,
      speed: _prayerPlayer.speed,
      queueIndex: event.currentIndex,
    ));
  }
}
