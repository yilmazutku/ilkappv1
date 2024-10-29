import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../dialogs/edit_appointment_dialog.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../models/user_model.dart';
import '../providers/appointment_manager.dart';

final Logger logger = Logger.forClass(AdminAppointmentsPage);

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  bool isLoading = true;
  List<AppointmentModel> allAppointments = [];
  List<AppointmentModel> appointments = [];

  DateTime? startDate;
  DateTime? endDate;
  MeetingType? selectedMeetingType;
  MeetingStatus? selectedMeetingStatus;
  String? sortOption = 'Date Descending';

  final List<MeetingType?> meetingTypes = [null, ...MeetingType.values];
  final List<MeetingStatus?> meetingStatuses = [null, ...MeetingStatus.values];
  final List<String> sortOptions = ['Date Ascending', 'Date Descending', 'Name A-Z', 'Name Z-A'];

  @override
  void initState() {
    super.initState();
    fetchAllAppointments();
  }

  void applyFiltersAndSort() {
    setState(() {
      appointments = allAppointments.where((appointment) {
        bool matchesDate = (startDate == null || appointment.appointmentDateTime.isAfter(startDate!)) &&
            (endDate == null || appointment.appointmentDateTime.isBefore(endDate!.add(const Duration(days: 1))));

        bool matchesType = selectedMeetingType == null || appointment.meetingType == selectedMeetingType;
        bool matchesStatus = selectedMeetingStatus == null || appointment.status == selectedMeetingStatus;

        return matchesDate && matchesType && matchesStatus;
      }).toList();

      // Sort appointments based on selected option
      appointments.sort((a, b) {
        switch (sortOption) {
          case 'Date Ascending':
            return a.appointmentDateTime.compareTo(b.appointmentDateTime);
          case 'Date Descending':
            return b.appointmentDateTime.compareTo(a.appointmentDateTime);
          case 'Name A-Z':
            return a.user?.name.compareTo(b.user?.name ?? '') ?? 0;
          case 'Name Z-A':
            return b.user?.name.compareTo(a.user?.name ?? '') ?? 0;
          default:
            return 0;
        }
      });
    });
  }

  void _pickDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
      });
      applyFiltersAndSort();
    }
  }

  Future<void> fetchAllAppointments() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collectionGroup('appointments').get();

      // Fetch appointments and associated user details
      List<AppointmentModel> fetchedAppointments = await Future.wait(snapshot.docs.map((doc) async {
        AppointmentModel appointment = AppointmentModel.fromDocument(doc);

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(appointment.userId)
            .get();

        appointment.user = UserModel.fromDocument(userDoc);
        return appointment;
      }).toList());

      setState(() {
        allAppointments = fetchedAppointments;
        applyFiltersAndSort();
        isLoading = false;
      });
    } catch (e) {
      logger.err('Error fetching appointments: {}', [e]);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    try {
      final appointmentManager =
      Provider.of<AppointmentManager>(context, listen: false);
      appointmentManager.setUserId(appointment.userId);

      if (await appointmentManager.cancelAppointment(appointment.appointmentId, canceledBy: 'admin')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment canceled.')),
        );
      }

      fetchAllAppointments();
    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      if (!mounted) return;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllAppointments, // Refresh button to reload data
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          DropdownButton<MeetingType?>(
            value: selectedMeetingType,
            hint: const Text('Meeting Type'),
            items: meetingTypes.map((type) {
              return DropdownMenuItem<MeetingType?>(
                value: type,
                child: Text(type == null ? 'Hepsi' : type.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMeetingType = value;
              });
              applyFiltersAndSort();
            },
          ),
          DropdownButton<MeetingStatus?>(
            value: selectedMeetingStatus,
            hint: const Text('Meeting Status'),
            items: meetingStatuses.map((status) {
              return DropdownMenuItem<MeetingStatus?>(
                value: status,
                child: Text(status == null ? 'Hepsi' : status.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMeetingStatus = value;
              });
              applyFiltersAndSort();
            },
          ),
          DropdownButton<String>(
            value: sortOption,
            hint: const Text('Sort by'),
            items: sortOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sortOption = value;
              });
              applyFiltersAndSort();
            },
          ),
          if (startDate != null || endDate != null || selectedMeetingType != null || selectedMeetingStatus != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                  selectedMeetingType = null;
                  selectedMeetingStatus = null;
                });
                applyFiltersAndSort();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (startDate != null && endDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Date Range: ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: appointments.isEmpty
                ? const Center(child: Text('No appointments found.'))
                : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                AppointmentModel appointment = appointments[index];
                return ListTile(
                  title: Text(
                      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
                  subtitle: Text(
                      'User: ${appointment.user?.name ?? 'Unknown'}\nType: ${appointment.meetingType.label}\nStatus: ${appointment.status.label}\nCanceled By: ${appointment.canceledBy ?? 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditAppointmentDialog(context, appointment);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          bool? confirmDelete = await showDialog<bool>(
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

                          if (confirmDelete == true) {
                            _deleteAppointment(appointment);
                          }
                        },
                      ),
                    ],
                  ),
                );

              },
            ),
          ),
        ],
      ),
    );
  }
  void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () {
            Provider.of<AppointmentManager>(context, listen: false)
                .fetchAppointments();
          },
        );
      },
    );
  }
}
