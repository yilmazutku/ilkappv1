import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/logger.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_manager.dart';
import '../providers/user_provider.dart';

final Logger logger = Logger.forClass(AppointmentsPage);

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
   createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _selectedDate = DateTime.now();
  MeetingType _selectedMeetingType = MeetingType.f2f;
  TimeOfDay? _selectedTime;
  List<TimeOfDay> _availableTimes = [];

  @override
  void initState() {
    super.initState();
    logger.info('started initing state for appointments page state.');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAvailableTimesAndUserAppointments();
    });
    logger.info('ended initing state for appointments page state.');
  }

  Future<void> _fetchAvailableTimesAndUserAppointments() async {
    try {
      final appointmentManager =
          Provider.of<AppointmentManager>(context, listen: false);
      await appointmentManager.fetchUserAppointments();
      List<TimeOfDay> availableTimes =
          await appointmentManager.getAvailableTimesForDate(_selectedDate);
      setState(() {
        _availableTimes = availableTimes;
      });
    } catch (e) {
      logger.err('Error fetching available times: {}', [e]);
      setState(() {});
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    try {
      final appointmentManager =
          Provider.of<AppointmentManager>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      String? userId = appointmentManager.userId;
      String? subscriptionId =
          userProvider.selectedSubscription?.subscriptionId;

      if (userId == null || subscriptionId == null) {
        throw Exception('User ID or Subscription ID is not set.');
      }

      DateTime appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      bool isAvailable =
          appointmentManager.isTimeSlotAvailable(_selectedDate, _selectedTime!);

      if (!mounted) return;
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected time slot is not available.')),
        );
        return;
      }

      String appointmentId = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .doc()
          .id;

      AppointmentModel appointment = AppointmentModel(
        appointmentId: appointmentId,
        userId: userId,
        subscriptionId: subscriptionId,
        meetingType: _selectedMeetingType,
        appointmentDateTime: appointmentDateTime,
        status: MeetingStatus.scheduled,
        createdAt: DateTime.now(),
        createdBy: 'user',
      );

      await appointmentManager.addAppointment(appointment);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully.')),
      );

      // Refresh available times and user's appointments
      await _fetchAvailableTimesAndUserAppointments();
    } catch (e) {
      logger.err('Error booking appointment: {}', [e]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      final appointmentManager =
          Provider.of<AppointmentManager>(context, listen: false);

      if (await appointmentManager.cancelAppointment(appointmentId,
          canceledBy: 'user')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment canceled.')),
        );
      }
      await _fetchAvailableTimesAndUserAppointments();
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
    final appointmentManager = Provider.of<AppointmentManager>(context);
logger.info('build appts page');
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Meeting Type:'),
                const SizedBox(width: 16),
                DropdownButton<MeetingType>(
                  value: _selectedMeetingType,
                  onChanged: (MeetingType? newValue) {
                    setState(() {
                      _selectedMeetingType = newValue!;
                    });
                  },
                  items: MeetingType.values
                      .map<DropdownMenuItem<MeetingType>>((MeetingType type) {
                    return DropdownMenuItem<MeetingType>(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 45)),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                    _selectedTime = null;
                  });
                  await _fetchAvailableTimesAndUserAppointments();
                }
              },
            ),
            const SizedBox(height: 16),
            appointmentManager.isLoading
                ? const CircularProgressIndicator()
                : _availableTimes.isEmpty
                    ? const Text(
                        'No available time slots for the selected date.')
                    : Wrap(
                        spacing: 8.0,
                        children: _availableTimes.map((time) {
                          return ChoiceChip(
                            label: Text(time.format(context)),
                            selected: _selectedTime == time,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedTime = selected ? time : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _bookAppointment,
                child: const Text('Book Appointment'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'My Appointments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            appointmentManager.isLoading
                ? const CircularProgressIndicator()
                : _buildAppointmentsList(appointmentManager.userAppointments),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    final upcomingAppointments = appointments.where((appointment) {
      return appointment.appointmentDateTime.isAfter(DateTime.now()) &&
          appointment.status != MeetingStatus.canceled && !appointment.isDeleted!;
    }).toList();

    if (upcomingAppointments.isEmpty) {
      return const Text('No upcoming appointments.');
    }
  logger.info('upcomingAppointments={}',[upcomingAppointments]);
    return Column(
      children: upcomingAppointments.map((appointment) {
        return ListTile(
          title: Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
          subtitle: Text('Type: ${appointment.meetingType.label}'),
          trailing: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () async {
              bool? confirmCancel = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Cancel Appointment"),
                    content: const Text(
                        "Are you sure you want to cancel this appointment?"),
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
                await _cancelAppointment(appointment.appointmentId);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
