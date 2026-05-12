import 'package:shared_preferences/shared_preferences.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/models/rosary_alarm.dart';

class AlarmStorageService {
  Future<List<RosaryAlarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppPreferencesKeys.rosaryAlarmsJson);
    return RosaryAlarm.decodeList(raw);
  }

  Future<void> saveAlarms(List<RosaryAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppPreferencesKeys.rosaryAlarmsJson,
      RosaryAlarm.encodeList(alarms),
    );
  }
}
