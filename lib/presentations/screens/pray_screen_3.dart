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
  int _counter = 0;

    @override
  void initState() {
    super.initState();
    _loadAllImages(); // Inicia la carga de todas las imágenes
  }

      void _incrementCounter() {
      setState(() {
        if (_counter < Data.rosaryCircleBeadCount-1) {
          _counter++; // Incrementa el contador
        }
      });
    }

    void _decrementCounter() {
      setState(() {
        if (_counter > 0) {
          _counter--;  // Disminuye el contador
        }
      });
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
         title: 
             Column(
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
        ),
      ),
      body: Stack (
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
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) { 
                // Muestra un indicador de carga si las imágenes aún no se han cargado
                if (_loadedImages == null) {
                  return const CircularProgressIndicator(
                    color: Colors.amber, 
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
                    painter : CuentasPainter(
                      cuentas: _loadedImages!,
                      counter: _counter,
                      
                    )
                  ),
                );
            }),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        ),
                        onPressed: _decrementCounter,
                        child: const Text('Anterior'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        ),
                        onPressed: () {
                          Navigator.pop(context); 
                        },
                        child: const Text('Credo'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        ),
                        onPressed: _incrementCounter,
                        child: const Text('Siguiente'),
                      ),
                    ]
                  ),
                ),
            ),
        ]
      )
    );
  }
}

class CuentasPainter extends CustomPainter {
  final Map<String,  ui.Image> cuentas;
  final int counter;

  CuentasPainter({
    required this.cuentas,
    required this.counter,
  });

