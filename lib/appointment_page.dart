import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:table_calendar/table_calendar.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // Define the selected day and focused day
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Appointment')),
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16),  // Adjust these dates as needed
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) {
          // Use `selectedDayPredicate` to determine which day is currently selected.
          // If this returns true, then `day` will be marked as selected.

          // Using `isSameDay` to check if two dates are the same day.
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            // Call `setState()` when updating the selected day
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; // update `_focusedDay` here as well
              Appointment? info= requestInfo();
            });
          }
        },
        onPageChanged: (focusedDay) {
          // No need to call `setState()` here
          _focusedDay = focusedDay;
        },
        // Add more configurations here...
      ),
    );
  }

  Appointment? requestInfo() {
  //online mi yuzyuze mi? kendisi adina mi, isim yazsin. 2 field kendi girecek, time zaten alindi, id platform gnerated
    
    return null;
  }
}
class Appointment {
  final String name;
  final DateTime time;
  final String service;
  final String id;

  Appointment({
    required this.name,
    required this.time,
    required this.service,
    required this.id
  });
}