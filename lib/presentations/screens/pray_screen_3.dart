import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/data.dart'; 

class PrayScreen3 extends StatefulWidget {

  const PrayScreen3({
    super.key,
    required this.mystery,
  });
  final String? mystery;
      @override
    State<PrayScreen3> createState() => _PrayScreen3State();
}


class _PrayScreen3State extends State<PrayScreen3> {
  // Mapa para almacenar las imágenes cargadas
  Map<String, ui.Image>? _loadedImages;

    @override
  void initState() {
    super.initState();
    _loadAllImages(); // Inicia la carga de todas las imágenes
  }

   // Función asíncrona para cargar todas las imágenes
  Future<void> _loadAllImages() async {
    final Map<String, ui.Image> images = {};
    for (var entry in Data.cuentas.entries) {
      final String key = entry.key;
      final String assetPath = entry.value;

      // Carga el asset como ByteData
      final ByteData data = await rootBundle.load(assetPath);
      // Decodifica la imagen
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      images[key] = frameInfo.image;
    }

    setState(() {
      _loadedImages = images; // Actualiza el estado con las imágenes cargadas
    });
  }
  
  @override
  Widget build(BuildContext context) {

    const Color backgroundColor = Color(0xFF1D404C);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 70.0,
      ),
      body: Stack (
        children: <Widget>[
          Container(
            color: backgroundColor,
          ),
          Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) { 
                // Muestra un indicador de carga si las imágenes aún no se han cargado
                if (_loadedImages == null) {
                  return const CircularProgressIndicator(
                    color: Colors.amber, // Color del indicador
                  );
                }

                // se obtienen las dimensiones de la pantalla 
                //y se saca un porcentaje que se considera el margen adaptable a todas las pantallas
                final double width = 0.9 * constraints.maxWidth;
                final double height = 0.69 * constraints.maxHeight;  

                return 
                SizedBox(
                  width: width,
                  height: height,
                  child: 
                  CustomPaint(
                    painter : cuentasPainter(
                      cuentas: _loadedImages!,
                      
                    )
                  ),
                );
            }),
            ),
        ]
      )
    );
  }
}

class cuentasPainter extends CustomPainter {
  final Map<String,  ui.Image> cuentas;

  cuentasPainter({
    required this.cuentas,
  });

