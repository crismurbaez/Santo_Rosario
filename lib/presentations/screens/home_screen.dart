import 'package:flutter/material.dart';
import 'package:santo_rosario/presentations/screens/calendar_screen.dart';
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
  bool gozoso = false;
  bool doloroso = false;
  bool luminoso = false;
  bool glorioso = false;

  
  

  int get weekdayNowInt => widget.dateNow;
  late final String weekdayNow;

  @override
  void initState() {
    super.initState(); 


    switch(weekdayNowInt) {
      case 1:
        weekdayNow=AppWeekdays.lunes;
        gozoso = true;
        break;
      case 2:
        weekdayNow=AppWeekdays.martes;
        doloroso = true;
        break;
      case 3:
        weekdayNow=AppWeekdays.miercoles;
        glorioso = true;
        break;
      case 4:
        weekdayNow=AppWeekdays.jueves;
        luminoso = true;
        break;
      case 5:
        weekdayNow=AppWeekdays.viernes;
        doloroso = true;
        break;
      case 6:
        weekdayNow=AppWeekdays.sabado;
        gozoso = true;
        break;
      case 7:
        weekdayNow=AppWeekdays.domingo;
        glorioso = true;
        break;
      default:
        weekdayNow=AppWeekdays.lunes;
        gozoso = true;
      break;

    }
  }

  void _toggleMystery(String mystery, bool value) {
    setState(() {
      gozoso = mystery == AppMysteryTypes.gozosos ? value : false;
      doloroso = mystery == AppMysteryTypes.dolorosos ? value : false;
      luminoso = mystery == AppMysteryTypes.luminosos ? value : false;
      glorioso = mystery == AppMysteryTypes.gloriosos ? value : false;
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
      String? mysteryType;
      if (gozoso) {
        mysteryType = AppMysteryTypes.gozosos;
      } else if (glorioso) {
        mysteryType = AppMysteryTypes.gloriosos;
      } else if (doloroso) {
        mysteryType = AppMysteryTypes.dolorosos;
      } else if (luminoso) {
        mysteryType = AppMysteryTypes.luminosos;
    }

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

    bool _getMysteryValue(String key) {
    switch (key) {
      case AppMysteryTypes.gozosos:
        return gozoso;
      case AppMysteryTypes.gloriosos:
        return glorioso;
      case AppMysteryTypes.dolorosos:
        return doloroso;
      case AppMysteryTypes.luminosos:
        return luminoso;
      default:
        return gozoso; 
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
                          value: _getMysteryValue(mystery.mystery), 
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