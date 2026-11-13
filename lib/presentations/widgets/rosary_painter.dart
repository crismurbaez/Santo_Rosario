import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:santo_rosario/constants/app_constants.dart';
import '../../data/models/data.dart';

class CuentasPainter extends CustomPainter {
  final Map<String, ui.Image> cuentas;
  final int counter;
  final int rosaryBeadCount;
  final int rosaryCircleBeadCount;
  final Function(List<String> prayers, int orderMystery)
  onCuentaHighlighted; //pasa el conjunto de oraciones de la cuenta resaltada
  final int orderPrayer; // <-- Añadido para el orden de oración
  final Function(String message)
  onDrawingError; // Callback para manejar errores de dibujo
  final bool showDebugGuides; // 👈 Guías visuales de diagnóstico

  CuentasPainter({
    required this.cuentas,
    required this.counter,
    required this.rosaryBeadCount,
    required this.rosaryCircleBeadCount,
    required this.onCuentaHighlighted,
    required this.orderPrayer,
    required this.onDrawingError,
    this.showDebugGuides = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    //se calcula el centro del canvas
    Offset center = Offset(size.width / 2, (size.height / 2));
    double radius;
    //tener en cuenta el tamaño de pantalla s8 que es el que mejor se dapta al tamaño actual de las imágenes
    double imageWidthBasic;
    double imageHeightBasic;
    double imageWidthMedium;
    double imageHeightMedium;
    double imageWidthLarge;
    double imageHeightLarge;
    double imageWidthLargest;
    double imageHeightLargest;
    double cuentasAdicionales;
    int orientation;
    int location;
    ui.Image image;
    late Rect dstcuentas;
    // se inicializa con este valor, pero luego se cambia
    //se usa para dibujar la extensión del rosario
    Offset medallaCenter = center;
    // Offset brilloCenter = center;

    String cuentaName;
    String cuentaWidth;

    double imageWidth = 1;
    double imageHeight = 1;

    int counter = this.counter;
    // int orderPrayer = this.orderPrayer;

    //teniendo en cuenta la orientación de la pantalla, se determina si la extensión se dibuja debajo o dentro del rosario
    //si se dibuja debajo, se le resta la parte vertical del rosario para que no se salga de la pantalla
    // si el ancho es menor que el alto se hace la resta y se cambia la ubicación y la orientación .

    // obtiene el menor radio entre el ancho y el alto de la pantalla,
    if (size.width < size.height) {
      // Factores geométricos del conjunto completo (aro + extensión):
      // - Distancia hacia arriba (centro -> borde superior del aro): 1.10 * radius
      // - Distancia hacia abajo (centro -> base inferior de la cruz): 2.942 * radius
      const double topSpanFactor = 1.10;
      const double bottomSpanFactor = 2.942;
      const double totalVerticalFactor =
          topSpanFactor + bottomSpanFactor; // 4.042

      // 1. En horizontal se tiene en cuenta el círculo solamente (con margen para cuentas laterales):
      final double maxRadiusByWidth = (size.width / 2) * 0.88;
      // 2. En vertical se considera el conjunto completo (círculo + extensión):
      final double maxRadiusByHeight =
          (size.height - 16.0) / totalVerticalFactor;
      radius = maxRadiusByWidth < maxRadiusByHeight
          ? maxRadiusByWidth
          : maxRadiusByHeight;

      imageWidthBasic = radius * 0.20;
      imageHeightBasic = radius * 0.20;
      imageWidthMedium = radius * 0.21;
      imageHeightMedium = radius * 0.21;
      imageWidthLarge = radius * 0.50;
      imageHeightLarge = radius * 0.50;
      imageWidthLargest = radius * 0.80;
      imageHeightLargest = radius * 0.80;

      // Centrado vertical de todo el conjunto (círculo + extensión):
      center = Offset(
        size.width / 2,
        size.height / 2 - ((bottomSpanFactor - topSpanFactor) / 2) * radius,
      );

      //la extensión se dibuja debajo del rosario
      location = 1;
      //se dibuja en sentido anti horario
      orientation = -1;
    } else {
      // la extensión se dibuja dentro del rosario
      location = -1;
      //se dibuja en sentido horario
      orientation = 1;

      // El aro completo con sus perlas mide 2.20 * radius (1.10 hacia arriba y 1.10 hacia abajo).
      // Dividiendo por 2.20, el borde superior de las cuentas toca exactamente Y = 0 (bajo el AppBar) sin esconderse:
      radius = (min(size.width, size.height)) / 2.20;
      imageWidthBasic = radius * 0.20;
      imageHeightBasic = radius * 0.20;
      imageWidthMedium = radius * 0.21;
      imageHeightMedium = radius * 0.21;
      imageWidthLarge = radius * 0.50;
      imageHeightLarge = radius * 0.50;
      imageWidthLargest = radius * 0.70;
      imageHeightLargest = radius * 0.70;
      cuentasAdicionales = 5 * imageHeightBasic;
    }

    int i = 0;
    //Se dibujan las cuentas del rosario
    List<dynamic> rosaryElementsCircle = Data.rosaryDetailsCircle.expand((
      detail,
    ) {
      List<Map<String, dynamic>> currentDetailElements = [];

      for (int j = 0; j < detail.count; j++) {
        double angle =
            location * (pi / 2) +
            2 * pi * i * orientation / rosaryCircleBeadCount;

        String currentCuentaName = detail.cuenta;
        image = cuentas[currentCuentaName]!;
        // se calcula el centro de la cuenta
        var cuentaCenter = Offset(
          center.dx + cos(angle) * radius, //posición en x
          center.dy + sin(angle) * radius, //posición en y
        );
        //destination Rectangle, da la ubicación y la escala de la imagen
        if (detail.width == AppRosarySizes.basic) {
          imageWidth = imageWidthBasic;
          imageHeight = imageHeightBasic;
        }
        if (detail.width == AppRosarySizes.medium) {
          imageWidth = imageWidthMedium;
          imageHeight = imageHeightMedium;
        }
        if (detail.width == AppRosarySizes.large) {
          imageWidth = imageWidthLarge;
          imageHeight = imageHeightLarge;
        }
        if (detail.width == AppRosarySizes.largest) {
          imageWidth = imageWidthLargest;
          imageHeight = imageHeightLargest;
        }
        if (currentCuentaName == AppRosaryAccounts.medalla) {
          //TODOhacer más universal, cómo marcar como inicio****************
          cuentaCenter = Offset(
            center.dx + cos(angle) * radius, //posición en x
            center.dy +
                (sin(angle) * radius) +
                imageHeightBasic, //posición en y se traslada un poco hacia abajo
          );
          //se guarda la ubicación de la medalla para dibujar la extensión
          medallaCenter = cuentaCenter;
        }
        dstcuentas = Rect.fromCenter(
          center: cuentaCenter,
          width: imageWidth,
          height: imageHeight,
        );
        final paintImage = Paint();
        //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
        final srccuentas = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        try {
          canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
        } catch (e) {
          onDrawingError(
            '❌ Error al dibujar la imagen: $currentCuentaName - Error: $e',
          );
        }

        currentDetailElements.add({
          AppRosaryMapKeys.cuenta: currentCuentaName,
          AppRosaryMapKeys.angle: angle,
          AppRosaryMapKeys.width: detail.width,
          AppRosaryMapKeys.height: detail.height,
          AppRosaryMapKeys.dstcuentas: dstcuentas,
          AppRosaryMapKeys.cuentaCenter: cuentaCenter,
          AppRosaryMapKeys.prayers:
              detail.prayers, // Agrega las oraciones de la cuenta
          AppRosaryMapKeys.order: detail.order, // Agrega el orden de la cuenta
        });

        i++; // Incremento de i para calcular el ángulo de la siguiente cuenta
      }
      return currentDetailElements;
    }).toList();

    //desplazamiento inicial de la extensión a partir de la ubicación de la medalla
    Offset cuentaCenter = Offset(
      medallaCenter.dx, //posición en x
      medallaCenter.dy + imageWidthBasic * 1.16, //posición en y
    );

    List<dynamic> rosaryElementsExtension = Data.rosaryDetailsExtension.expand((
      detail,
    ) {
      List<Map<String, dynamic>> currentDetailElements = [];

      for (int j = 0; j < detail.count; j++) {
        String currentCuentaName = detail.cuenta;
        image = cuentas[currentCuentaName]!;
        //destination Rectangle, da la ubicación y la escala de la imagen
        if (detail.width == AppRosarySizes.basic) {
          imageWidth = imageWidthBasic;
          imageHeight = imageHeightBasic;
          // se calcula el centro de la cuenta
          cuentaCenter = Offset(
            cuentaCenter.dx, //posición en x
            cuentaCenter.dy + imageHeight * 0.60, //posición en y
          );
        }
        if (detail.width == AppRosarySizes.medium) {
          imageWidth = imageWidthMedium;
          imageHeight = imageHeightMedium;
          cuentaCenter = Offset(
            cuentaCenter.dx, //posición en x
            cuentaCenter.dy + imageHeight * 0.70, //posición en y
          );
        }
        if (detail.width == AppRosarySizes.large) {
          imageWidth = imageWidthLarge;
          imageHeight = imageHeightLarge;
          cuentaCenter = Offset(
            cuentaCenter.dx, //posición en x
            cuentaCenter.dy + imageHeight * 0.40, //posición en y
          );
        }
        if (detail.width == AppRosarySizes.largest) {
          imageWidth = imageWidthLargest;
          imageHeight = imageHeightLargest;
          cuentaCenter = Offset(
            cuentaCenter.dx, //posición en x
            cuentaCenter.dy + imageHeight * 0.57, //posición en y
          );
        }

        dstcuentas = Rect.fromCenter(
          center: cuentaCenter,
          width: imageWidth,
          height: imageHeight,
        );
        final paintImage = Paint();
        //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
        final srccuentas = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        try {
          canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
        } catch (e) {
          onDrawingError(
            '❌ Error al dibujar la imagen: $currentCuentaName - Error: $e',
          );
        }

        currentDetailElements.add({
          AppRosaryMapKeys.cuenta: currentCuentaName,
          AppRosaryMapKeys.width: detail.width,
          AppRosaryMapKeys.height: detail.height,
          AppRosaryMapKeys.dstcuentas: dstcuentas,
          AppRosaryMapKeys.cuentaCenter: cuentaCenter,
          AppRosaryMapKeys.prayers:
              detail.prayers, // Agrega las oraciones de la cuenta
          AppRosaryMapKeys.order: detail.order, // Agrega el orden de la cuenta
        });
      }
      return currentDetailElements;
    }).toList();

    final List<dynamic> allRosaryElements =
        rosaryElementsCircle + rosaryElementsExtension;

    // Se dibuja el brillo
    if (allRosaryElements.isNotEmpty) {
      var element = allRosaryElements[counter];
      cuentaName = element[AppRosaryMapKeys.cuenta];
      // Verificamos que 'prayers' exista y sea una List<String> antes de castear y llamar.
      if (element[AppRosaryMapKeys.prayers] != null) {
        onCuentaHighlighted(
          element[AppRosaryMapKeys.prayers] as List<String>,
          element[AppRosaryMapKeys.order] as int,
        ); // Pasa las oraciones y el orden de la cuenta resaltada
      } else {
        // En caso de que, por alguna razón, no tenga la clave o el tipo correcto (poco probable ahora)
        onCuentaHighlighted(
          [],
          0,
        ); // Pasa una lista vacía y un cero para evitar errores
      }

      cuentaWidth = element[AppRosaryMapKeys.width];
      dstcuentas = element[AppRosaryMapKeys.dstcuentas];
      var cuentaCenter = element[AppRosaryMapKeys.cuentaCenter];

      //se dibuja la cuenta brillo
      image = cuentas[AppRosaryAccounts.brillo]!;

      if (cuentaWidth == AppRosarySizes.basic) {
        imageWidth = imageWidthBasic * 0.7;
        imageHeight = imageHeightBasic * 0.7;
      }
      if (cuentaWidth == AppRosarySizes.medium) {
        imageWidth = imageWidthMedium * 1.1;
        imageHeight = imageHeightMedium * 1.1;
      }
      if (cuentaWidth == AppRosarySizes.large) {
        imageWidth = imageWidthLarge * 0.8;
        imageHeight = imageHeightLarge * 1.2;
      }
      if (cuentaWidth == AppRosarySizes.largest) {
        imageWidth = imageWidthLargest * 0.3;
        imageHeight = imageHeightLargest * 0.7;
      }
      //destination Rectangle, da la ubicación y la escala de la imagen
      dstcuentas = Rect.fromCenter(
        center: cuentaCenter,
        width: imageWidth,
        height: imageHeight,
      );

      final paintImage = Paint();
      paintImage.colorFilter = const ColorFilter.mode(
        Color.fromRGBO(255, 255, 255, 0.7),
        BlendMode.modulate, // Multiplica los valores de color y alfa
      );
      if (cuentaName == AppRosaryAccounts.cruz) {
        paintImage.colorFilter = const ColorFilter.mode(
          Color.fromRGBO(255, 255, 255, 0.3),
          BlendMode.modulate, // Multiplica los valores de color y alfa
        );
      }
      //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
      final srccuentas = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      try {
        canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
      } catch (e) {
        onDrawingError('❌ Error al dibujar la imagen: $cuentaName - Error: $e');
      }
    }

    if (showDebugGuides) {
      // =======================================================
      // 📐 CUADROS DE DIAGNÓSTICO VISUAL PROVISORIOS PARA ANÁLISIS
      // =======================================================
      final paintDebugCyan = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final paintDebugYellow = Paint()
        ..color = const Color(0xFFFFD600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final paintDebugMagenta = Paint()
        ..color = const Color(0xFFFF4081)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final paintDebugCenterLine = Paint()
        ..color = const Color(0x99FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 1. Cuadro CIAN: Área total del lienzo disponible recibido
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        paintDebugCyan,
      );

      // Eje central de la pantalla / lienzo (mitad vertical)
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paintDebugCenterLine,
      );

      // 2. Círculo y caja AMARILLA: El aro del rosario
      canvas.drawCircle(center, radius, paintDebugYellow);
      canvas.drawRect(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
        paintDebugYellow,
      );

      // 3. Cuadro MAGENTA: Conjunto completo
      if (size.width < size.height) {
        // En vertical: Aro + Extensión / Cruz
        const double topSpanFactor = 1.10;
        const double bottomSpanFactor = 2.942;
        final double conjuntoTop = center.dy - radius * topSpanFactor;
        final double conjuntoBottom = center.dy + radius * bottomSpanFactor;
        canvas.drawRect(
          Rect.fromLTRB(
            center.dx - radius * topSpanFactor,
            conjuntoTop,
            center.dx + radius * topSpanFactor,
            conjuntoBottom,
          ),
          paintDebugMagenta,
        );
      } else {
        // En horizontal: Delimita el aro completo con el grosor de perlas (1.10 * radius)
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: radius * 2.20,
            height: radius * 2.20,
          ),
          paintDebugMagenta,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CuentasPainter oldDelegate) {
    return oldDelegate.cuentas != cuentas ||
        oldDelegate.counter != counter ||
        oldDelegate.rosaryBeadCount != rosaryBeadCount ||
        oldDelegate.rosaryCircleBeadCount != rosaryCircleBeadCount ||
        oldDelegate.orderPrayer != orderPrayer ||
        oldDelegate.showDebugGuides != showDebugGuides;
  }
}
