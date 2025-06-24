import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/data.dart';

class PrayScreen1 extends StatefulWidget {
  const PrayScreen1({
    super.key,
    required this.mystery,
  });
  final String? mystery;
  @override
  State<PrayScreen1> createState() => _PrayScreenState1();
}

class _PrayScreenState1 extends State<PrayScreen1> {
  Map<String, ui.Image>? _loadedImages;

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    final Map<String, ui.Image> images = {};
    for (var entry in Data.cuentas.entries) {
      final String key = entry.key;
      final String assetPath = entry.value;

      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      images[key] = frameInfo.image;
    }

    setState(() {
      _loadedImages = images;
    });
  }

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
                      'Misterios ${widget.mystery}',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )),
        body: Stack(children: <Widget>[
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
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              if (_loadedImages == null) {
                return const CircularProgressIndicator(
                  color: Colors.amber,
                );
              }

              final double width = 0.9 * constraints.maxWidth;
              final double height = 0.69 * constraints.maxHeight;

              return SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                    painter: cuentasPainter(
                  cuentas: _loadedImages!,
                )),
              );
            }),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Credo'),
                ),
              ),
            ),
          ),
        ]));
  }
}

class cuentasPainter extends CustomPainter {
  final Map<String, ui.Image> cuentas;

  cuentasPainter({
    required this.cuentas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, (size.height / 2));
    double radius;
    double imageWidthBasic;
    double imageHeightBasic;
    double imageWidthLarge;
    double imageHeightLarge;
    double imageWidthLargest;
    double imageHeightLargest;
    double cuentasAdicionales = 5 * 30;
    int orientation;
    Offset? medallaCenter; // Se inicializa como nullable

    // Calcular dimensiones y orientación
    if (size.width < size.height) {
      cuentasAdicionales = size.height * 0.34;
      radius = min((size.width / 2), ((size.height - cuentasAdicionales) / 2));
      imageWidthBasic = radius * 0.20;
      imageHeightBasic = radius * 0.20;
      imageWidthLarge = radius * 0.60;
      imageHeightLarge = radius * 0.60;
      imageWidthLargest = radius * 0.90;
      imageHeightLargest = radius * 0.90;
      cuentasAdicionales = 5 * imageHeightBasic;
      center = Offset(center.dx, center.dy - cuentasAdicionales);
      orientation = 1;
    } else {
      orientation = -1;
      radius = min((size.width / 2), ((size.height) / 2));
      imageWidthBasic = radius * 0.20;
      imageHeightBasic = radius * 0.20;
      imageWidthLarge = radius * 0.50;
      imageHeightLarge = radius * 0.50;
      imageWidthLargest = radius * 0.70;
      imageHeightLargest = radius * 0.70;
      cuentasAdicionales = 5 * imageHeightBasic;
    }

    // Dibujar las cuentas del rosario principal
    for (var i = 0; i < 55; i++) {
      final Offset currentBeadCenter = _drawMainRosary(
        canvas,
        size,
        center,
        radius,
        orientation,
        i,
        imageHeightBasic,
        imageWidthLarge,
        imageHeightLarge,
        imageWidthLargest,
        imageHeightLargest,
        imageWidthLargest,
      );
           // Si es la primera cuenta (la medalla), guardamos su centro
      if (i == 0) {
        medallaCenter = currentBeadCenter;
      }
    }

    // Dibujar la extensión del rosario
    final Offset brilloCenter = _drawRosaryExtension(
      canvas,
      medallaCenter!,
      imageWidthBasic,
      imageHeightBasic,
      imageWidthLarge,
      imageHeightLarge,
      imageWidthLargest,
      imageHeightLargest,
      radius,
    );

    // Dibujar el brillo en la medalla
    _drawMedalGlow(
      canvas,
      brilloCenter,
      imageWidthLargest,
      imageHeightLargest,
    );
  }

