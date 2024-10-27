import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../providers/appointment_manager.dart';

final Logger logger = Logger.forClass(AdminAppointmentsPage);

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({Key? key}) : super(key: key);

  @override
  _AdminAppointmentsPageState createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  bool isLoading = true;
  List<AppointmentModel> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAllAppointments();
  }

  Future<void> fetchAllAppointments() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .get();

      List<AppointmentModel> fetchedAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      setState(() {
        appointments = fetchedAppointments;
        isLoading = false;
      });
    } catch (e) {
      logger.err('Error fetching appointments: {}', [e]);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    try {
      AppointmentManager appointmentManager = AppointmentManager();
      appointmentManager.setUserId(appointment.userId);
      await appointmentManager.cancelAppointment(appointment.appointmentId, canceledBy: 'admin');
       if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled.')),
      );

      fetchAllAppointments();
    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Appointments'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
          ? const Center(child: Text('No appointments found.'))
          : ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          AppointmentModel appointment = appointments[index];
          return ListTile(
            title: Text(
                'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
            subtitle: Text(
                'User ID: ${appointment.userId}\nType: ${appointment.meetingType.label}\nStatus: ${appointment.status.label}\nCanceled By: ${appointment.canceledBy ?? 'N/A'}'),
            trailing: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                bool? confirmCancel = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Cancel Appointment"),
                      content: const Text("Are you sure you want to cancel this appointment?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    );
                  },
                );

                if (confirmCancel == true) {
                  _cancelAppointment(appointment);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
