import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santo_rosario/providers/mystery_provider.dart';
import 'package:santo_rosario/presentations/screens/calendar_screen.dart';
import 'pray_screen.dart';
import '../../data/models/data.dart';
import '../widgets/mystery_list_item.dart';
import 'package:santo_rosario/constants/app_constants.dart';

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

  @override
  void initState() {
    super.initState(); 
    Future.microtask(() {
      if (!mounted) return;
      ref.read(mysteryProvider.notifier).initializeFromWeekday(widget.dateNow);
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Here you can define your transition.
            // For a fade transition:
            return FadeTransition(
              opacity: animation,
              child: child,
            );
            // For a slide transition from right:
            // return SlideTransition(
            //   position: Tween<Offset>(
            //     begin: const Offset(1.0, 0.0),
            //     end: Offset.zero,
            //   ).animate(animation),
            //   child: child,
            // );
            // For a scale transition:
            // return ScaleTransition(
            //   scale: animation,
            //   child: child,
            // );
          },
          transitionDuration: AppHomeLayout.transitionDuration, // Adjust duration as needed
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mysteryState = ref.watch(mysteryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppHomeColors.screenBackground,
        toolbarHeight: AppHomeLayout.appBarToolbarHeight,
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
                    style: GoogleFonts.poppins(
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