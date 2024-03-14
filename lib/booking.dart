import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'managers/appointment_manager.dart';
import 'commons/common.dart';

final auth = FirebaseAuth.instance;

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final meetingTypeList = MeetingType.values.map((e) => e.name).toList();
  // final _nameController = TextEditingController(); // daha sonra eklenebilir kayıtlı olmayan kullanıcılar için
  String? _serviceType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  void setSelectedTime(bool selected, TimeOfDay time) {
    print('selectedTime= $time');
    _selectedTime = selected ? time : null;
  }

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
              ServiceTypeDropdown(
                selectedServiceType: _serviceType,
                serviceTypeList: meetingTypeList,
                onServiceTypeChanged: (newValue) => _serviceType = newValue,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                //TODO belki isim yazabilir ayların
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                   await appointmentManager.updateSelectedDate(picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Display available time slots
              FutureBuilder<List<TimeOfDay>>(
                future: appointmentManager.getAvailableTimeSlots(_selectedDate),
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
                          selected: _selectedTime == time,
                          onSelected: (bool selected) {
                            setState(() {
                              setSelectedTime(selected, time);
                            });
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
                  if (/*_nameController.text.isEmpty ||*/
                      _serviceType == null ||
                      _selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }
                  DateTime finalDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );

                  Appointment newAppointment = Appointment(
                    id: auth.currentUser!.uid,
                    // This might be replaced with a more appropriate ID generation strategy
                    name: /*_nameController.text*/'TODO',
                    serviceType: _serviceType!,
                    dateTime: finalDateTime,
                  );

                  await appointmentManager.bookAppointment(newAppointment);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Appointment booked successfully")),
                  );
                },
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*
  Here's a summary of how this setup works:

Dropdown for Service Type: Allows the user to select the type of meeting (e.g., online or face-to-face) from a dropdown list.

Date Picker: Lets the user pick a date for the appointment. Upon selecting a date, it updates the selectedDate in the AppointmentManager, which, in turn, can trigger fetching of available time slots for that date.

FutureBuilder for Time Slots: Utilizes a FutureBuilder to asynchronously fetch and display available time slots based on the selected date. It shows a loading indicator while fetching and provides options for the user to select a time slot.

Booking Button: Upon clicking, it validates the input fields, creates a new Appointment object with the selected details, and calls bookAppointment on the AppointmentManager to save the appointment. If successful, it displays a confirmation message.

This architecture helps to keep your UI code clean and maintainable, facilitating easy updates or changes to the state management logic without requiring significant changes to your UI code.
   */
}

class ServiceTypeDropdown extends StatefulWidget {
  final String? selectedServiceType;
  final List<String> serviceTypeList;
  final Function(String?) onServiceTypeChanged;

  const ServiceTypeDropdown({
    super.key,
    required this.selectedServiceType,
    required this.serviceTypeList,
    required this.onServiceTypeChanged,
  });

  @override
  createState() => _ServiceTypeDropdownState();
}

class _ServiceTypeDropdownState extends State<ServiceTypeDropdown> {
  String? _serviceType;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.selectedServiceType;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _serviceType,
      hint: const Text('Select Service Type'),
      onChanged: (String? newValue) {
        if (newValue != _serviceType) {
          setState(() {
            print('Building ServiceTypeDropdown widget... ');
            _serviceType = newValue;
          });
          widget.onServiceTypeChanged(
              newValue); // Notify the parent widget of the change
        }
      },
      items:
          widget.serviceTypeList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
