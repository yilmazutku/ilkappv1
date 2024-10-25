// appointments_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/logger.dart';
import '../models/appointment_model.dart';
import '../models/subs_model.dart';
import '../providers/appointment_manager.dart';

final Logger logger = Logger.forClass(AppointmentsPage);

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentManager = Provider.of<AppointmentManager>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: FutureBuilder<SubscriptionModel?>(
        future: appointmentManager.getCurrentSubscription(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            logger.err('Error fetching subscription: {}', [snapshot.error!]);
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData && snapshot.data != null) {
            SubscriptionModel subscription = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meetings Remaining: ${subscription.meetingsRemaining}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text('Meeting Type:'),
                      SizedBox(width: 16),
                      ServiceTypeDropdown(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(DateFormat('dd/MM/yyyy')
                        .format(appointmentManager.selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: appointmentManager.selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 45)),
                      );
                      if (picked != null &&
                          picked != appointmentManager.selectedDate) {
                        appointmentManager.setSelectedDate(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<TimeOfDay>>(
                    future: appointmentManager.getAvailableTimesForDate(
                        appointmentManager.selectedDate),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        logger.err('Snapshot error: {}', [snapshot.error!]);
                        return Text("Error: ${snapshot.error}");
                      } else if (snapshot.hasData) {
                        var availableTimes = snapshot.data!;
                        if (availableTimes.isEmpty) {
                          return const Text(
                              'No available time slots for the selected date.');
                        }
                        return Wrap(
                          children: availableTimes.map((time) {
                            return ValueListenableBuilder<TimeOfDay?>(
                              valueListenable:
                              appointmentManager.selectedTimeNotifier,
                              builder: (context, selectedTime, child) {
                                return ChoiceChip(
                                  label: Text(time.format(context)),
                                  selected: selectedTime == time,
                                  onSelected: (bool selected) {
                                    appointmentManager.setSelectedTime(
                                        selected ? time : null);
                                  },
                                );
                              },
                            );
                          }).toList(),
                        );
                      } else {
                        return const Text(
                            'No available time slots for the selected date.');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await appointmentManager.bookAppointmentForCurrentUser();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Appointment booked successfully.')),
                            );
                          }
                        } catch (e) {
                          logger.err(
                              'An error occurred while booking appointment: {}',
                              [e]);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      child: const Text('Book Appointment'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'My Appointments',
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<List<AppointmentModel>>(
                    future:
                    appointmentManager.fetchCurrentUserAppointments(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else if (snapshot.hasData) {
                        var appointments = snapshot.data!;
                        if (appointments.isEmpty) {
                          return const Text("No upcoming appointments.");
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: appointments.map((appointment) {
                            return ListTile(
                              title: Text(
                                  "Meeting: ${appointment.meetingType.label}"),
                              subtitle: Text(
                                  "Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.red),
                                onPressed: () async {
                                  bool? confirmCancel = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                        const Text("Cancel Appointment"),
                                        content: const Text(
                                            "Are you sure you want to cancel this appointment?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(false);
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
                                    try {
                                      await appointmentManager
                                          .cancelAppointment(
                                          appointment.appointmentId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Appointment canceled.')),
                                        );
                                      }
                                    } catch (e) {
                                      logger.err(
                                          'An error occurred while canceling appointment: {}',
                                          [e]);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        return const Text("No upcoming appointments.");
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            return const Center(
                child: Text('No active subscription found.'));
          }
        },
      ),
    );
  }
}

class ServiceTypeDropdown extends StatelessWidget {
  const ServiceTypeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentManager =
    Provider.of<AppointmentManager>(context, listen: false);

    return ValueListenableBuilder<MeetingType>(
      valueListenable: appointmentManager.meetingTypeNotifier,
      builder: (context, meetingType, child) {
        return DropdownButton<MeetingType>(
          value: meetingType,
          onChanged: (MeetingType? newValue) {
            appointmentManager.setMeetingType(newValue);
          },
          items: MeetingType.values
              .map<DropdownMenuItem<MeetingType>>((MeetingType type) {
            return DropdownMenuItem<MeetingType>(
              value: type,
              child: Text(type.label),
            );
          }).toList(),
        );
      },
    );
  }
}
