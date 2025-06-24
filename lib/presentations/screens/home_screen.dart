import 'package:flutter/material.dart';
import '../widgets/mystery_list_item.dart';
import '../widgets/start_button.dart';
import '../../data/models/data.dart';

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
      // gozoso = mystery == 'gozoso' ? value : false;
      // doloroso = mystery == 'doloroso' ? value : false;
      // luminoso = mystery == 'luminoso' ? value : false;
      // glorioso = mystery == 'glorioso' ? value : false;


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
        '/pray1',
        arguments: 'gloriosos', 
      );
    } else if (doloroso) {
      Navigator.pushNamed(
        context,
        '/pray2',
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

  bool _getMysteryValue(String key) {
  switch (key) {
    case 'gozoso':
      return gozoso;
    case 'glorioso':
      return glorioso;
    case 'doloroso':
      return doloroso;
    case 'luminoso':
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
                    const Divider(
                      color: Colors.white24,
                      thickness: 2,
                      height: 20,
                    ),
                  ],
                );
              }).toList(),
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