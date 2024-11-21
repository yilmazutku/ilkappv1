import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';

class PastAppointmentsPage extends StatefulWidget {
  final String userId;

  const PastAppointmentsPage({super.key, required this.userId});

  @override
  createState() => _PastAppointmentsPageState();
}

class _PastAppointmentsPageState extends State<PastAppointmentsPage> {
  int _currentPage = 1;
  static const int _pageSize = 5;
  late Future<List<AppointmentModel>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  void _fetchAppointments() {
    _appointmentsFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('appointments')
        .orderBy('appointmentDateTime', descending: true)
       // .limit(_pageSize)
        .get()
        .then((snapshot) {
          var list = snapshot.docs.map((doc) => AppointmentModel.fromDocument(doc)).toList();
          if(list.length>_currentPage*1)
          return list.getRange((_currentPage-1)*1, _currentPage*1).toList();
          else
            return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past Appointments')),
      body: FutureBuilder<List<AppointmentModel>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No past appointments found.'));
          }

          final appointments = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return ListTile(
                      title: Text(DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)),
                      subtitle: Text('Status: ${appointment.status.label}'),
                    );
                  },
                ),
              ),
              if (appointments.length == _pageSize)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return TextButton(
                      onPressed: () {
                        setState(() {
                          _currentPage = index + 1;
                          _fetchAppointments();
                        });
                      },
                      child: Text('${index + 1}'),
                    );
                  }),
                ),
            ],
          );
        },
      ),
    );
  }
}
