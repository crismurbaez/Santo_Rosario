import 'package:flutter/material.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return 
    // Card(
    //   color: const Color.fromARGB(0, 49, 177, 206),
    //   margin: const EdgeInsets.all(20),
    //   child: 
      ElevatedButton(
        onPressed: onPressed,
        child: const Text('Comenzar'),
      );
    // );
  }
}