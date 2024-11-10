import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_manager.dart';
import '../dialogs/edit_appointment_dialog.dart';
import 'basetab.dart';

class AppointmentsTab extends BaseTab<AppointmentManager> {

  const AppointmentsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Appointments',
    subscriptionDataLabel: 'Subscription Appointments',
  );

  @override
  AppointmentManager getProvider(BuildContext context) {
    final provider = Provider.of<AppointmentManager>(context);
    return provider;
  }

  @override
  Future<List<dynamic>> getDataList(AppointmentManager provider, bool showAllData) {
    return provider.fetchAppointments(showAllAppointments: showAllData, userId: userId);
  }

  @override
  _AppointmentsTabState createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends BaseTabState<AppointmentManager, AppointmentsTab> {
  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<AppointmentModel> appointments = dataList.cast<AppointmentModel>();
    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        AppointmentModel appointment = appointments[index];
        return ListTile(
          title: Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
          subtitle: Text(
              'Type: ${appointment.meetingType.label}\nStatus: ${appointment.status.label}\nCanceled By: ${appointment.canceledBy ?? 'N/A'}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditAppointmentDialog(context, appointment);
            },
          ),
        );
      },
    );
  }

  void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () {
            setState(() {
              // Re-fetch data when the appointment is updated
              fetchData();
            });
          },
        );
      },
    );
  }
}
