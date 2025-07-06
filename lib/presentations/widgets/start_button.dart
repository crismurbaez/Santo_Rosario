import 'package:flutter/material.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return 
      ElevatedButton(
        onPressed: onPressed,
        child: const FittedBox(
          fit: BoxFit.scaleDown, // Escala hacia abajo si no cabe
          alignment: Alignment.center,
          child: Text('Comenzar')
          ),
      );
    // );
  }
}