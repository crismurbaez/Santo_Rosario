import 'package:flutter/material.dart';
import 'presentations/screens/home_screen.dart';
import 'presentations/screens/pray_screen_3.dart';

class SantoRosarioApp extends StatelessWidget {
  const SantoRosarioApp({super.key});

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
      home: const HomeScreen(title: 'Santo Rosario'),
      debugShowCheckedModeBanner: false,
      routes: {
      '/pray3': (context) {
          final mystery = ModalRoute.of(context)?.settings.arguments as String?;
          return PrayScreen3(mystery: mystery);
  },
},
    );
  }
}