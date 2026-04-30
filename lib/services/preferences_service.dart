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

  Future<bool> isHelpMessageDismissed(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppPreferencesKeys.helpMessageDismissedPrefix}$messageId';
    return prefs.getBool(key) ?? false;
  }

  Future<void> setHelpMessageDismissed(String messageId, bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppPreferencesKeys.helpMessageDismissedPrefix}$messageId';
    await prefs.setBool(key, dismissed);
  }

  Future<List<String>> getErrorLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppPreferencesKeys.errorLogs) ?? <String>[];
  }

  Future<void> appendErrorLog(String serializedLog) async {
    final prefs = await SharedPreferences.getInstance();
    final currentLogs = prefs.getStringList(AppPreferencesKeys.errorLogs) ?? <String>[];
    currentLogs.add(serializedLog);
    if (currentLogs.length > 200) {
      currentLogs.removeRange(0, currentLogs.length - 200);
    }
    await prefs.setStringList(AppPreferencesKeys.errorLogs, currentLogs);
  }
}
