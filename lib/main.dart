import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santo Rosario',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x88BBC9D9)),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF242C3B),
          ),
          displayMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF242C3B),
          ),
          displaySmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(10, 101, 172, 1),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Santo Rosario'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool gozoso = true;
  bool doloroso = false;
  bool luminoso = false;
  bool glorioso = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 70.0,
        title: Column(children: [
          ListTile(
            title: Align(alignment: Alignment.center,
              child: Text (
              'Misterios del ${widget.title}',
              style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            subtitle: Align(alignment: Alignment.center,
              child: Text (
              'Selecciona el misterio de acuerdo al día y presiona comenzar.',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
              ),
            ),),

        ],)
      ),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
                   ListTile(
                    leading: Image.asset('assets/images/gozosos.png',),
                    title: Text('MISTERIOS GOZOSOS',
                    style: Theme.of(context).textTheme.displayMedium,),
                    subtitle: Text(
                      'Se rezan los días Lunes y Sábados',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    trailing: Switch(
                            value: gozoso, 
                            onChanged: (bool value) {
                              setState(() {
                                gozoso = value;
                              });
                            },
                            ),
                  ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
                ListTile(
                    leading: Image.asset('assets/images/gloriosos.png',),
                    title: Text('MISTERIOS GLORIOSOS',
                    style: Theme.of(context).textTheme.displayMedium,),
                    subtitle: Text(
                      'Se rezan los días Miércoles y Domingos',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    trailing: Switch(
                            value: glorioso, 
                            onChanged: (bool value) {
                              setState(() {
                                glorioso = value;
                              });
                            },
                            ),
                  ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
               ListTile(
                    leading: Image.asset('assets/images/dolorosos.png',),
                    title: Text('MISTERIOS DOLOROSOS',
                    style: Theme.of(context).textTheme.displayMedium,),
                    subtitle: Text(
                      'Se rezan los días Martes y Viernes',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    trailing: Switch(
                            value: doloroso, 
                            onChanged: (bool value) {
                              setState(() {
                                doloroso = value;
                              });
                            },
                            ),
                  ),
              const Divider(
                color: Colors.white24,
                thickness: 2,
                height: 20,
              ),
              ListTile(
                    leading: Image.asset('assets/images/luminosos.png',),
                    title: Text('MISTERIOS LUMINOSOS',
                    style: Theme.of(context).textTheme.displayMedium,),
                    subtitle: Text(
                      'Se rezan los días Jueves',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    trailing: Switch(
                            value: luminoso, 
                            onChanged: (bool value) {
                              setState(() {
                                luminoso = value;
                              });
                            },
                            ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
