import 'package:shared_preferences/shared_preferences.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/models/prayer_progress_snapshot.dart';

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

  /// Quita todos los mensajes “no volver a mostrar” de la pantalla del rosario;
  /// los consejos reaparecen la próxima vez que abras el modo oración.
  Future<void> resetPrayScreenHelpTips() async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in AppHelpMessageIds.prayScreenTips) {
      await prefs.remove(
        '${AppPreferencesKeys.helpMessageDismissedPrefix}$id',
      );
    }
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

  /// Por defecto [true]: se guarda el avance si la persona abandona antes de terminar.
  Future<bool> getSavePrayerProgressEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppPreferencesKeys.savePrayerProgressEnabled) ?? true;
  }

  Future<void> setSavePrayerProgressEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferencesKeys.savePrayerProgressEnabled, value);
  }

  Future<void> savePrayerProgressSnapshot(PrayerProgressSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppPreferencesKeys.prayerProgressSnapshot,
      snapshot.encode(),
    );
  }

  Future<PrayerProgressSnapshot?> loadPrayerProgressSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppPreferencesKeys.prayerProgressSnapshot);
    return PrayerProgressSnapshot.decode(raw);
  }

  Future<void> clearPrayerProgressSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppPreferencesKeys.prayerProgressSnapshot);
  }
}