  @override
  void paint(Canvas canvas, Size size) {
      //se calcula el centro del canvas
      Offset center = Offset(size.width/2, (size.height/2));
      double radius;
      //tener en cuenta el tamaño de pantalla s8 que es el que mejor se dapta al tamaño actual de las imágenes
      debugPrint('-------------------------------------');
      debugPrint('Tamaño de pantalla ancho x alto: ${size.width} x ${size.height}');
      debugPrint('Tamaño de perlas ancho x alto: ${size.width*0.10} x ${size.height*.10}');
      debugPrint('Tamaño de perla: ${min(size.width*0.10,size.height*.10)}');
      double imageWidthBasic;
      double imageHeightBasic;
      double imageWidthLarge;
      double imageHeightLarge;
      double imageWidthLargest;
      double imageHeightLargest;
      double cuentasAdicionales = 5 * 30;
      int orientation;
      ui.Image image;
      late Rect dstcuentas;
      // se inicializa con este valor, pero luego se cambia
      //se usa para dibujar la extensión del rosario
      Offset medallaCenter = center;

      //teniendo en cuenta la orientación de la pantalla, se determina si la extensión se dibuja debajo o dentro del rosario
      //si se dibuja debajo, se le resta la parte vertical del rosario para que no se salga de la pantalla
      // si el ancho es menor que el alto se hace la resta y se cambia la orientación.

      // obtiene el menor radio entre el ancho y el alto de la pantalla,
      if (size.width<size.height) {
        //se desplaza el centro hacia arriba para que entre la extensión y no salga de la pantalla
        cuentasAdicionales = size.height * 0.34;
        radius = min((size.width / 2),((size.height - cuentasAdicionales) / 2)); 
        debugPrint('Radio: $radius');
        debugPrint('Tamaño de perla: ${radius*0.20}');
        imageWidthBasic = radius * 0.20;
        imageHeightBasic = radius * 0.20;
        imageWidthLarge = radius * 0.60;
        imageHeightLarge = radius * 0.60;
        imageWidthLargest = radius * 0.90;
        imageHeightLargest = radius * 0.90;
        debugPrint('Tamaño de perla: ${radius*0.20} $imageWidthBasic');
        cuentasAdicionales = 5 * imageHeightBasic;
        debugPrint('cuentasAdicionales: $cuentasAdicionales ${size.height * 0.34}');
        center = Offset(center.dx, center.dy - cuentasAdicionales);
        //la extensión se dibuja debajo del rosario
        orientation = 1;
      } else {
        // la extensión se dibuja dentro del rosario
        orientation = -1;
        radius = min((size.width / 2),((size.height) / 2)); 
        debugPrint('Radio: $radius');
        debugPrint('traslación: ${radius * 0.017}');
        debugPrint('Tamaño de perla: ${radius*0.20}');
        imageWidthBasic = radius * 0.20;
        imageHeightBasic = radius * 0.20;
        imageWidthLarge = radius * 0.50;
        imageHeightLarge = radius * 0.50;
        imageWidthLargest = radius * 0.70;
        imageHeightLargest = radius * 0.70;
        debugPrint('Tamaño de perla: ${radius*0.20} $imageWidthBasic');
        cuentasAdicionales = 5 * imageHeightBasic;
      }


      for (var i = 0; i < 55; i++) {
            // el cálculo comienza en el ángulo 0, que se encuentra a la derecha, y continúa en sentido horario.
            //como quiero que comience en la parte de abajo, le sumo 90 grados-> pi/2
            //para que vaya dibujando las perlas en sentido antihorario, le multiplico por -1 a la i
            //orientation cambia la ubicación de la medalla y de las cuentas que siguen en vertical hacia abajo según las dimensiones de la pantalla
            final double angle = orientation * (pi/2) + 2 * pi * (-i) / 55; 

            //para el brillo se puede usar siempre la misma imagen que se va cambiando de lugar 
            //imagen por defecto
            image = cuentas['perla']!;
            // se calcula el centro de la cuenta
            var cuentaCenter = Offset(
              center.dx + cos(angle) * radius, //posición en x
              center.dy + sin(angle) * radius, //posición en y
            );
            //destination Rectangle, da la ubicación y la escala de la imagen
            dstcuentas = Rect.fromCenter(
              center: cuentaCenter, 
              width: imageWidthBasic, 
              height: imageHeightBasic,
            );

            if ([11, 22, 33, 44].contains(i) ) {
              image = cuentas['rosa']!; 
              dstcuentas = Rect.fromCenter(
                center: cuentaCenter, 
                width: imageWidthLarge, 
                height: imageHeightLarge,
              );
            }

            if (i == 0) {
              image = cuentas['medalla']!;
              cuentaCenter = Offset(
                center.dx + cos(angle) * radius, //posición en x
                center.dy + (sin(angle) * radius) + imageHeightBasic * 0.8, //posición en y se traslada un poco hacia abajo
              );
              //se guarda la ubicación de la medalla para dibujar la extensión
              medallaCenter = cuentaCenter;
              debugPrint('Medalla Center: $medallaCenter');
              dstcuentas = Rect.fromCenter(
                center: cuentaCenter, 
                width: imageWidthLargest, 
                height: imageHeightLargest,
              );
            } 

              final paintImage = Paint();
              //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
              final srccuentas = Rect.fromLTWH(0,0,image.width.toDouble(), image.height.toDouble());  
              canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
          }
          //Se dibuja la extensión del rosario
          for (var j = 0; j < 6; j++) {
                image = cuentas['perla']!;
                if ([0].contains(j) ) {
                  image = cuentas['rosa']!; 
                  medallaCenter = Offset(
                    medallaCenter.dx - radius * 0.017, //posición en x
                    medallaCenter.dy + imageHeightLarge * 0.57, //posición en y
                  );
                  
                  dstcuentas = Rect.fromCenter(
                    center: medallaCenter, 
                    width: imageWidthLarge, 
                    height: imageHeightLarge,
                  );
                }

                if ([4].contains(j) ) {
                image = cuentas['rosa']!; 
                medallaCenter = Offset(
                  medallaCenter.dx, //posición en x
                  medallaCenter.dy + imageHeightBasic * 0.8, //posición en y
                );
                dstcuentas = Rect.fromCenter(
                  center: medallaCenter, 
                  width: imageWidthLarge, 
                  height: imageHeightLarge,
                );
                }

                if ([1,2,3].contains(j) ) {
                  image = cuentas['perla']!;
                  medallaCenter = Offset(
                    medallaCenter.dx, //posición en x
                    medallaCenter.dy + imageHeightBasic * 0.57, //posición en y
                  );
                  dstcuentas = Rect.fromCenter(
                    center: medallaCenter, 
                    width: imageWidthBasic, 
                    height: imageHeightBasic,
                  );
                }

               if ([5].contains(j) ) {
                image = cuentas['cruz']!; 
                medallaCenter = Offset(
                  medallaCenter.dx + radius * 0.017, //posición en x
                  medallaCenter.dy + imageHeightLarge * 0.64, //posición en y
                );
                dstcuentas = Rect.fromCenter(
                  center: medallaCenter, 
                  width: imageWidthLargest, 
                  height: imageHeightLargest,
                );
                }

              final paintImage = Paint();
              //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
              final srccuentas = Rect.fromLTWH(0,0,image.width.toDouble(), image.height.toDouble()); 
              canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
          }
        }
    
  
    @override
    bool shouldRepaint(covariant cuentasPainter oldDelegate) {
      return oldDelegate.cuentas != cuentas;
    }
}