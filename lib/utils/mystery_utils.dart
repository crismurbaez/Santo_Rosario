import 'package:santo_rosario/constants/app_constants.dart';

class MysteryUtils {
  static const Map<int, String> _weekdayNameByInt = {
    1: AppWeekdays.lunes,
    2: AppWeekdays.martes,
    3: AppWeekdays.miercoles,
    4: AppWeekdays.jueves,
    5: AppWeekdays.viernes,
    6: AppWeekdays.sabado,
    7: AppWeekdays.domingo,
  };

  static const Map<int, String> _mysteryByWeekday = {
    1: AppMysteryTypes.gozosos,
    2: AppMysteryTypes.dolorosos,
    3: AppMysteryTypes.gloriosos,
    4: AppMysteryTypes.luminosos,
    5: AppMysteryTypes.dolorosos,
    6: AppMysteryTypes.gozosos,
    7: AppMysteryTypes.gloriosos,
  };

  static String weekdayName(int weekday) {
    return _weekdayNameByInt[weekday] ?? AppWeekdays.lunes;
  }

  static String mysteryForWeekday(int weekday) {
    return _mysteryByWeekday[weekday] ?? AppMysteryTypes.gozosos;
  }
}
