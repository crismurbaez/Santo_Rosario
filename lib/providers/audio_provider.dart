import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:santo_rosario/services/rosary_audio_handler.dart';

/// Provider que expone el Handler global de audio.
/// Se sobreescribe en el main.dart tras la inicialización.
final audioHandlerProvider = Provider<RosaryAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider no ha sido sobreescrito en el ProviderScope');
});

/// Stream que expone el estado de reproducción (si está sonando, controles, etc.)
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

/// Stream que expone el MediaItem actual (título de la oración, índices, etc.)
final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
});
