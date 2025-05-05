import 'package:flutter/material.dart';
import '../widgets/mystery_list_item.dart';
import '../widgets/start_button.dart';

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
      gozoso = mystery == 'gozoso' ? value : false;
      doloroso = mystery == 'doloroso' ? value : false;
      luminoso = mystery == 'luminoso' ? value : false;
      glorioso = mystery == 'glorioso' ? value : false;
    });
  }

  void _navigateToPray() {
    if (gozoso) {
      Navigator.pushNamed(
        context,
        '/pray',
        arguments: 'gozosos', 
      );
    } else if (glorioso) {
      Navigator.pushNamed(
        context,
        '/pray_2',
        arguments: 'gloriosos', 
      );
    } else if (doloroso) {
      Navigator.pushNamed(
        context,
        '/pray',
        arguments: 'dolorosos', 
      );
    } else if (luminoso) {
      Navigator.pushNamed(
        context,
        '/pray',
        arguments: 'luminosos', 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 70.0,
        title: Column(
          children: [
            ListTile(
              title: Align(
                alignment: Alignment.center,
                child: Text(
                  'Misterios del ${widget.title}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              subtitle: Align(
                alignment: Alignment.center,
                child: Text(
                  'Selecciona el misterio de acuerdo al día y presiona comenzar.',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
              MysteryListItem(
                title: 'MISTERIOS GOZOSOS',
                subtitle: 'Se rezan los días Lunes y Sábados',
                imageAsset: 'assets/images/gozosos.png',
                value: gozoso,
                onChanged: (value) => _toggleMystery('gozoso', value),
              ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
              MysteryListItem(
                title: 'MISTERIOS GLORIOSOS',
                subtitle: 'Se rezan los días Miércoles y Domingos',
                imageAsset: 'assets/images/gloriosos.png',
                value: glorioso,
                onChanged: (value) => _toggleMystery('glorioso', value),
              ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
              MysteryListItem(
                title: 'MISTERIOS DOLOROSOS',
                subtitle: 'Se rezan los días Martes y Viernes',
                imageAsset: 'assets/images/dolorosos.png',
                value: doloroso,
                onChanged: (value) => _toggleMystery('doloroso', value),
              ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
              MysteryListItem(
                title: 'MISTERIOS LUMINOSOS',
                subtitle: 'Se rezan los días Jueves',
                imageAsset: 'assets/images/luminosos.png',
                value: luminoso,
                onChanged: (value) => _toggleMystery('luminoso', value),
              ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
              StartButton(onPressed: _navigateToPray),
            ],
          ),
        ),
      ),
    );
  }
}