import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/models/data.dart'; 

class PrayScreen2 extends StatelessWidget {
  const PrayScreen2({
    super.key,
    required this.mystery,
  }); 
      final String? mystery;


  @override
  Widget build(BuildContext context) {

    const Color backgroundColor = Color(0xFF1D404C);

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
      body:  Stack(
        children: <Widget>[
          Container(
              color: backgroundColor,
          ),
          Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/VirgenLourdes.png'),
                          fit: BoxFit.fitHeight,
                        ),
                      ),
          ),
          Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        const double tamanoNuevaPerlaBase = 25.0;
                        const double espacioNuevasPerlas = tamanoNuevaPerlaBase * 0.8;
                        final int numNuevasPerlas = nuevasPerlas.length;
                        final double alturaPerlasAdicionales = (tamanoNuevaPerlaBase + espacioNuevasPerlas) * numNuevasPerlas - espacioNuevasPerlas + (tamanoNuevaPerlaBase * 0.5);
                        const double factorEspacioVertical = 0.7;
                        const double factorEspacioHorizontal = 0.8;
            
                        final double anchoMaximoConjunto = constraints.maxWidth * factorEspacioHorizontal;
                        final double alturaMaximaConjunto = screenHeight * factorEspacioVertical;
            
                        // CALCULA EL RADIO MÁXIMO BASADO EN EL ANCHO
                        final double radioMaximoAncho = anchoMaximoConjunto / 2;
            
                        // CALCULA EL RADIO MÁXIMO BASADO EN LA ALTURA DISPONIBLE PARA EL CÍRCULO
                        final double radioMaximoAltoCirculo = (alturaMaximaConjunto - alturaPerlasAdicionales - (tamanoNuevaPerlaBase * 0.5)) / 2;
            
                        // SELECCIONA EL RADIO QUE PERMITA QUE EL CÍRCULO Y LAS PERLAS ADICIONALES QUEPAN
                        final double radius = min(radioMaximoAncho, max(0, radioMaximoAltoCirculo));
                        final double size = radius * 2;
            
                        // CALCULA LA ALTURA TOTAL DEL CONJUNTO CON EL RADIO AJUSTADO
                        final double alturaTotalConRadio = radius + alturaPerlasAdicionales + (tamanoNuevaPerlaBase * 0.5) + radius; // Radio arriba + adicionales + espacio + radio abajo
            
                      return SizedBox(
                        width: size,
                        height: alturaTotalConRadio,
                        child: CustomPaint(
                          painter: PerlasCircularesPainter(
                            perlas: perlas,
                            radius: radius,
                            nuevasPerlas: nuevasPerlas,
                            tamanoNuevaPerlaBase : tamanoNuevaPerlaBase ,
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
        ]
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
    const double standardPearlSize = 25.0;
    // Define un factor para hacer las perlas especificadas más grandes
    const double largePearlFactor = 2.5;
    // Define un factor para hacer la perla en el índice 0 la más grande
    const double largestPearlFactor = 4.0;
    
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
      final circlePaint = Paint()..color = const Color.fromRGBO(252, 183, 143, 0.0);
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

    const double desplazarejex = 0.0; //----------------------------------------

    Offset currentNuevaPerlaCenter = Offset(
      centroPerlaCero.dx - desplazarejex,  //----------------------------------------
      centroPerlaCero.dy + ((largestPearlFactor * standardPearlSize)/2) + (tamanoNuevaPerlaBase/1.5), // Debajo de la perla 0
    );

      // FACTORES DE ESCALA PARA LAS PERLAS ADICIONALES  
      const double nuevaPerlaGrandeFactor = 2.5;  //----------------------------------------
      const double nuevaPerlaMasGrandeFactor = 4.0; //----------------------------------------

      for (int i = 0; i < nuevasPerlas.length; i++) {
        double tamanoActualNuevaPerla = tamanoNuevaPerlaBase;
        // APLICANDO TAMAÑOS ESPECIALES A LAS PERLAS ADICIONALES
        if (i == 0 || i == 4) {
          tamanoActualNuevaPerla = tamanoNuevaPerlaBase * nuevaPerlaGrandeFactor; 
          //TRASLADAR LAS PERLAS HACIA ABAJO 
          currentNuevaPerlaCenter = currentNuevaPerlaCenter.translate(desplazarejex, tamanoActualNuevaPerla/9); 
        } else if (i == 5) {
          tamanoActualNuevaPerla = tamanoNuevaPerlaBase * nuevaPerlaMasGrandeFactor;  
          //TRASLADAR LA PERLA 5 HACIA ABAJO 
          currentNuevaPerlaCenter = currentNuevaPerlaCenter.translate( desplazarejex + 3 , tamanoActualNuevaPerla / 3);
        }

        final pearlRectAdicional = Rect.fromCenter(
          center: currentNuevaPerlaCenter,
          width: tamanoActualNuevaPerla ,
          height: tamanoActualNuevaPerla ,
      );

      final circlePaintAdicional = Paint()..color = const Color.fromRGBO(252, 183, 143, 0.0);
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
      currentNuevaPerlaCenter = currentNuevaPerlaCenter.translate(0, tamanoNuevaPerlaBase - tamanoNuevaPerlaBase/4); //----------------------------------------
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