import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santo_rosario/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SantoRosarioApp(),
    ),
  );
}

