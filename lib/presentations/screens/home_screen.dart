import 'package:flutter/material.dart';
import 'package:santo_rosario/presentations/screens/calendar_screen.dart';
import 'package:santo_rosario/utils/mystery_utils.dart';
import 'pray_screen.dart';
import '../../data/models/data.dart';
import '../widgets/mystery_list_item.dart';
import 'package:santo_rosario/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(
    {super.key, 
    required this.title,
    required this.dateNow
    });
  final String title;
  final int dateNow;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int get weekdayNowInt => widget.dateNow;
  late final String weekdayNow;
  late String selectedMystery;

  @override
  void initState() {
    super.initState(); 

    weekdayNow = MysteryUtils.weekdayName(weekdayNowInt);
    selectedMystery = MysteryUtils.mysteryForWeekday(weekdayNowInt);
  }

  void _toggleMystery(String mystery, bool value) {
    setState(() {
      selectedMystery = value ? mystery : '';
    });
  }
    void _navigateToCalendar(){
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CalendarScreen(),
        ),
      );
    }
    void _navigateToPray() {
      final mysteryType = selectedMystery.isNotEmpty ? selectedMystery : null;

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - AppHomeLayout.minHeightOffset),
            child: IntrinsicHeight( // <--- Importante para que Column sepa su "altura ideal"
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppHomeLayout.horizontalPadding),
                    child: Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            children: [
                              IconButton(
                                onPressed: _navigateToCalendar, 
                                icon: Icon(Icons.add_alert_sharp,)),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Hoy es $weekdayNow',
                                  style: Theme.of(context).textTheme.displaySmall,
                                  textAlign: TextAlign.left,
                                  softWrap: false,
                                  maxLines: 1, 
                                ),
                              ),
                              //  Align(
                              //   alignment: Alignment.center,
                              //   child: Text(
                              //     '${DateTime.now().hour.toString()} : ${DateTime.now().minute.toString()}',
                              //     style: Theme.of(context).textTheme.displaySmall,
                              //     textAlign: TextAlign.left,
                              //     softWrap: false,
                              //     maxLines: 1, 
                              //   ),
                              // ),
                              const Divider(
                                color: Colors.white24,
                                thickness: 2,
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                  ),
                  ...Data.mysteries.map((mystery) {
                    return Column(
                      children: [
                        MysteryListItem(
                          title: mystery.title, 
                          subtitle: mystery.subtitle, 
                          imageAsset: mystery.imageAsset, 
                          value: selectedMystery == mystery.mystery, 
                          onChanged:(value) => _toggleMystery(mystery.mystery, value),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.inversePrimary,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppHomeColors.startButtonBackground,
                foregroundColor: AppHomeColors.startButtonForeground,
              ),
              onPressed: _navigateToPray,
              child: const Text(
                'Comenzar',
                style: TextStyle(
                  color: AppHomeColors.startButtonForeground,
                  fontSize: AppHomeLayout.startButtonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
  
}