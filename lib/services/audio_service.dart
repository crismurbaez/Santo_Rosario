import 'package:just_audio/just_audio.dart';
import 'package:santo_rosario/constants/app_constants.dart';

class AudioService {
  final AudioPlayer _prayerPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  Stream<PlayerState> get prayerPlayerStateStream =>
      _prayerPlayer.playerStateStream;

  Future<void> playBackgroundMusic() async {
    await _backgroundPlayer.setAsset(AppAssets.soundAveMariaBackground);
    await _backgroundPlayer.setLoopMode(LoopMode.all);
    await _backgroundPlayer.setVolume(AppAudio.backgroundMusicVolume);
    await _backgroundPlayer.play();
  }

  Future<void> stopBackgroundMusic() async {
    await _backgroundPlayer.stop();
  }

  Future<void> playPrayer(String assetPath) async {
    await _prayerPlayer.stop();
    await _prayerPlayer.setAsset(assetPath);
    await _prayerPlayer.play();
  }

  Future<void> stopPrayer() async {
    await _prayerPlayer.stop();
  }

  Future<void> dispose() async {
    await _prayerPlayer.stop();
    await _prayerPlayer.dispose();
    await _backgroundPlayer.stop();
    await _backgroundPlayer.dispose();
  }
}
