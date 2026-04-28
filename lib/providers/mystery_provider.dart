import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santo_rosario/utils/mystery_utils.dart';

class MysteryState {
  const MysteryState({
    required this.weekdayNow,
    required this.selectedMystery,
  });

  final String weekdayNow;
  final String selectedMystery;

  MysteryState copyWith({
    String? weekdayNow,
    String? selectedMystery,
  }) {
    return MysteryState(
      weekdayNow: weekdayNow ?? this.weekdayNow,
      selectedMystery: selectedMystery ?? this.selectedMystery,
    );
  }
}

class MysteryNotifier extends Notifier<MysteryState> {
  @override
  MysteryState build() {
    return const MysteryState(
      weekdayNow: '',
      selectedMystery: '',
    );
  }

  void initializeFromWeekday(int weekday) {
    state = state.copyWith(
      weekdayNow: MysteryUtils.weekdayName(weekday),
      selectedMystery: MysteryUtils.mysteryForWeekday(weekday),
    );
  }

  void toggleMystery(String mystery, bool value) {
    state = state.copyWith(selectedMystery: value ? mystery : '');
  }

  String? get mysteryToPray =>
      state.selectedMystery.isNotEmpty ? state.selectedMystery : null;
}

final mysteryProvider = NotifierProvider<MysteryNotifier, MysteryState>(
  MysteryNotifier.new,
);
