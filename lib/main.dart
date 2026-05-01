import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santo_rosario/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/env/app.env');
  } catch (e, st) {
    debugPrint('[main] Sin app.env, intentando app.env.example: $e');
    debugPrint('$st');
    try {
      await dotenv.load(fileName: 'assets/env/app.env.example');
    } catch (e2) {
      debugPrint('[main] No se cargó ningún archivo de entorno: $e2');
    }
  }

  runApp(
    const ProviderScope(
      child: SantoRosarioApp(),
    ),
  );
}

