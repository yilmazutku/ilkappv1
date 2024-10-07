import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../commons/userclass.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  _AdminAppointmentsPageState createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  Map<DateTime, List<Map<String, dynamic>>> dailyAppointments = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      // Fetch all appointments from all users
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .get();

      List<AppointmentModel> appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      // Fetch user details
      Set<String> userIds = appointments.map((a) => a.userId).toSet();
      Map<String, UserModel> userMap = {};

      for (String userId in userIds) {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userMap[userId] = UserModel.fromDocument(userDoc);
        }
      }

      // Organize appointments by date
      Map<DateTime, List<Map<String, dynamic>>> appointmentsByDate = {};

      for (var appointment in appointments) {
        DateTime date = DateTime(
            appointment.appointmentDateTime.year,
            appointment.appointmentDateTime.month,
            appointment.appointmentDateTime.day);

        if (!appointmentsByDate.containsKey(date)) {
          appointmentsByDate[date] = [];
        }

        appointmentsByDate[date]!.add({
          'appointment': appointment,
          'user': userMap[appointment.userId],
        });
      }

      setState(() {
        dailyAppointments = appointmentsByDate;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Appointments'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dailyAppointments.isEmpty
          ? const Center(child: Text('No appointments found.'))
          : ListView.builder(
        itemCount: dailyAppointments.keys.length,
        itemBuilder: (context, index) {
          DateTime date = dailyAppointments.keys.elementAt(index);
          List<Map<String, dynamic>> appointments = dailyAppointments[date]!;

          return ExpansionTile(
            title: Text(DateFormat('EEEE, MMM d').format(date)),
            children: appointments.map((data) {
              AppointmentModel appointment = data['appointment'];
              UserModel? user = data['user'];
              return ListTile(
                title: Text(
                    '${formatDateTime(appointment.appointmentDateTime)} - ${appointment.meetingType.label}'),
                subtitle: Text(
                    'User: ${user?.name ?? 'Unknown'} (${appointment.userId})\nStatus: ${appointment.status}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
