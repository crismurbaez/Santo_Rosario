import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/data.dart'; 
import '../widgets/prayer_dialog.dart';

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
  Map<String, ui.Image>? _loadedImages;
  int _counter = 0;
  int rosaryBeadCount = Data.rosaryCircleBeadCount + Data.rosaryExtensionBeadCount;
  int rosaryCircleBeadCount = Data.rosaryCircleBeadCount;
  List<String> _currentPrayers = [''];
  int _orderPrayer=0;
  int _orderMystery=0;
  

    @override
  void initState() {
    super.initState();
    _loadAllImages(); // Inicia la carga de todas las imágenes
  }

    void _incrementCounter() {
      setState(() {
          if (_orderPrayer < _currentPrayers.length-1) {
            _orderPrayer++;
          } else {
            if (_counter < rosaryBeadCount-1) {
            _counter++; // Incrementa el contador
            _orderPrayer = 0;
            }
          }
      });
    }
    //TODO también decrementar el orden de oración si se vuelve atrás
    void _decrementCounter() {
      setState(() {
        if (_orderPrayer > 0) {
          _orderPrayer--; // Decrementa el orden de oración
        } else if (_counter > 0 && _orderPrayer == 0) {
          // Si estamos en la primera oración y el contador es mayor que 0, decrementamos el contador
          // y reiniciamos el orden de oración a 0.
          // Esto permite retroceder al misterio anterior.
          _counter--;  // Disminuye el contador
          _orderPrayer = 0;
        }
      });
    }
    // Esta función se llama cuando una cuenta es resaltada
    // y actualiza las oraciones actuales y el orden del misterio.
    void _handleCuentaHighlighted(List<String> prayers, int orderMystery) {
      // Solo actualizamos si las oraciones son diferentes para evitar redibujados innecesarios
      if (_currentPrayers.toString() != prayers.toString() || _orderMystery != orderMystery) {
        // Usamos addPostFrameCallback para posponer la llamada a setState
        // hasta después de que el frame actual haya terminado de construirse.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _currentPrayers = prayers; // Actualiza las oraciones actuales
            _orderMystery = orderMystery; // Actualiza el orden del misterio
          });
        });
      }
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
                    color: ui.Color.fromARGB(255, 228, 207, 143), 
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
                      rosaryBeadCount: rosaryBeadCount,
                      rosaryCircleBeadCount: rosaryCircleBeadCount,
                      onCuentaHighlighted: _handleCuentaHighlighted, 
                      orderPrayer: _orderPrayer, 
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
                        child: const Icon(Icons.arrow_back),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        ),
                        onPressed: () {
                          // Muestra el diálogo con las oraciones actuales
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return PrayerDialog(
                                prayer: _currentPrayers[_orderPrayer], 
                                mystery: widget.mystery,
                                currentMysteryOrder:_orderMystery, 
                              );
                            },
                          );
                        },
                        child: Text(_currentPrayers[_orderPrayer]),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 192, 121, 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        ),
                        onPressed: _incrementCounter,
                        child: const Icon(Icons.arrow_forward),
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
  final int rosaryBeadCount;
  final int rosaryCircleBeadCount;
  final Function(List<String> prayers, int orderMystery) onCuentaHighlighted; //pasa el conjunto de oraciones de la cuenta resaltada
  final int orderPrayer; // <-- Añadido para el orden de oración


  CuentasPainter({
    required this.cuentas,
    required this.counter,
    required this.rosaryBeadCount,
    required this.rosaryCircleBeadCount,
    required this.onCuentaHighlighted,
    required this.orderPrayer,
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
      int orderPrayer = this.orderPrayer;
      

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
       List<dynamic> rosaryElementsCircle = Data.rosaryDetailsCircle.expand((detail) {
        List<Map<String, dynamic>> currentDetailElements = [];

        for (int j = 0; j < detail.count; j++) {
          double angle = location * (pi / 2) + 2 * pi * i * orientation / rosaryCircleBeadCount;

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
            if (currentCuentaName == 'medalla') { //TODOhacer más universal, cómo marcar como inicio****************
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
            'prayers': detail.prayers, // Agrega las oraciones de la cuenta
            'order': detail.order, // Agrega el orden de la cuenta
          });

          i++; // Incremento de i para calcular el ángulo de la siguiente cuenta
        }
        return currentDetailElements;
      }).toList();

      //desplazamiento inicial de la extensión a partir de la ubicación de la medalla
      Offset cuentaCenter = Offset(
                medallaCenter.dx, //posición en x
                medallaCenter.dy + imageWidthBasic, //posición en y
              );
            
      List<dynamic> rosaryElementsExtension = Data.rosaryDetailsExtension.expand((detail) {
        List<Map<String, dynamic>> currentDetailElements = [];
        
        for (int j = 0; j < detail.count; j++) {

          String currentCuentaName = detail.cuenta; 
            image = cuentas[currentCuentaName]!;
            //destination Rectangle, da la ubicación y la escala de la imagen
            if (detail.width == 'basic') {
              imageWidth = imageWidthBasic;
              imageHeight = imageHeightBasic; 
              // se calcula el centro de la cuenta
              cuentaCenter = Offset(
                cuentaCenter.dx, //posición en x
                cuentaCenter.dy + imageHeight * 0.57, //posición en y
              );
            }
            if (detail.width == 'large') {
              imageWidth = imageWidthLarge; 
              imageHeight = imageHeightLarge;
              cuentaCenter = Offset(
                cuentaCenter.dx, //posición en x
                cuentaCenter.dy + imageHeight * 0.25, //posición en y
              );
            }
            if (detail.width == 'largest') {
              imageWidth = imageWidthLargest;
              imageHeight = imageHeightLargest;
              cuentaCenter = Offset(
                cuentaCenter.dx + imageWidthBasic * 0.1, //posición en x
                cuentaCenter.dy + imageHeight * 0.45, //posición en y
              );
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
            'width': detail.width,
            'height': detail.height,
            'dstcuentas': dstcuentas,
            'cuentaCenter': cuentaCenter,
            'prayers': detail.prayers, // Agrega las oraciones de la cuenta
            'order': detail.order, // Agrega el orden de la cuenta
          });
        }
        return currentDetailElements;
      }).toList();

      final List<dynamic> allRosaryElements = rosaryElementsCircle + rosaryElementsExtension;

          // Se dibuja el brillo
          if (allRosaryElements.isNotEmpty) {
            var element = allRosaryElements[counter];
            cuentaName = element['cuenta']; 
            // Verificamos que 'prayers' exista y sea una List<String> antes de castear y llamar.
            if (element['prayers'] != null) {
              onCuentaHighlighted(element['prayers'] as List<String>, element['order'] as int); // Pasa las oraciones y el orden de la cuenta resaltada
            } else {
              // En caso de que, por alguna razón, no tenga la clave o el tipo correcto (poco probable ahora)
              onCuentaHighlighted([],0); // Pasa una lista vacía y un cero para evitar errores
            }
            cuentaOrder = cuentasOrder;
            cuentaCount = cuentasCount;
            cuentaWidth = element['width'];
            cuentaHeight = element['height'];
            dstcuentas = element['dstcuentas'];
            var cuentaCenter = element['cuentaCenter'];
            
            //se dibuja la cuenta brillo
            image = cuentas['brillo']!;

            
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
            if (cuentaName == 'cruz') {
              paintImage.colorFilter = const ColorFilter.mode(
                Color.fromRGBO(255, 255, 255, 0.3), 
                BlendMode.modulate, // Multiplica los valores de color y alfa
              );
            }
              //source rectangle, recorta la imagen a mostrar, en este caso la mostramos completa
              final srccuentas = Rect.fromLTWH(0,0,image.width.toDouble(), image.height.toDouble());  
              canvas.drawImageRect(image, srccuentas, dstcuentas, paintImage);
          }

        }
    
  
    @override
    bool shouldRepaint(covariant CuentasPainter oldDelegate) {
      return  oldDelegate.cuentas != cuentas
           || oldDelegate.counter != counter ||
              oldDelegate.rosaryBeadCount != rosaryBeadCount ||
              oldDelegate.rosaryCircleBeadCount != rosaryCircleBeadCount;
    }
}