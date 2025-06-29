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

    MysteryDetail? _getMysteryDetail(String mysteryName) {
    for (final my in Data.mysteries) {
      if (my.mystery == mysteryName) {
        return my; // Encontramos el detalle del misterio y lo retornamos
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

    MysteryDetail? mysteryDetail;
    if (mystery != null) {
      mysteryDetail = _getMysteryDetail(mystery!);
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
      content: 
      prayer.isNotEmpty && prayer != 'Misterio'
          ? Text(
                Data.prayers[prayer] ?? '', 
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white, // Color de texto claro para la oración
                      fontSize: 12,
                    ),
              ) : SingleChildScrollView(
                child: Column(
                  children: [
                    mysteryDetail==null ? const SizedBox.shrink() // Si mysteryDetail es null, no mostramos la imagen
                        :
                    // Si mysteryDetail no es null, mostramos la imagen
                    Image.asset(mysteryDetail.imageAsset, 
                    //TODO: cambiar por la imagen del misterio adecuado
                    //TODO: agregar más imágenes al proyecto y poner las rutas en MysteriesMeditations
                    //TODO: agregar el pedidos de las rutas en _getMeditation y borrar la función _getMysteryDetail
                      height: 150, // Ajusta la altura de la imagen
                      width: 150, // Ancho completo
                      fit: BoxFit.cover, // Ajusta la imagen al contenedor
                    ),
                    Text(meditation==null ? '' : meditation.scriptural,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white, // Color de texto claro
                          fontSize: 12,
                        )
                    ),
                  ],
                ),
              ), 
            // mysteryDetail!.imageAsset
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