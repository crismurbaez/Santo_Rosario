import 'package:flutter/material.dart';
import '../../data/models/data.dart'; 

class PrayerDialog extends StatelessWidget {
  final String prayer;
  final String? mystery;
  final int? currentMysteryOrder; 

  const PrayerDialog({
    super.key,
    required this.prayer,
    this.mystery,
    this.currentMysteryOrder,
  });

  MysteriesMeditations? _getMeditation(String mysteryName, int orderNumber) {
    for (final m in Data.meditations) {
      if (m.mystery == mysteryName && m.order == orderNumber) {
        return m; // Encontramos la meditación, la retornamos
      }
    }
    return null; // Si el bucle termina y no encontramos nada, retornamos null
  }

  @override
  Widget build(BuildContext context) {

    MysteriesMeditations? meditation;
    if (mystery != null && currentMysteryOrder != null) {
      meditation = _getMeditation(mystery!, currentMysteryOrder!);
    }


    return AlertDialog(
      backgroundColor: Color.fromRGBO(29, 64, 76, 0.5), // Fondo oscuro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: prayer.isNotEmpty && prayer != 'Misterio'
          ? Text(
              prayer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color.fromARGB(255, 228, 207, 143), // Color de texto claro
                    fontSize: 20,
                  ),
            )
          : Text(meditation==null ?  '' : meditation.meditation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color.fromARGB(255, 228, 207, 143), // Color de texto claro
                    fontSize: 20,
                  )
          ), 
      content: prayer.isNotEmpty && prayer != 'Misterio'
          ? Text(
                Data.prayers[prayer] ?? '', 
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white, // Color de texto claro para la oración
                      fontSize: 12,
                    ),
              ) : Text(meditation==null ? '' : meditation.scriptural,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white, // Color de texto claro
                    fontSize: 12,
                  )
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