  /// Dibuja el círculo principal del rosario (las 55 cuentas y 5 "rosas").
  Offset _drawMainRosary(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    int orientation,
    int i,
    double imageWidthBasic,
    double imageHeightBasic,
    double imageWidthLarge,
    double imageHeightLarge,
    double imageWidthLargest,
    double imageHeightLargest,
  ) {
    ui.Image image;
    late Rect dstcuentas;
    // Offset medallaCenter = center; // Se inicializa con el centro

    // for (var i = 0; i < 55; i++) {
      final double angle = orientation * (pi / 2) + 2 * pi * (-i) / 55;

      image = cuentas['perla']!;
      var cuentaCenter = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      dstcuentas = Rect.fromCenter(
        center: cuentaCenter,
        width: imageWidthBasic,
        height: imageHeightBasic,
      );

      if ([11, 22, 33, 44].contains(i)) {
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
          center.dx + cos(angle) * radius,
          center.dy + (sin(angle) * radius) + imageHeightBasic * 0.8,
        );
        // medallaCenter = cuentaCenter;
        dstcuentas = Rect.fromCenter(
          center: cuentaCenter,
          width: imageWidthLargest,
          height: imageHeightLargest,
        );
      }

      final paintImage = Paint();
      final srccuentas =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
    // }
    return cuentaCenter; // Retorna el centro de la cuenta dibujada
  }

  /// Dibuja la extensión del rosario (las cuentas que cuelgan de la medalla).
  Offset _drawRosaryExtension(
    Canvas canvas,
    Offset medallaCenter,
    double imageWidthBasic,
    double imageHeightBasic,
    double imageWidthLarge,
    double imageHeightLarge,
    double imageWidthLargest,
    double imageHeightLargest,
    double radius,
  ) {
    ui.Image image;
    late Rect dstcuentas;
    Offset currentMedallaCenter = medallaCenter;
    Offset brilloCenter = medallaCenter; // Se usará para el brillo

    for (var j = 0; j < 6; j++) {
      image = cuentas['perla']!;

      if ([0].contains(j)) {
        brilloCenter = currentMedallaCenter; // Guarda la posición de la primera cuenta de la extensión (rosa)
        image = cuentas['rosa']!;
        currentMedallaCenter = Offset(
          currentMedallaCenter.dx - radius * 0.017,
          currentMedallaCenter.dy + imageHeightLarge * 0.57,
        );
        dstcuentas = Rect.fromCenter(
          center: currentMedallaCenter,
          width: imageWidthLarge,
          height: imageHeightLarge,
        );
      } else if ([4].contains(j)) {
        image = cuentas['rosa']!;
        currentMedallaCenter = Offset(
          currentMedallaCenter.dx,
          currentMedallaCenter.dy + imageHeightBasic * 0.8,
        );
        dstcuentas = Rect.fromCenter(
          center: currentMedallaCenter,
          width: imageWidthLarge,
          height: imageHeightLarge,
        );
      } else if ([1, 2, 3].contains(j)) {
        image = cuentas['perla']!;
        currentMedallaCenter = Offset(
          currentMedallaCenter.dx,
          currentMedallaCenter.dy + imageHeightBasic * 0.57,
        );
        dstcuentas = Rect.fromCenter(
          center: currentMedallaCenter,
          width: imageWidthBasic,
          height: imageHeightBasic,
        );
      } else if ([5].contains(j)) {
        image = cuentas['cruz']!;
        currentMedallaCenter = Offset(
          currentMedallaCenter.dx + radius * 0.017,
          currentMedallaCenter.dy + imageHeightLarge * 0.64,
        );
        dstcuentas = Rect.fromCenter(
          center: currentMedallaCenter,
          width: imageWidthLargest,
          height: imageHeightLargest,
        );
      }

      final paintImage = Paint();
      final srccuentas =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
    }
    return brilloCenter;
  }

  /// Dibuja el brillo sobre la medalla.
  void _drawMedalGlow(
    Canvas canvas,
    Offset brilloCenter,
    double imageWidthLargest,
    double imageHeightLargest,
  ) {
    ui.Image image = cuentas['brillo']!;
    final Rect dstcuentas = Rect.fromCenter(
      center: brilloCenter,
      width: imageWidthLargest * 0.3,
      height: imageHeightLargest * 0.5,
    );
    final paintImage = Paint();
    paintImage.colorFilter = const ColorFilter.mode(
      Color.fromRGBO(255, 255, 255, 0.4),
      BlendMode.modulate,
    );
    final srccuentas =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
  }

  @override
  bool shouldRepaint(covariant cuentasPainter oldDelegate) {
    return oldDelegate.cuentas != cuentas;
  }
}