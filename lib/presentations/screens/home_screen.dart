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
      gozoso = mystery == 'gozosos' ? value : false;
      doloroso = mystery == 'dolorosos' ? value : false;
      luminoso = mystery == 'luminosos' ? value : false;
      glorioso = mystery == 'gloriosos' ? value : false;
    });
  }

  void _navigateToPray() {
    if (gozoso) {
      Navigator.pushNamed(
        context,
        '/pray3',
        arguments: 'gozosos', 
      );
    } else if (glorioso) {
      Navigator.pushNamed(
        context,
        '/pray3',
        arguments: 'gloriosos', 
      );
    } else if (doloroso) {
      Navigator.pushNamed(
        context,
        '/pray3',
        arguments: 'dolorosos', 
      );
    } else if (luminoso) {
      Navigator.pushNamed(
        context,
        '/pray3',
        arguments: 'luminosos', 
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 70.0),
            child: IntrinsicHeight( // <--- Importante para que Column sepa su "altura ideal"
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  StartButton(onPressed: _navigateToPray),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}