import 'dart:convert';

/// Estado serializado de la pantalla del rosario para reanudar la oración.
class PrayerProgressSnapshot {
  PrayerProgressSnapshot({
    required this.mystery,
    required this.counter,
    required this.orderPrayer,
    required this.orderMystery,
  });

  final String mystery;
  final int counter;
  final int orderPrayer;
  final int orderMystery;

  /// Oración terminada cuando estamos en la última cuenta y en la última oración visible.
  static bool computeComplete({
    required int counter,
    required int orderPrayer,
    required int rosaryBeadCount,
    required int currentPrayersLength,
    required bool prayersMeaningful,
  }) {
    if (!prayersMeaningful || currentPrayersLength < 1) return false;
    return counter >= rosaryBeadCount - 1 &&
        orderPrayer >= currentPrayersLength - 1;
  }

  Map<String, dynamic> toJson() => {
        'mystery': mystery,
        'counter': counter,
        'orderPrayer': orderPrayer,
        'orderMystery': orderMystery,
        'savedAt': DateTime.now().toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  static PrayerProgressSnapshot? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>?;
      if (m == null) return null;
      final mystery = m['mystery'];
      if (mystery is! String || mystery.isEmpty) return null;
      return PrayerProgressSnapshot(
        mystery: mystery,
        counter: (m['counter'] as num?)?.toInt() ?? 0,
        orderPrayer: (m['orderPrayer'] as num?)?.toInt() ?? 0,
        orderMystery: (m['orderMystery'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
