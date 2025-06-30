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
      backgroundColor: const Color.fromRGBO(29, 64, 76, 0.5), // Fondo oscuro
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
      content: 
      prayer.isNotEmpty && prayer != 'Misterio'
          ? SingleChildScrollView(
            child: Text(
                  Data.prayers[prayer] ?? '', 
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white, // Color de texto claro para la oración
                        fontSize: 16,
                      ),
                ),
          ) : SingleChildScrollView(
                child: Column(
                  children: [
                    meditation==null ? const SizedBox.shrink() // Si meditation es null, no mostramos la imagen
                        :
                    // Si meditation no es null, mostramos la imagen
                    Image.asset(meditation.image, 
                      height: 300, // Ajusta la altura de la imagen
                      width: 300, // Ancho completo
                      fit: BoxFit.cover, // Ajusta la imagen al contenedor
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(meditation==null ? '' : meditation.scriptural,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white, // Color de texto claro
                            fontSize: 16,
                          )
                      ),
                    ),
                  ],
                ),
              ), 
      actionsPadding: EdgeInsets.zero, // Elimina el padding por defecto de las acciones
      actions: <Widget>[
              // Alineamos el botón de cerrar en la esquina superior derecha del área de acciones
              Align(
                alignment: Alignment.center, // Esto lo empuja a la esquina
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color.fromARGB(255, 255, 192, 121)),
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                  },
                ),
              ),
            ],
    );
  }
}