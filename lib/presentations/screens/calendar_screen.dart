import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key:key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
  
}


class _CalendarScreenState extends State<CalendarScreen> {
  DateTime dateSelected = DateTime.now();
  TimeOfDay timeSelected = TimeOfDay.now();

  @override 
  void initState() {
    super.initState();
  }

    // Función para mostrar el selector de hora
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: timeSelected,
    );
    if (picked != null && picked != timeSelected) {
      setState(() {
        timeSelected = picked;
      });
      print('Hora seleccionada: ${timeSelected.format(context)}');
    }
  }


@override
Widget build(BuildContext context) {

  return Scaffold(
    appBar: AppBar(
      title: const Text('Calendario'),
    ),
    body: Column(
      children: [
        // Botón para mostrar el selector de hora
          ElevatedButton(
            onPressed: () => _selectTime(context),
            child: const Text('Seleccionar Hora'),
          ),
          // Muestra la hora seleccionada
          Text('Hora seleccionada: ${timeSelected.format(context)}'),
        CalendarDatePicker(
          initialDate: dateSelected, 
          firstDate: DateTime(1900, 1, 1), 
          lastDate: DateTime(2050, 1, 1), 
          onDateChanged: (value) {
            // Aquí puedes manejar el cambio de fecha
            print('Fecha seleccionada: $value');
            dateSelected = value;
          },
          )
      ],
    ),
  );
}

}