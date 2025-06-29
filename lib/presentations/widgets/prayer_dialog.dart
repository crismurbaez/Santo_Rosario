import 'package:flutter/material.dart';
import '../widgets/prayer_dialog.dart';

class PrayerDialog extends StatelessWidget {
  final String prayer;
  final String? mystery; 

  const PrayerDialog({
    super.key,
    required this.prayer,
    this.mystery,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1D404C), // Fondo oscuro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: prayer.isNotEmpty && prayer != 'Mystery'
          ? Text(
              prayer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color.fromARGB(255, 228, 207, 143), // Color de texto claro
                  ),
            )
          : Text('Misterio',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color.fromARGB(255, 228, 207, 143), // Color de texto claro
                  )
          ), 
      content: Text(
                prayer,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white, // Color de texto claro para la oración
                      fontSize: 18,
                    ),
              ),
            
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cierra el diálogo
          },
          child: Text(
            'Cerrar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color.fromARGB(255, 255, 192, 121), // Color del botón
                ),
          ),
        ),
      ],
    );
  }
}