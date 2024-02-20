import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../appointment_manager.dart';
import '../commons/common.dart';

class AdminAppointmentsPage extends StatelessWidget {
  const AdminAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the AppointmentManager provided above this widget in the tree
    final appointmentManager = Provider.of<AppointmentManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Appointments'),
      ),
      body: FutureBuilder(
        future: appointmentManager.fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching appointments"));
          }

          // Assuming fetchAppointmentsForWeek updates weeklyAppointments inside AppointmentManager
          return ListView.builder(
            itemCount: appointmentManager.weeklyAppointments.keys.length,
            itemBuilder: (context, index) {
              DateTime date = appointmentManager.weeklyAppointments.keys.elementAt(index);
              List<Appointment> appointments = appointmentManager.weeklyAppointments[date]!;
              return ExpansionTile(
                title: Text(DateFormat('EEEE, MMM d').format(date)),
                children: appointments.map((appointment) => ListTile(
                  title: Text('${TimeOfDay.fromDateTime(appointment.dateTime).format(context)} - ${appointment.serviceType}'),
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }
}