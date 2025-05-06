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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Usa el menor de los dos (ancho o alto) para asegurar que el círculo quepa
              double size = min(constraints.maxWidth, constraints.maxHeight) * 0.78;
              double radius = size / 2;

              return SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: PerlasCircularesPainter(
                    perlas: perlas,
                    radius: radius,
                  ),
                ),
              );
            },
          ),
      ),
      ),
    );
  }
}

class PerlasCircularesPainter extends CustomPainter {
  final List<String> perlas;
  final double radius;

  PerlasCircularesPainter({required this.perlas, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final numPerlas = perlas.length;
    const initialOffset = pi / 2; // Desplazamiento para empezar en la parte inferior del canvas

    
    // Define el tamaño estándar de las perlas
    const double standardPearlSize = 30.0;
    // Define un factor para hacer las perlas especificadas más grandes
    const double largePearlFactor = 2.7;
    // Define un factor para hacer la perla en el índice 0 la más grande
    const double largestPearlFactor = 5.0;
    
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
      canvas.drawCircle(pearlCenter, currentPearlSize  / 4, circlePaint);

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
  }

  @override
  bool shouldRepaint(covariant PerlasCircularesPainter oldDelegate) {
    return oldDelegate.perlas != perlas || oldDelegate.radius != radius;
  }
}