import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santo_rosario/providers/mystery_provider.dart';
import 'package:santo_rosario/presentations/screens/calendar_screen.dart';
import 'pray_screen.dart';
import '../../data/models/data.dart';
import '../widgets/mystery_list_item.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'package:santo_rosario/services/preferences_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen(
    {super.key, 
    required this.title,
    required this.dateNow
    });
  final String title;
  final int dateNow;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _preferencesService = PreferencesService();

  bool _savePrayerProgressEnabled = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      ref.read(mysteryProvider.notifier).initializeFromWeekday(widget.dateNow);
      final save = await _preferencesService.getSavePrayerProgressEnabled();
      if (mounted) setState(() => _savePrayerProgressEnabled = save);
    });
  }

  void _toggleMystery(String mystery, bool value) {
    ref.read(mysteryProvider.notifier).toggleMystery(mystery, value);
  }
    void _navigateToCalendar(){
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CalendarScreen(),
        ),
      );
    }
    void _navigateToPray() {
      final mysteryType = ref.read(mysteryProvider.notifier).mysteryToPray;

      if (mysteryType != null) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PrayScreen(mystery: mysteryType),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: AppHomeLayout.transitionDuration,
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppHomeColors.todayChipBackground,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Seleccioná un misterio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppHomeColors.titleText,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
            ),
            content: Text(
              'Para comenzar la oración tenés que elegir un '
              'misterio (Gozosos, Dolorosos, Gloriosos o Luminosos).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppHomeColors.subtitleText,
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    height: 1.4,
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Entendido',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppHomeColors.titleText,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

  void _showHomeSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var tutorialResetPressed = false;
        var progressClearPressed = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: ColoredBox(
                  color: AppHomeColors.screenBackground,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppHomeColors.todayChipIcon
                                  .withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Text(
                          'Configuración',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppHomeColors.titleText,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Personalizá tu experiencia durante la oración',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppHomeColors.subtitleText,
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Tutorial de la aplicación',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppHomeColors.titleText,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            splashColor: AppHomeColors.startButtonForeground
                                .withValues(alpha: 0.18),
                            highlightColor: AppHomeColors.startButtonForeground
                                .withValues(alpha: 0.12),
                            onTap: () async {
                              tutorialResetPressed = true;
                              setModalState(() {});
                              await Future<void>.delayed(
                                const Duration(milliseconds: 220),
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              await _preferencesService
                                  .resetPrayScreenHelpTips();
                              if (!mounted || !context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppHomeColors.titleText,
                                  content: const Text(
                                    'La próxima vez que entres en la pantalla de oración verás de nuevo el tutorial de la aplicación.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: tutorialResetPressed
                                      ? [
                                          Color.lerp(
                                            AppHomeColors.startButtonTop,
                                            Colors.black,
                                            0.16,
                                          )!,
                                          Color.lerp(
                                            AppHomeColors.startButtonBottom,
                                            Colors.black,
                                            0.2,
                                          )!,
                                        ]
                                      : const [
                                          AppHomeColors.startButtonTop,
                                          AppHomeColors.startButtonBottom,
                                        ],
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppHomeColors
                                        .button3DBottomHighlight,
                                    width: 3,
                                  ),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppHomeColors.buttonShadowDark,
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: AppHomeColors.buttonShadowMid,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: AppHomeColors.buttonShadowLight,
                                    blurRadius: 4,
                                    offset: Offset(0, -1),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.school_rounded,
                                      color:
                                          AppHomeColors.startButtonForeground,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mostrar de nuevo el tutorial de la aplicación',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: AppHomeColors
                                                      .startButtonForeground,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tocá este botón: los mensajes '
                                            'que ocultaste vuelven al pulsar '
                                            'Comenzar.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppHomeColors
                                                      .startButtonForeground
                                                      .withValues(
                                                          alpha: 0.82),
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12.5,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 18,
                                      color: AppHomeColors.startButtonForeground
                                          .withValues(alpha: 0.75),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Avance del rosario',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppHomeColors.titleText,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
                          decoration: BoxDecoration(
                            color: AppHomeColors.todayChipBackground,
                            borderRadius: BorderRadius.circular(
                              AppHomeLayout.todayCardRadius,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x45304055),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Color(0x33FFFFFF),
                                blurRadius: 2,
                                offset: Offset(0, -1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.bookmark_added_outlined,
                                      color: AppHomeColors.todayChipIcon,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Guardar avance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppHomeColors.titleText,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                          ),
                                    ),
                                  ),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      switchTheme: SwitchThemeData(
                                        thumbColor:
                                            WidgetStateProperty.resolveWith(
                                          (states) {
                                            if (states.contains(
                                                WidgetState.selected)) {
                                              return AppHomeColors
                                                  .switchActiveThumb;
                                            }
                                            return AppHomeColors
                                                .switchInactiveThumb;
                                          },
                                        ),
                                        trackColor:
                                            WidgetStateProperty.resolveWith(
                                          (states) {
                                            if (states.contains(
                                                WidgetState.selected)) {
                                              return AppHomeColors
                                                  .switchActiveTrack;
                                            }
                                            return AppHomeColors
                                                .switchInactiveTrack;
                                          },
                                        ),
                                        trackOutlineColor:
                                            WidgetStateProperty.resolveWith(
                                          (states) {
                                            if (states.contains(
                                                WidgetState.selected)) {
                                              return AppHomeColors
                                                  .switchActiveTrackBorder;
                                            }
                                            return AppHomeColors.subtitleText
                                                .withValues(alpha: 0.25);
                                          },
                                        ),
                                      ),
                                    ),
                                    child: Switch.adaptive(
                                      value: _savePrayerProgressEnabled,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (value) async {
                                        await _preferencesService
                                            .setSavePrayerProgressEnabled(
                                                value);
                                        if (!value) {
                                          await _preferencesService
                                              .clearPrayerProgressSnapshot();
                                        }
                                        setState(() =>
                                            _savePrayerProgressEnabled =
                                                value);
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 34),
                                child: Text(
                                  'Si salís sin terminar, al volver con el mismo '
                                  'tipo de misterios continuás donde dejaste. '
                                  'Cambiar de misterio reinicia ese avance. '
                                  'Al desactivar se borra lo guardado.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppHomeColors.subtitleText,
                                        fontFamily: 'Poppins',
                                        fontSize: 12.5,
                                        height: 1.4,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            splashColor: AppHomeColors.titleText
                                .withValues(alpha: 0.10),
                            highlightColor: AppHomeColors.titleText
                                .withValues(alpha: 0.06),
                            onTap: () async {
                              progressClearPressed = true;
                              setModalState(() {});
                              await Future<void>.delayed(
                                const Duration(milliseconds: 220),
                              );
                              await _preferencesService
                                  .clearPrayerProgressSnapshot();
                              if (!sheetContext.mounted) return;
                              progressClearPressed = false;
                              setModalState(() {});
                              if (!mounted || !context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppHomeColors.titleText,
                                  content: const Text(
                                    'Se borró el avance guardado. La próxima '
                                    'vez que entres en la oración comenzarás '
                                    'desde el inicio de la secuencia.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: progressClearPressed
                                      ? [
                                          Color.lerp(
                                            AppHomeColors.todayChipBackground,
                                            Colors.black,
                                            0.10,
                                          )!,
                                          Color.lerp(
                                            AppHomeColors.cardBackground,
                                            Colors.black,
                                            0.12,
                                          )!,
                                        ]
                                      : const [
                                          AppHomeColors.todayChipBackground,
                                          AppHomeColors.cardBackground,
                                        ],
                                ),
                                border: Border.all(
                                  color: AppHomeColors.subtitleText
                                      .withValues(alpha: 0.22),
                                  width: 1,
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.restart_alt_rounded,
                                      color: AppHomeColors.titleText
                                          .withValues(alpha: 0.9),
                                      size: 26,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Borrar avance de la oración',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: AppHomeColors.titleText,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Eliminá lo guardado: al volver a '
                                            'orar con el mismo tipo de '
                                            'misterios empezás desde el '
                                            'principio.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppHomeColors
                                                      .subtitleText,
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12.5,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 18,
                                      color: AppHomeColors.subtitleText
                                          .withValues(alpha: 0.65),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mysteryState = ref.watch(mysteryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppHomeColors.screenBackground,
        toolbarHeight: AppHomeLayout.appBarToolbarHeight,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Configuración',
            color: AppHomeColors.titleText,
            onPressed: _showHomeSettings,
          ),
        ],
        title:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,// Alinea el texto a la izquierda
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Misterios del ${widget.title}',
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.left,
                        softWrap: false,
                        maxLines: 1, 
                      ),
                    ),
                  ],
                ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppHomeColors.screenBackground),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final safeBottom = MediaQuery.paddingOf(context).bottom;
            final scrollListBottomPad =
                safeBottom + AppHomeLayout.scrollClearOfBottomBarMin;
            final hRaw = constraints.maxHeight;
            final h = (hRaw - AppHomeLayout.bodyBottomVisualReserve)
                .clamp(80.0, hRaw);
            final compact = hRaw < 600;
            final topGap = compact
                ? (h * 0.02).clamp(8.0, 18.0)
                : (h * 0.045).clamp(14.0, 36.0);
            final itemGap = compact
                ? (h * 0.012).clamp(6.0, 14.0)
                : (h * 0.028).clamp(10.0, 24.0);

            final chipGuess = compact
                ? AppHomeLayout.chipHeightEstimateCompact
                : AppHomeLayout.chipHeightEstimateRelaxed;
            final gapsBetweenFourRows = 3 * itemGap;
            final remainderAfterHeader =
                h - topGap - chipGuess - itemGap - gapsBetweenFourRows;
            final fillVertically = remainderAfterHeader >=
                4 * AppHomeLayout.mysteryRowMinSlotHeight + 10.0;

            final todayChip = Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppHomeLayout.horizontalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppHomeLayout.todayCardMaxWidth,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 14 : 18,
                      vertical: compact ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppHomeColors.todayChipBackground,
                      borderRadius: BorderRadius.circular(
                        AppHomeLayout.todayCardRadius,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x45304055),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Color(0x33FFFFFF),
                          blurRadius: 2,
                          offset: Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _navigateToCalendar,
                          visualDensity: VisualDensity.compact,
                          iconSize: compact ? 20 : 22,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add_alert_sharp,
                            color: AppHomeColors.todayChipIcon,
                          ),
                        ),
                        Text(
                          'Hoy es ${mysteryState.weekdayNow}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            if (fillVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topGap),
                  todayChip,
                  SizedBox(height: itemGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < Data.mysteries.length; i++) ...[
                          if (i > 0) SizedBox(height: itemGap),
                          Expanded(
                            child: MysteryListItem(
                              expandToParentSlot: true,
                              title: Data.mysteries[i].title,
                              subtitle: Data.mysteries[i].subtitle,
                              imageAsset: Data.mysteries[i].imageAsset,
                              value: mysteryState.selectedMystery ==
                                  Data.mysteries[i].mystery,
                              onChanged: (value) => _toggleMystery(
                                Data.mysteries[i].mystery,
                                value,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: AppHomeLayout.fillModeFooterBreathingRoom),
                ],
              );
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: scrollListBottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: topGap),
                    todayChip,
                    SizedBox(height: itemGap),
                    ...Data.mysteries.asMap().entries.expand((entry) {
                      final mystery = entry.value;
                      final isLast =
                          entry.key == Data.mysteries.length - 1;
                      return <Widget>[
                        MysteryListItem(
                          title: mystery.title,
                          subtitle: mystery.subtitle,
                          imageAsset: mystery.imageAsset,
                          value:
                              mysteryState.selectedMystery == mystery.mystery,
                          onChanged: (value) =>
                              _toggleMystery(mystery.mystery, value),
                        ),
                        if (!isLast) SizedBox(height: itemGap),
                      ];
                    }),
                    SizedBox(height: itemGap),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppHomeColors.screenBackground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppHomeColors.startButtonTop,
                AppHomeColors.startButtonBottom,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppHomeColors.button3DBottomHighlight,
                width: 3,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppHomeColors.buttonShadowDark,
                blurRadius: 16,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: AppHomeColors.buttonShadowMid,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: AppHomeColors.buttonShadowLight,
                blurRadius: 4,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: _navigateToPray,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'Comenzar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppHomeColors.startButtonForeground,
                      fontSize: AppHomeLayout.startButtonFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
}