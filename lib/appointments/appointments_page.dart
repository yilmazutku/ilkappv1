import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../commons/logger.dart';
import '../managers/appointment_manager.dart';
import '../commons/common.dart';

final auth = FirebaseAuth.instance;
final Logger logger = Logger.forClass(AppointmentsPage);

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentManager = Provider.of<AppointmentManager>(context);
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    logger.info('Building BookingPage...');

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
                                appointmentManager
                                    .setSelectedTime(selected ? time : null);
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
                  width: screenWidth * 0.35, // 50% of the screen width
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await appointmentManager.bookAppointment(Appointment(
                          id: FirebaseAuth.instance.currentUser!.uid,
                          name:
                              FirebaseAuth.instance.currentUser!.displayName ??
                                  'nullDisplayName',
                          serviceType:
                              appointmentManager.serviceTypeNotifier.value!,
                          dateTime: DateTime(
                            appointmentManager.selectedDate.year,
                            appointmentManager.selectedDate.month,
                            appointmentManager.selectedDate.day,
                            appointmentManager.selectedTimeNotifier.value!.hour,
                            appointmentManager
                                .selectedTimeNotifier.value!.minute,
                          ),
                        ));
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
                                      selectionColor: Colors.blue,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      } catch (e) {
                        logger.err(
                            'an error occurred while making appointment= {}',
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
              // Existing FutureBuilder for displaying appointments
              // Existing FutureBuilder for displaying appointments
// Existing FutureBuilder for displaying appointments
              FutureBuilder<List<Appointment>>(
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
                          title: Text("Görüşme: ${appointment.serviceType}"),
                          subtitle: Text(
                              "Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              // Show confirmation dialog before canceling
                              bool? confirmCancel = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Randevuyu İptal Et"),
                                    content: const Text("Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false); // Dismisses the dialog and returns false
                                        },
                                        child: const Text("Hayır"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true); // Dismisses the dialog and returns true
                                        },
                                        child: const Text("Evet"),
                                      ),
                                    ],
                                  );
                                },
                              );

                              // If the user confirmed the cancellation
                              if (confirmCancel == true) {
                                try {
                                  await appointmentManager.cancelAppointment(appointment.id);
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                         title: const Text("Başarılı"),
                                          content: const Text("Randevu iptal edildi."),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Dismiss the dialog
                                              },
                                              child: const Text("Tamam"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                } catch (e) {
                                  logger.err('an error occurred while canceling appointment= {}', [e]);
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Hata"),
                                          content: Text("Hata: ${e.toString()}"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Dismiss the dialog
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
/*
  Here's a summary of how this setup works:

Dropdown for Service Type: Allows the user to select the type of meeting (e.g., online or face-to-face) from a dropdown list.

Date Picker: Lets the user pick a date for the appointment. Upon selecting a date, it updates the selectedDate in the AppointmentManager, which, in turn, can trigger fetching of available time slots for that date.

FutureBuilder for Time Slots: Utilizes a FutureBuilder to asynchronously fetch and display available time slots based on the selected date. It shows a loading indicator while fetching and provides options for the user to select a time slot.

Booking Button: Upon clicking, it validates the input fields, creates a new Appointment object with the selected details, and calls bookAppointment on the AppointmentManager to save the appointment. If successful, it displays a confirmation message.

This architecture helps to keep your UI code clean and maintainable, facilitating easy updates or changes to the state management logic without requiring significant changes to your UI code.
   */

class ServiceTypeDropdown extends StatelessWidget {
  const ServiceTypeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentManager = Provider.of<AppointmentManager>(context);
    return ValueListenableBuilder<String?>(
      valueListenable: appointmentManager.serviceTypeNotifier,
      builder: (context, serviceType, child) {
        return DropdownButton<String>(
          value: serviceType,
          hint: const Text('Select Service Type'),
          onChanged: (String? newValue) {
            appointmentManager.setServiceType(newValue);
          },
          items: appointmentManager.meetingTypeList
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }
}
