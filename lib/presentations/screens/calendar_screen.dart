import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/models/rosary_alarm.dart';
import 'package:santo_rosario/services/alarm_notification_service.dart';
import 'package:santo_rosario/services/alarm_storage_service.dart';
import 'package:uuid/uuid.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = AlarmStorageService();
  final _uuid = const Uuid();

  List<RosaryAlarm> _alarms = [];
  DateTime _dateSelected = DateTime.now();
  TimeOfDay _timeSelected = TimeOfDay.now();
  bool _repeatWeekly = false;
  bool _repeatDaily = false;
  bool _openRosaryWithGuidedAudio = false;
  String? _editingId;
  bool _loading = true;
  bool _localeReady = false;
  AndroidAutoStartDiagnostic? _autoStartDiagnostic;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AlarmNotificationService.instance.requestRuntimePermissions();
    final diagnostic =
        await AlarmNotificationService.instance.getAndroidAutoStartDiagnostic();
    await initializeDateFormatting('es');
    final loaded = await _storage.loadAlarms();
    loaded.sort(_compareAlarms);
    if (!mounted) return;
    setState(() {
      _alarms = loaded;
      _loading = false;
      _localeReady = true;
      _autoStartDiagnostic = diagnostic;
    });
  }

  int _compareAlarms(RosaryAlarm a, RosaryAlarm b) {
    final svc = AlarmNotificationService.instance;
    final da = svc.nextFireAsDateTime(a);
    final db = svc.nextFireAsDateTime(b);
    if (da == null && db == null) return a.id.compareTo(b.id);
    if (da == null) return 1;
    if (db == null) return -1;
    final c = da.compareTo(db);
    if (c != 0) return c;
    return a.id.compareTo(b.id);
  }

  String _alarmTitle(RosaryAlarm a) {
    if (!_localeReady) {
      return '${a.day}/${a.month}/${a.year} ${_timeHm(a)}';
    }
    final t = TimeOfDay(hour: a.hour, minute: a.minute);
    if (a.repeatDaily) {
      return 'Todos los días · ${t.format(context)}';
    }
    if (a.repeatWeekly) {
      final dow = DateFormat('EEEE', 'es').format(a.anchorDate);
      return 'Cada $dow · ${t.format(context)}';
    }
    final d = DateTime(a.year, a.month, a.day, a.hour, a.minute);
    return DateFormat("EEE d 'de' MMMM yyyy · HH:mm", 'es').format(d);
  }

  String _timeHm(RosaryAlarm a) {
    final h = a.hour.toString().padLeft(2, '0');
    final m = a.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeSelected,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppHomeColors.switchActiveGradientTop,
              onPrimary: Colors.white,
              surface: AppHomeColors.cardBackground,
              onSurface: AppHomeColors.titleText,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppHomeColors.cardBackground,
              hourMinuteTextColor:
                  WidgetStateColor.resolveWith((_) => AppHomeColors.titleText),
              dayPeriodTextColor:
                  WidgetStateColor.resolveWith((_) => AppHomeColors.titleText),
              dialHandColor: AppHomeColors.switchActiveGradientTop,
              dialBackgroundColor: AppHomeColors.todayChipBackground,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _timeSelected = picked);
    }
  }

  void _editAlarm(RosaryAlarm a) {
    setState(() {
      _editingId = a.id;
      _dateSelected = DateTime(a.year, a.month, a.day);
      _timeSelected = TimeOfDay(hour: a.hour, minute: a.minute);
      _repeatWeekly = a.repeatWeekly;
      _repeatDaily = a.repeatDaily;
      _openRosaryWithGuidedAudio = a.openRosaryWithGuidedAudio;
    });
  }

  Future<void> _deleteAlarm(RosaryAlarm a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppHomeColors.todayChipBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Eliminar alarma',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppHomeColors.titleText,
            fontSize: 20,
          ),
        ),
        content: Text(
          '¿Querés quitar esta alarma?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppHomeColors.subtitleText,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppHomeColors.titleText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AlarmNotificationService.instance.cancelNotification(a.notificationId);
    _alarms.removeWhere((e) => e.id == a.id);
    await _storage.saveAlarms(_alarms);
    if (_editingId == a.id) _editingId = null;
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppHomeColors.titleText,
        content: const Text(
          'Alarma eliminada.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _toggleEnabled(RosaryAlarm a, bool value) async {
    final i = _alarms.indexWhere((e) => e.id == a.id);
    if (i < 0) return;
    _alarms[i] = a.copyWith(enabled: value);
    await _persist();
    if (!mounted) return;
    setState(() {});
  }

  RosaryAlarm _alarmFromForm() {
    final id = _editingId ?? _uuid.v4();
    return RosaryAlarm(
      id: id,
      year: _dateSelected.year,
      month: _dateSelected.month,
      day: _dateSelected.day,
      hour: _timeSelected.hour,
      minute: _timeSelected.minute,
      repeatDaily: _repeatDaily,
      repeatWeekly: _repeatWeekly,
      enabled: true,
      openRosaryWithGuidedAudio: _openRosaryWithGuidedAudio,
    );
  }

  Future<void> _persist() async {
    await _storage.saveAlarms(_alarms);
    try {
      await AlarmNotificationService.instance.syncAll(_alarms);
    } catch (e, st) {
      debugPrint('[CalendarScreen] sync alarmas: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppHomeColors.titleText,
          content: Text(
            'Las alarmas se guardaron, pero hubo un problema al programarlas '
            '([$e]). Verificá permisos de notificación y alarmas exactas.',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _saveAlarm() async {
    final wasEditing = _editingId != null;
    final alarm = _alarmFromForm();
    if (!AlarmNotificationService.supportsNativeSchedule) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppHomeColors.titleText,
          content: const Text(
            'Las alarmas programadas están pensadas para Android e iOS. '
            'En esta plataforma no se pueden activar.',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
        ),
      );
    }

    final next = AlarmNotificationService.instance.nextFireAsDateTime(alarm);
    if (!alarm.repeatWeekly && next == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppHomeColors.titleText,
          content: const Text(
            'Elegí una fecha y hora futuras para alarmas sin repetición.',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (wasEditing) {
      final ix = _alarms.indexWhere((e) => e.id == _editingId);
      if (ix >= 0) {
        final prevEnabled = _alarms[ix].enabled;
        _alarms[ix] = alarm.copyWith(enabled: prevEnabled);
      }
    } else {
      _alarms.add(alarm);
    }

    _alarms.sort(_compareAlarms);

    await _persist();
    if (!mounted) return;
    setState(() {
      if (wasEditing) {
        _editingId = null;
      } else {
        _dateSelected = DateTime.now();
        _timeSelected = TimeOfDay.now();
        _repeatWeekly = false;
        _repeatDaily = false;
        _openRosaryWithGuidedAudio = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppHomeColors.titleText,
        content: Text(
          wasEditing ? 'Cambios guardados.' : 'Alarma guardada.',
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppHomeColors.screenBackground,
        appBar: AppBar(
          backgroundColor: AppHomeColors.screenBackground,
          foregroundColor: AppHomeColors.titleText,
          toolbarHeight: AppHomeLayout.appBarToolbarHeight,
          title: Text(
            'Alarmas del rosario',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppHomeColors.switchActiveGradientTop,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppHomeColors.screenBackground,
      appBar: AppBar(
        backgroundColor: AppHomeColors.screenBackground,
        foregroundColor: AppHomeColors.titleText,
        toolbarHeight: AppHomeLayout.appBarToolbarHeight,
        title: Align(
          alignment: Alignment.center,
          child: Text(
            'Alarmas del rosario',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 20,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppCalendarLayout.horizontalPadding,
              8,
              AppCalendarLayout.horizontalPadding,
              24,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_openRosaryWithGuidedAudio &&
                      _autoStartDiagnostic != null &&
                      !_autoStartDiagnostic!.canLikelyAutoOpen)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppHomeColors.todayChipBackground,
                        borderRadius: BorderRadius.circular(
                          AppCalendarLayout.cardRadius,
                        ),
                        border: Border.all(
                          color:
                              AppHomeColors.subtitleText.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Para que se abra automáticamente el rosario, verificá '
                        'estos permisos del sistema: notificaciones, alarmas '
                        'exactas y pantalla completa. Sin ellos, la alarma puede '
                        'mostrar solo la notificación.',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontSize: 13, height: 1.38),
                      ),
                    ),
                  if (!AlarmNotificationService.supportsNativeSchedule)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppHomeColors.todayChipBackground,
                        borderRadius: BorderRadius.circular(
                          AppCalendarLayout.cardRadius,
                        ),
                        border: Border.all(
                          color: AppHomeColors.subtitleText
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'En esta versión las notificaciones programadas '
                        'funcionan en Android y iOS. Podés igualmente guardar '
                        'aquí tus horarios.',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontSize: 13, height: 1.38),
                      ),
                    ),
                  _GlassCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary:
                              AppHomeColors.switchActiveGradientTop,
                          onPrimary: Colors.white,
                          onSurface: AppHomeColors.titleText,
                        ),
                        textTheme: Theme.of(context).textTheme,
                      ),
                      child: CalendarDatePicker(
                        initialDate: _dateSelected,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365 * 10),
                        ),
                        lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                        onDateChanged: (d) =>
                            setState(() => _dateSelected = d),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppCalendarLayout.sectionGap),
                  _GlassCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppCalendarLayout.cardRadius - 6,
                      ),
                      onTap: _selectTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: AppHomeColors.todayChipIcon,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hora',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeSelected.format(context),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppHomeColors.subtitleText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GlassCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveThumb;
                            }
                            return AppHomeColors.switchInactiveThumb;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveTrack;
                            }
                            return AppHomeColors.switchInactiveTrack;
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveTrackBorder;
                            }
                            return AppHomeColors.subtitleText
                                .withValues(alpha: 0.25);
                          }),
                        ),
                      ),
                      child: SwitchListTile.adaptive(
                      value: _repeatWeekly,
                      onChanged: (v) => setState(() {
                        _repeatWeekly = v;
                        if (v) _repeatDaily = false;
                      }),
                      title: Text(
                        'Repetir cada semana',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: AppHomeColors.titleText,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        'Suena cada ${DateFormat('EEEE', 'es').format(_dateSelected)} '
                        'a la misma hora.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          color: AppHomeColors.subtitleText,
                          height: 1.35,
                        ),
                      ),
                    ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GlassCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveThumb;
                            }
                            return AppHomeColors.switchInactiveThumb;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveTrack;
                            }
                            return AppHomeColors.switchInactiveTrack;
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveTrackBorder;
                            }
                            return AppHomeColors.subtitleText
                                .withValues(alpha: 0.25);
                          }),
                        ),
                      ),
                      child: SwitchListTile.adaptive(
                        value: _repeatDaily,
                        onChanged: (v) => setState(() {
                          _repeatDaily = v;
                          if (v) _repeatWeekly = false;
                        }),
                        title: Text(
                          'Repetir cada día',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppHomeColors.titleText,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          'Suena todos los días a la misma hora.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: AppHomeColors.subtitleText,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GlassCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        switchTheme: SwitchThemeData(
                          thumbColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveThumb;
                            }
                            return AppHomeColors.switchInactiveThumb;
                          }),
                          trackColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveTrack;
                            }
                            return AppHomeColors.switchInactiveTrack;
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppHomeColors.switchActiveTrackBorder;
                            }
                            return AppHomeColors.subtitleText
                                .withValues(alpha: 0.25);
                          }),
                        ),
                      ),
                      child: SwitchListTile.adaptive(
                        value: _openRosaryWithGuidedAudio,
                        onChanged: (v) => setState(
                          () => _openRosaryWithGuidedAudio = v,
                        ),
                        title: Text(
                          'Abrir y rezar con voz',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: AppHomeColors.titleText,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          'Al sonar la alarma se abre el rosario del día y '
                          'empiezan solas las oraciones guiadas. Si lo desactivás, '
                          'solo verás la pantalla de alarma.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: AppHomeColors.subtitleText,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_editingId != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _editingId = null);
                      },
                      icon: Icon(Icons.close_rounded,
                          color: AppHomeColors.titleText, size: 20),
                      label: Text(
                        'Cancelar edición',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: AppHomeColors.titleText,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppCalendarLayout.sectionGap),
                  _GradientActionButton(
                    label: _editingId != null ? 'Guardar cambios' : 'Agregar alarma',
                    icon: Icons.add_alarm_rounded,
                    onTap: _saveAlarm,
                  ),
                  const SizedBox(height: AppCalendarLayout.sectionGap + 8),
                  Text(
                    'Alarmas guardadas',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.1,
                        ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (_alarms.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppCalendarLayout.horizontalPadding,
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppHomeColors.cardBackground,
                    borderRadius:
                        BorderRadius.circular(AppCalendarLayout.cardRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: AppHomeColors.cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    'Todavía no hay alarmas. Elegí fecha, hora y tocá '
                    '«Agregar alarma».',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontSize: 14,
                              height: 1.42,
                            ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppCalendarLayout.horizontalPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final a = _alarms[index];
                    final subtitle = !a.enabled
                        ? 'Desactivada'
                        : [
                              if (a.repeatDaily) 'Se repite diariamente',
                              a.repeatWeekly
                                  ? 'Se repite semanalmente'
                                  : 'Una sola vez',
                              if (a.openRosaryWithGuidedAudio)
                                'Rosario con voz',
                            ].join(' · ');

                    final next = AlarmNotificationService.instance
                        .nextFireAsDateTime(a);
                    final nextLine = !a.enabled || next == null
                        ? null
                        : 'Próxima: ${DateFormat("EEE d MMM · HH:mm", 'es').format(next)}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: AppHomeColors.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppCalendarLayout.cardRadius,
                        ),
                        elevation: 0,
                        shadowColor: AppHomeColors.cardShadow,
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppCalendarLayout.cardRadius,
                            ),
                            border: Border.all(
                              color: AppHomeColors.subtitleText
                                  .withValues(alpha: 0.12),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppHomeColors.cardShadow,
                                blurRadius: 11,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 6,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.alarm_rounded,
                                  color: AppHomeColors.todayChipIcon,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _alarmTitle(a),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          height: 1.25,
                                          color:
                                              AppHomeColors.titleText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12.5,
                                          color:
                                              AppHomeColors.subtitleText,
                                        ),
                                      ),
                                      if (nextLine != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          nextLine,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: AppHomeColors
                                                .switchActiveGradientBottom,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    switchTheme: SwitchThemeData(
                                      thumbColor:
                                          WidgetStateProperty.resolveWith((s) {
                                        if (s.contains(WidgetState.selected)) {
                                          return AppHomeColors
                                              .switchActiveThumb;
                                        }
                                        return AppHomeColors
                                            .switchInactiveThumb;
                                      }),
                                      trackColor:
                                          WidgetStateProperty.resolveWith((s) {
                                        if (s.contains(WidgetState.selected)) {
                                          return AppHomeColors
                                              .switchActiveTrack;
                                        }
                                        return AppHomeColors
                                            .switchInactiveTrack;
                                      }),
                                      trackOutlineColor:
                                          WidgetStateProperty.resolveWith((s) {
                                        if (s.contains(WidgetState.selected)) {
                                          return AppHomeColors
                                              .switchActiveTrackBorder;
                                        }
                                        return AppHomeColors.subtitleText
                                            .withValues(alpha: 0.25);
                                      }),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch.adaptive(
                                        value: a.enabled,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (v) =>
                                            _toggleEnabled(a, v),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar',
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              color:
                                                  AppHomeColors.titleText,
                                              size: 22,
                                            ),
                                            onPressed: () =>
                                                _editAlarm(a),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red.shade600,
                                              size: 22,
                                            ),
                                            onPressed: () =>
                                                _deleteAlarm(a),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _alarms.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppHomeColors.todayChipBackground,
        borderRadius: BorderRadius.circular(AppCalendarLayout.cardRadius),
        border: Border.all(
          color: AppHomeColors.subtitleText.withValues(alpha: 0.14),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332A3441),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x28FFFFFF),
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppHomeColors.startButtonTop,
                AppHomeColors.startButtonBottom,
              ],
            ),
            border: const Border(
              bottom: BorderSide(
                color: AppHomeColors.button3DBottomHighlight,
                width: 3,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppHomeColors.buttonShadowDark,
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
              BoxShadow(
                color: AppHomeColors.buttonShadowMid,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppHomeColors.startButtonForeground, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppHomeColors.startButtonForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
