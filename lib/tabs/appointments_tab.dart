// tabs/appointments_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../commons/userclass.dart';
import '../managers/appointment_manager.dart';
import 'basetab.dart';

class AppointmentsTab extends BaseTab<AppointmentManager> {
  const AppointmentsTab({super.key, required super.userId})
      : super(
          allDataLabel: 'All Appointments',
          subscriptionDataLabel: 'Subscription Appointments',
        );

  @override
  AppointmentManager getProvider(BuildContext context) {
    return Provider.of<AppointmentManager>(context);
  }

  @override
  List<AppointmentModel> getDataList(AppointmentManager provider) {
    return provider.appointments;
  }

  @override
  bool getShowAllData(AppointmentManager provider) {
    return provider.showAllAppointments;
  }

  @override
  void setShowAllData(AppointmentManager provider, bool value) {
    provider.setShowAllAppointments(value);
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<AppointmentModel> appointments = dataList.cast<AppointmentModel>();
    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        AppointmentModel appointment = appointments[index];
        return ListTile(
          title: Text('Date: ${appointment.appointmentDateTime.toLocal()}'),
          subtitle: Text('Type: ${appointment.meetingType.label}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${appointment.status.label}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditAppointmentDialog(context, appointment);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditAppointmentDialog(
      BuildContext context, AppointmentModel appointment) {
    // Implement your edit appointment dialog
  }
}
