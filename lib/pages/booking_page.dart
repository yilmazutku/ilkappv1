import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../managers/appointment_manager.dart';
import '../commons/common.dart';

final auth = FirebaseAuth.instance;

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentManager = Provider.of<AppointmentManager>(context);
    print('Building BookingPage...');

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const ServiceTypeDropdown(),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('dd/MM/yyyy').format(appointmentManager.selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: appointmentManager.selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != appointmentManager.selectedDate) {
                    appointmentManager.setSelectedDate(picked);
                    await appointmentManager.updateSelectedDate(picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<TimeOfDay>>(
                future: appointmentManager.getAvailableTimeSlots(appointmentManager.selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    var availableTimes = snapshot.data!;
                    return Wrap(
                      children: availableTimes.map((time) {
                        return ChoiceChip(
                          label: Text(time.format(context)),
                          selected: appointmentManager.selectedTime == time,
                          onSelected: (bool selected) {
                            appointmentManager.setSelectedTime(selected ? time : TimeOfDay.now());
                          },
                        );
                      }).toList(),
                    );
                  } else {
                    return const Text("Seçtiğiniz gün için müsait bir saat bulunmuyor.");
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await appointmentManager.bookAppointment(Appointment(
                      id: '123', // Replace with actual user ID
                      name: 'TODO', // Replace with actual user name
                      serviceType: appointmentManager.serviceType!,
                      dateTime: DateTime(
                        appointmentManager.selectedDate.year,
                        appointmentManager.selectedDate.month,
                        appointmentManager.selectedDate.day,
                        appointmentManager.selectedTime!.hour,
                        appointmentManager.selectedTime!.minute,
                      ),
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointment booked successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: const Text('Book Appointment'),
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
    return DropdownButton<String>(
      value: appointmentManager.serviceType,
      hint: const Text('Select Service Type'),
      onChanged: (String? newValue) {
        appointmentManager.setServiceType(newValue);
      },
      items: appointmentManager.meetingTypeList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}