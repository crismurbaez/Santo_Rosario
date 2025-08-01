import 'package:flutter/material.dart';
import 'pray_screen_3.dart';
import '../../data/models/data.dart';
import '../widgets/mystery_list_item.dart';

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
        weekdayNow='Lunes';
        gozoso = true;
        break;
      case 2:
        weekdayNow='Martes';
        doloroso = true;
        break;
      case 3:
        weekdayNow='Miércoles';
        glorioso = true;
        break;
      case 4:
        weekdayNow='Jueves';
        luminoso = true;
        break;
      case 5:
        weekdayNow='Viernes';
        doloroso = true;
        break;
      case 6:
        weekdayNow='Sábado';
        gozoso = true;
        break;
      case 7:
        weekdayNow='Domingo';
        glorioso = true;
        break;
      default:
        weekdayNow='Lunes';
        gozoso = true;
      break;

    }
  }

  void _toggleMystery(String mystery, bool value) {
    setState(() {
      gozoso = mystery == 'gozosos' ? value : false;
      doloroso = mystery == 'dolorosos' ? value : false;
      luminoso = mystery == 'luminosos' ? value : false;
      glorioso = mystery == 'gloriosos' ? value : false;
    });
  }

    void _navigateToPray() {
      String? mysteryType;
      if (gozoso) {
        mysteryType = 'gozosos';
      } else if (glorioso) {
        mysteryType = 'gloriosos';
      } else if (doloroso) {
        mysteryType = 'dolorosos';
      } else if (luminoso) {
        mysteryType = 'luminosos';
    }

    if (mysteryType != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PrayScreen3(mystery: mysteryType),
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
          transitionDuration: const Duration(milliseconds: 500), // Adjust duration as needed
        ),
      );
    }
  }

    bool _getMysteryValue(String key) {
    switch (key) {
      case 'gozosos':
        return gozoso;
      case 'gloriosos':
        return glorioso;
      case 'dolorosos':
        return doloroso;
      case 'luminosos':
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
        toolbarHeight: 50.0,
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
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 130.0),
            child: IntrinsicHeight( // <--- Importante para que Column sepa su "altura ideal"
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            children: [
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
                backgroundColor: const Color.fromRGBO(255, 192, 121, 1),
                foregroundColor: const Color.fromRGBO(0, 0, 0, 1),
              ),
              onPressed: _navigateToPray,
              child: const Text(
                'Comenzar',
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
  
}