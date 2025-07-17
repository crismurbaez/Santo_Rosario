import 'package:flutter/material.dart';

class StartButton extends StatelessWidget {
  const StartButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return 
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(255, 192, 121, 1),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        ),
        onPressed: onPressed,
        child:  const Text(
          'Comenzar',
          style: TextStyle(
            color: Color.fromRGBO(0, 0, 0, 1),
            ),
          )
      );
  }
}