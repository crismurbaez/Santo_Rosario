import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key:key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
  
}

class _CalendarScreenState extends State<CalendarScreen> {

  @override 
  void initState() {
    super.initState();
  }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Calendario'),
    ),
    body: Column(
      children: [
        Text('Calendario en construcción'),
        TableCalendar(
          focusedDay: DateTime.now(), 
          firstDay: DateTime.utc(2024,1,1), 
          lastDay: DateTime.utc(2030,12,31)
        )
      ],
    ),
  );
}

}