  @override
  void paint(Canvas canvas, Size size) {
      //se calcula el centro del canvas
      Offset center = Offset(size.width/2, (size.height/2));
      double radius;
      //tener en cuenta el tamaño de pantalla s8 que es el que mejor se dapta al tamaño actual de las imágenes
      double imageWidthBasic;
      double imageHeightBasic;
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
      Offset brilloCenter = center;
      int cuentasCount = 61; 
      int cuentasOrder = 0;

      String cuentaName;
      String cuentaPrayer;
      int cuentaCount;
      int cuentaOrder;
      String cuentaWidth;
      String cuentaHeight;

      double imageWidth=1;
      double imageHeight=1;

      int counter = this.counter;
      

      //teniendo en cuenta la orientación de la pantalla, se determina si la extensión se dibuja debajo o dentro del rosario
      //si se dibuja debajo, se le resta la parte vertical del rosario para que no se salga de la pantalla
      // si el ancho es menor que el alto se hace la resta y se cambia la ubicación y la orientación .

      // obtiene el menor radio entre el ancho y el alto de la pantalla,
      if (size.width<size.height) {
        //se desplaza el centro hacia arriba para que entre la extensión y no salga de la pantalla
        cuentasAdicionales = size.height * 0.34;
        radius = min((size.width / 2),((size.height - cuentasAdicionales) / 2)); 
        imageWidthBasic = radius * 0.20;
        imageHeightBasic = radius * 0.20;
        imageWidthLarge = radius * 0.60;
        imageHeightLarge = radius * 0.60;
        imageWidthLargest = radius * 0.90;
        imageHeightLargest = radius * 0.90;
        cuentasAdicionales = 5 * imageHeightBasic;
        center = Offset(center.dx, center.dy - cuentasAdicionales);
        //la extensión se dibuja debajo del rosario
        location = 1; 
        //se dibuja en sentido anti horario
        orientation = -1;
        

      } else {
        // la extensión se dibuja dentro del rosario
        location = -1; 
        //se dibuja en sentido horario
        orientation = 1;

        radius = min((size.width / 2),((size.height) / 2)); 
        imageWidthBasic = radius * 0.20;
        imageHeightBasic = radius * 0.20;
        imageWidthLarge = radius * 0.50;
        imageHeightLarge = radius * 0.50;
        imageWidthLargest = radius * 0.70;
        imageHeightLargest = radius * 0.70;
        cuentasAdicionales = 5 * imageHeightBasic;
      }

       int i = 0;
       //Se dibujan las cuentas del rosario
       List<dynamic> rosaryElements = Data.rosaryDetailsCircle.expand((detail) {
        // Create a local list to hold the elements generated for *this* 'detail'
        List<Map<String, dynamic>> currentDetailElements = [];

        for (int j = 0; j < detail.count; j++) {
          double angle = location * (pi / 2) + 2 * pi * i * orientation / Data.rosaryCircleBeadCount;

          String currentCuentaName = detail.cuenta; 
            image = cuentas[currentCuentaName]!;
            // se calcula el centro de la cuenta
            var cuentaCenter = Offset(
              center.dx + cos(angle) * radius, //posición en x
              center.dy + sin(angle) * radius, //posición en y
            );
            //destination Rectangle, da la ubicación y la escala de la imagen
            if (detail.width == 'basic') {
              imageWidth = imageWidthBasic;
              imageHeight = imageHeightBasic; 
            }
            if (detail.width == 'large') {
              imageWidth = imageWidthLarge; 
              imageHeight = imageHeightLarge;
            }
            if (detail.width == 'largest') {
              imageWidth = imageWidthLargest;
              imageHeight = imageHeightLargest;
            }
            if (currentCuentaName == 'medalla') { //hacer más universal, cómo marcar como inicio****************
              cuentaCenter = Offset(
                center.dx + cos(angle) * radius, //posición en x
                center.dy + (sin(angle) * radius) + imageHeightBasic * 0.8, //posición en y se traslada un poco hacia abajo
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
              final srccuentas = Rect.fromLTWH(0,0,image.width.toDouble(), image.height.toDouble());  
              canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);

          currentDetailElements.add({
            'cuenta': currentCuentaName,
            'angle': angle,
            'width': detail.width,
            'height': detail.height,
            'dstcuentas': dstcuentas,
            'cuentaCenter': cuentaCenter,
          });

          i++; // Increment 'i' for the next *individual* bead/element
        }
        // Return the list of elements generated for this 'detail' entry.
        return currentDetailElements;
      }).toList();

      Data.rosaryDetailsExtension.map((e) => {
        cuentaName = e.cuenta,
        image = cuentas[cuentaName]!,
        cuentaCount = e.count,
        cuentaOrder = e.order,
        cuentaWidth = e.width,
        cuentaHeight = e.height,
      }
      ).toList();

          // Se dibuja el brillo
          if (rosaryElements.isNotEmpty) {
            var element = rosaryElements[counter];
            cuentaName = element['cuenta']; 
            //^^^ puedo utilizarlo para agregar la oración de acuerdo al nombre
            //Data.rosaryDetails aquí tengo el nombre de la cuenta y las oraciones 
            cuentaOrder = cuentasOrder;
            cuentaCount = cuentasCount;
            cuentaWidth = element['width'];
            cuentaHeight = element['height'];
            dstcuentas = element['dstcuentas'];
            var cuentaCenter = element['cuentaCenter'];
            
            //se dibuja la cuenta brillo
            image = cuentas['brillo']!;

            //destination Rectangle, da la ubicación y la escala de la imagen
            if (cuentaWidth == 'basic') {
              imageWidth = imageWidthBasic * 0.7;
              imageHeight = imageHeightBasic * 0.7; 
            }
            if (cuentaWidth == 'large') {
              imageWidth = imageWidthLarge * 0.4; 
              imageHeight = imageHeightLarge * 0.4;
            }
            if (cuentaWidth == 'largest') {
              imageWidth = imageWidthLargest * 0.3;
              imageHeight = imageHeightLargest * 0.7;
            }
            
            dstcuentas = Rect.fromCenter(
              center: cuentaCenter, 
              width: imageWidth, 
              height: imageHeight,
            );
              final paintImage = Paint();
              paintImage.colorFilter = const ColorFilter.mode(
                Color.fromRGBO(255, 255, 255, 0.5), 
                BlendMode.modulate, // Multiplica los valores de color y alfa
              );
              //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
              final srccuentas = Rect.fromLTWH(0,0,image.width.toDouble(), image.height.toDouble());  
              canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
          }

        }
    
  
    @override
    bool shouldRepaint(covariant CuentasPainter oldDelegate) {
      return oldDelegate.cuentas != cuentas;
    }
}