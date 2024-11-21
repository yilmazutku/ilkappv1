import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../models/user_model.dart';
import '../providers/appointment_manager.dart';
import '../providers/user_provider.dart';
import '../dialogs/edit_appointment_dialog.dart';

final Logger logger = Logger.forClass(AdminAppointmentsPage);

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  DateTime? startDate;
  DateTime? endDate;
  MeetingType? selectedMeetingType;
  MeetingStatus? selectedMeetingStatus;
  String? sortOption = 'Date Descending';

  final List<MeetingType?> meetingTypes = [null, ...MeetingType.values];
  final List<MeetingStatus?> meetingStatuses = [null, ...MeetingStatus.values];
  final List<String> sortOptions = ['Date Ascending', 'Date Descending', 'Name A-Z', 'Name Z-A'];

  late Future<List<AppointmentModel>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAllAppointments();
  }

  void _fetchAllAppointments() {
    _appointmentsFuture = _fetchAppointmentsWithUsers();
  }

  Future<List<AppointmentModel>> _fetchAppointmentsWithUsers() async {
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

      // Apply filters and sorting
      return _applyFiltersAndSort(fetchedAppointments);
    } catch (e) {
      logger.err('Error fetching appointments: {}', [e]);
      return [];
    }
  }

  List<AppointmentModel> _applyFiltersAndSort(List<AppointmentModel> appointments) {
    List<AppointmentModel> filteredAppointments = appointments.where((appointment) {
      bool matchesDate = (startDate == null || appointment.appointmentDateTime.isAfter(startDate!)) &&
          (endDate == null || appointment.appointmentDateTime.isBefore(endDate!.add(const Duration(days: 1))));

      bool matchesType = selectedMeetingType == null || appointment.meetingType == selectedMeetingType;
      bool matchesStatus = selectedMeetingStatus == null || appointment.status == selectedMeetingStatus;

      return matchesDate && matchesType && matchesStatus;
    }).toList();

    // Sort appointments based on selected option
    filteredAppointments.sort((a, b) {
      switch (sortOption) {
        case 'Date Ascending':
          return a.appointmentDateTime.compareTo(b.appointmentDateTime);
        case 'Date Descending':
          return b.appointmentDateTime.compareTo(a.appointmentDateTime);
        case 'Name A-Z':
          return (a.user?.name ?? '').compareTo(b.user?.name ?? '');
        case 'Name Z-A':
          return (b.user?.name ?? '').compareTo(a.user?.name ?? '');
        default:
          return 0;
      }
    });

    return filteredAppointments;
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
        _fetchAllAppointments();
      });
    }
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    try {
      final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);

      if (await appointmentManager.cancelAppointment(appointment.appointmentId, appointment.userId, canceledBy: 'admin')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment canceled.')),
        );
      }

      _fetchAllAppointments();
    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling appointment: $e')),
      );
    }
  }

  void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () {
            setState(() {
              _fetchAllAppointments();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _fetchAllAppointments();
              });
            },
            tooltip: 'Refresh',
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
                child: Text(type == null ? 'All' : type.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMeetingType = value;
                _fetchAllAppointments();
              });
            },
          ),
          DropdownButton<MeetingStatus?>(
            value: selectedMeetingStatus,
            hint: const Text('Meeting Status'),
            items: meetingStatuses.map((status) {
              return DropdownMenuItem<MeetingStatus?>(
                value: status,
                child: Text(status == null ? 'All' : status.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMeetingStatus = value;
                _fetchAllAppointments();
              });
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
                _fetchAllAppointments();
              });
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
                  _fetchAllAppointments();
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<List<AppointmentModel>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            logger.err('Error fetching appointments in build method: {}', [snapshot.error??'snapshot error']);
            return Center(child: Text('Error fetching appointments: ${snapshot.error}'));
          } else {
            final appointments = snapshot.data ?? [];

            if (appointments.isEmpty) {
              return const Center(child: Text('No appointments found.'));
            }

            return ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                AppointmentModel appointment = appointments[index];
                return ListTile(
                  title: Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
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
                            await _deleteAppointment(appointment);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
