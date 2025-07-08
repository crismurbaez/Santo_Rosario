import 'package:flutter/material.dart';
import '../widgets/mystery_list_item.dart';
import '../widgets/start_button.dart';
import '../../data/models/data.dart';
import 'pray_screen_3.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool gozoso = true;
  bool doloroso = false;
  bool luminoso = false;
  bool glorioso = false;

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
      //TODO acomodar problema de letra muy grande
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 120.0),
            child: IntrinsicHeight( // <--- Importante para que Column sepa su "altura ideal"
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selecciona el misterio de acuerdo al día y presiona comenzar.',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.left,
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
                        // const Divider(
                        //   color: Colors.white24,
                        //   thickness: 2,
                        //   height: 20,
                        // ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:BottomAppBar(
        color: Theme.of(context).colorScheme.inversePrimary,
        child: Center(
          child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: StartButton(onPressed: _navigateToPray),
                ),
        ),
      ),   
    );
  }
}