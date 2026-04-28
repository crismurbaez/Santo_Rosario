import 'package:shared_preferences/shared_preferences.dart';
import 'package:santo_rosario/constants/app_constants.dart';

class PreferencesService {
  Future<bool> getPrayerAudioPlaying() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppPreferencesKeys.prayersAudioPlaying) ?? true;
  }

  Future<bool> getBackgroundMusicPlaying() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppPreferencesKeys.backgroundMusicPlaying) ?? true;
  }

  Future<void> setPrayerAudioPlaying(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferencesKeys.prayersAudioPlaying, value);
  }

  Future<void> setBackgroundMusicPlaying(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferencesKeys.backgroundMusicPlaying, value);
  }
}
