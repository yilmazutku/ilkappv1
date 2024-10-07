import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../commons/logger.dart';
import '../commons/userclass.dart';
import '../managers/appointment_manager.dart';
import '../commons/common.dart';

final Logger logger = Logger.forClass(AppointmentsPage);

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentManager = Provider.of<AppointmentManager>(context);
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    logger.info('Building AppointmentsPage...');

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text('Görüşme'),
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
                    await appointmentManager.setSelectedDate(picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<TimeOfDay>>(
                future: appointmentManager
                    .getAvailableTimesForDate(appointmentManager.selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    var availableTimes = snapshot.data!;
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
                        'Seçtiğiniz gün için müsait bir saat bulunmuyor.');
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: screenWidth * 0.35, // 35% of the screen width
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          logger.err('User not authenticated.');
                          return;
                        }
                        final userId = user.uid;
                        final appointmentId = FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('appointments')
                            .doc()
                            .id;

                        AppointmentModel appointment = AppointmentModel(
                          appointmentId: appointmentId,
                          userId: userId,
                          meetingType:
                          appointmentManager.meetingTypeNotifier.value,
                          appointmentDateTime: DateTime(
                            appointmentManager.selectedDate.year,
                            appointmentManager.selectedDate.month,
                            appointmentManager.selectedDate.day,
                            appointmentManager
                                .selectedTimeNotifier.value!.hour,
                            appointmentManager
                                .selectedTimeNotifier.value!.minute,
                          ),
                          status: 'scheduled',
                          createdAt: DateTime.now(),
                        );

                        await appointmentManager.bookAppointment(appointment);

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Başarılı!"),
                                content: const Text(
                                    "Randevunuz başarılı bir şekilde oluşturuldu."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Dismiss the dialog
                                    },
                                    child: const Text(
                                      "Tamam",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      } catch (e) {
                        logger.err(
                            'An error occurred while making appointment: {}',
                            [e]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Book Appointment',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Randevularım',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<AppointmentModel>>(
                future: appointmentManager.fetchCurrentUserAppointments(
                    FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    var appointments = snapshot.data!;
                    if (appointments.isEmpty) {
                      return const Text("Yaklaşan randevunuz bulunmuyor.");
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: appointments.map((appointment) {
                        return ListTile(
                          title: Text(
                              "Görüşme: ${appointment.meetingType.label}"),
                          subtitle: Text(
                              "Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}"),
                          trailing: IconButton(
                            icon:
                            const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              bool? confirmCancel = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title:
                                    const Text("Randevuyu İptal Et"),
                                    content: const Text(
                                        "Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text("Hayır"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text("Evet"),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmCancel == true) {
                                try {
                                  await appointmentManager.cancelAppointment(
                                      appointment.userId,
                                      appointment.appointmentId);
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Başarılı"),
                                          content: const Text(
                                              "Randevu iptal edildi."),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Dismiss the dialog
                                              },
                                              child: const Text("Tamam"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                } catch (e) {
                                  logger.err(
                                      'An error occurred while canceling appointment: {}',
                                      [e]);
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Hata"),
                                          content:
                                          Text("Hata: ${e.toString()}"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Dismiss the dialog
                                              },
                                              child: const Text("Tamam"),
                                            ),
                                          ],
                                        );
                                      },
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
                    return const Text("Yaklaşan randevunuz bulunmuyor.");
                  }
                },
              ),
            ],
          ),
        ),
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