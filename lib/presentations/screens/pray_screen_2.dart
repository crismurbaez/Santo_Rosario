import 'package:flutter/material.dart';
import 'dart:math';

class PrayScreen2 extends StatelessWidget {
  PrayScreen2({
    super.key,
    required this.mystery,
  }); 
      final String? mystery;
      final List<String> perlas = [
    'assets/images/medalla.png', //0 la más grande de todas y desplazada hacia abajo
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10
    'assets/images/rosa.png', //11 más grande
    'assets/images/perla.png', //1 
    'assets/images/perla.png', //2
    'assets/images/perla.png', //3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png', //9
    'assets/images/perla.png', //21 10
    'assets/images/rosa.png', //22 más grande
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10 32
    'assets/images/rosa.png', //33 más grande
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10 43
    'assets/images/rosa.png', //44 más grande
    'assets/images/perla.png', //1
    'assets/images/perla.png', //2
    'assets/images/perla.png', // 3
    'assets/images/perla.png', //4
    'assets/images/perla.png', //5
    'assets/images/perla.png', //6
    'assets/images/perla.png', //7
    'assets/images/perla.png', //8
    'assets/images/perla.png',  //9
    'assets/images/perla.png', //10 54
  ]; 

    final List<String> nuevasPerlas  = [
    'assets/images/rosa.png',  //0
    'assets/images/perla.png', //1 (más grande)
    'assets/images/perla.png',  //2
    'assets/images/perla.png', //3
    'assets/images/rosa.png', //4 (más grande)
    'assets/images/cruz.png',   //5 (la más grande)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 70.0,
        title: Column(
          children: [
            ListTile(
              title: Align(
                alignment: Alignment.center,
                child: Text(
                  'Santo Rosario',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              subtitle: Align(
                alignment: Alignment.center,
                child: Text(
                  'Misterios $mystery',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        )
      ),
      body:  Container(
         decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/VirgenLourdes.png'),
              fit: BoxFit.cover, 
            ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Usa el menor de los dos (ancho o alto) para asegurar que el círculo quepa
                  double size = min(constraints.maxWidth, constraints.maxHeight) * 0.6;
                  double radius = size / 2;
                  // NUEVO TAMAÑO PARA LAS PERLAS ADICIONALES
                  const double tamanoNuevaPerlaBase  = 35.0;
                  // NUEVO ESPACIO ENTRE LAS PERLAS ADICIONALES
                  final double espacioNuevasPerlas = tamanoNuevaPerlaBase  * 0.0000001;  //----------------------------------------
                  // NUEVO CALCULO DE LA ALTURA TOTAL DEL CONJUNTO
                  final double alturaTotal = radius +
                      (tamanoNuevaPerlaBase  * 0.5) +
                      (tamanoNuevaPerlaBase  + espacioNuevasPerlas) * nuevasPerlas.length - espacioNuevasPerlas + 50;


                  return SizedBox(
                    width: size,
                    height: alturaTotal,
                    child: CustomPaint(
                      painter: PerlasCircularesPainter(
                        perlas: perlas,
                        radius: radius,
                        // NUEVA LISTA DE PERLAS ADICIONALES PASADA AL PAINTER
                        nuevasPerlas: nuevasPerlas,
                        // NUEVO TAMAÑO DE PERLA ADICIONAL PASADO AL PAINTER
                        tamanoNuevaPerlaBase : tamanoNuevaPerlaBase ,
                        // NUEVO ESPACIO ENTRE PERLAS ADICIONALES PASADO AL PAINTER
                        espacioNuevasPerlas: espacioNuevasPerlas,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PerlasCircularesPainter extends CustomPainter {
  final List<String> perlas;
  final double radius;
  // NUEVA LISTA DE PERLAS ADICIONALES
  final List<String> nuevasPerlas;
  // NUEVO TAMAÑO DE PERLA ADICIONAL
  final double tamanoNuevaPerlaBase ;
  // NUEVO ESPACIO ENTRE PERLAS ADICIONALES
  final double espacioNuevasPerlas;

  PerlasCircularesPainter({
    required this.perlas, 
    required this.radius, 
    required this.nuevasPerlas, 
    required this.tamanoNuevaPerlaBase , 
    required this.espacioNuevasPerlas
    });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, radius);
    final numPerlas = perlas.length;
    const initialOffset = pi / 2; // Desplazamiento para empezar en la parte inferior del canvas
    // Define el tamaño estándar de las perlas
    const double standardPearlSize = 30.0;
    // Define un factor para hacer las perlas especificadas más grandes
    const double largePearlFactor = 2.7;
    // Define un factor para hacer la perla en el índice 0 la más grande
    const double largestPearlFactor = 5.0;
    
    // Dibujar las perlas circulares
    for (int i = 0; i < numPerlas; i++) {
      // Calcula el ángulo en sentido contrario a las agujas del reloj
      final angle = 2 * pi * (-i) / numPerlas + initialOffset; 
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      Offset pearlCenter = Offset(x, y); // Inicializamos el centro

      // Inicializa el tamaño de la perla actual con el tamaño estándar
      double currentPearlSize = standardPearlSize;

      // Verifica si el índice actual es 0, y si lo es, establece un tamaño mayor
      if (i == 0) {
        currentPearlSize = standardPearlSize * largestPearlFactor;
        // Desplaza la perla 0 hacia abajo en un quinto de su tamaño
        pearlCenter = pearlCenter.translate(0, currentPearlSize / 5);
      }
      // Verifica si el índice actual está en la lista de perlas que deben ser más grandes
      else if ([11, 22, 33, 44].contains(i)) {
        currentPearlSize = standardPearlSize * largePearlFactor;
      }
      // Si el índice no coincide con los casos anteriores, se mantiene el tamaño estándar
      final pearlRect = Rect.fromCenter(
        center: pearlCenter,
        width: currentPearlSize,
        height: currentPearlSize,
      );

      // Dibuja el círculo de fondo de la perla
      final circlePaint = Paint()..color = Color.fromRGBO(252, 183, 143, 0.0);
      canvas.drawCircle(pearlCenter, currentPearlSize  / 2, circlePaint);

      // Carga y dibuja la imagen de la perla
      final image = AssetImage(perlas[i]);
      image.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          final paintImage = Paint();
          final src = Rect.fromLTWH(
            0,
            0,
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          canvas.drawImageRect(info.image, src, pearlRect, paintImage);
        }),
      );
    }
  

    // NUEVO: DIBUJAR LAS PERLAS ADICIONALES DEBAJO DE LA PERLA 0
    final Offset centroPerlaCero = Offset(
      center.dx + radius * cos(initialOffset), // Posición X de la perla 0
      center.dy + radius * sin(initialOffset), // Posición Y de la perla 0
    );

    const double desplazarejex = 5.0; //----------------------------------------

    Offset currentNuevaPerlaCenter = Offset(
      centroPerlaCero.dx - desplazarejex,  //----------------------------------------
      centroPerlaCero.dy + (largestPearlFactor * standardPearlSize / 2) + (tamanoNuevaPerlaBase  / 2), // Debajo de la perla 0
    );

      // FACTORES DE ESCALA PARA LAS PERLAS ADICIONALES  
      const double nuevaPerlaGrandeFactor = 2.7;  //----------------------------------------
      const double nuevaPerlaMasGrandeFactor = 4.0; //----------------------------------------

      for (int i = 0; i < nuevasPerlas.length; i++) {
        double tamanoActualNuevaPerla = tamanoNuevaPerlaBase;
        // APLICANDO TAMAÑOS ESPECIALES A LAS PERLAS ADICIONALES
        if (i == 0 || i == 4) {
          tamanoActualNuevaPerla = tamanoNuevaPerlaBase * nuevaPerlaGrandeFactor;  
        } else if (i == 5) {
          tamanoActualNuevaPerla = tamanoNuevaPerlaBase * nuevaPerlaMasGrandeFactor;  
          //TRASLADAR LA PERLA 5 (ÍNDICE 5) HACIA ABAJO LA MITAD DE SU TAMAÑO
          currentNuevaPerlaCenter = currentNuevaPerlaCenter.translate(desplazarejex, tamanoActualNuevaPerla / 3);
        }

        final pearlRectAdicional = Rect.fromCenter(
          center: currentNuevaPerlaCenter,
          width: tamanoActualNuevaPerla ,
          height: tamanoActualNuevaPerla ,
      );

      final circlePaintAdicional = Paint()..color = const Color.fromRGBO(252, 183, 143, 0.3);
      canvas.drawCircle(currentNuevaPerlaCenter, tamanoNuevaPerlaBase  / 2, circlePaintAdicional);

      final imageAdicional = AssetImage(nuevasPerlas[i]);
      imageAdicional.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          final paintImage = Paint();
          final src = Rect.fromLTWH(
            0,
            0,
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          canvas.drawImageRect(info.image, src, pearlRectAdicional, paintImage);
        }),
      );

      // Mueve el centro para la siguiente perla adicional
      currentNuevaPerlaCenter = currentNuevaPerlaCenter.translate(0, tamanoNuevaPerlaBase - 10); //----------------------------------------
    }
  }

  @override
  bool shouldRepaint(covariant PerlasCircularesPainter oldDelegate) {
    return oldDelegate.perlas != perlas ||
        oldDelegate.radius != radius ||
        // NUEVA COMPARACIÓN PARA LA LISTA DE PERLAS ADICIONALES
        oldDelegate.nuevasPerlas != nuevasPerlas ||
        // NUEVA COMPARACIÓN PARA EL TAMAÑO DE PERLA ADICIONAL
        oldDelegate.tamanoNuevaPerlaBase  != tamanoNuevaPerlaBase  ||
        // NUEVA COMPARACIÓN PARA EL ESPACIO ENTRE PERLAS ADICIONALES
        oldDelegate.espacioNuevasPerlas != espacioNuevasPerlas;
  }
}