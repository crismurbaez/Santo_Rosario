import 'package:flutter/material.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import 'presentations/screens/home_screen.dart';
import 'presentations/screens/pray_screen.dart';

/// Navigator raíz para abrir rutas cuando entra una notificación de alarma.
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>();

/// Títulos: Playfair Display (assets). Resto sans: Poppins (assets).
TextTheme _appTextTheme() {
  return const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 22,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.35,
      color: AppHomeColors.titleText,
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: AppHomeColors.titleText,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: AppHomeColors.subtitleText,
    ),
  );
}

class SantoRosarioApp extends StatelessWidget {
  const SantoRosarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appRootNavigatorKey,
      title: 'Santo Rosario',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x88BBC9D9)),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: _appTextTheme(),
      ),
      home: HomeScreen(
        title: 'Santo Rosario',
        dateNow: DateTime.now().weekday,
        ),
      debugShowCheckedModeBanner: false,
      routes: {
      '/pray3': (context) {
          final mystery = ModalRoute.of(context)?.settings.arguments as String?;
          return PrayScreen(mystery: mystery);
  },
},
    );
  }
}
