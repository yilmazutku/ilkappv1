// import 'dart:js';

import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Appointment {
  String id;
  String name;
  String serviceType; // 'online' or 'face-to-face'
  DateTime date;

  // String date;
  // String time;
  TimeOfDay time;

  Appointment({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.date,
    required this.time,
  });

  // Convert a Appointment into a Map. The keys must correspond to the names of the fields in Firestore.
  // Map<String, dynamic> toJson(BuildContext context) => {
  //   'id': id,
  //   'name': name,
  //   'serviceType': serviceType,
  //   'date': date.toString(),
  //   // 'time': time.format(context).toString(), // context is needed to format the time
  //   'time': time.format(context).toString(), // context is needed to format the time
  //
  // };
  Map<String, dynamic> toJson(BuildContext context) => {
        'id': id,
        'name': name,
        'serviceType': serviceType,
        'date': date,
        //.toIso8601String(), // Convert DateTime to ISO 8601 string
        'time': '${time.hour}:${time.minute}',
        // Convert TimeOfDay to a string in HH:mm format
      };

  // A method that retrieves all the data from Firestore and converts it to an Appointment object.
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'],
        name: json['name'],
        serviceType: json['serviceType'],
        date: (json['date'] as Timestamp).toDate(),
        time: TimeOfDay(
            hour: int.parse(json['time'].split(':')[0]),
            minute: int.parse(json['time'].split(':')[1])),
      );

  TimeOfDay getTime() {
    return time;
  }
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _nameController = TextEditingController();
  String? _serviceType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  List<TimeOfDay> _availableTimes = []; // Times will be fetched based on the selected date

  // This will hold the unavailable times
  Set<TimeOfDay> _unavailableTimes = {};
  Set <Appointment> appointments= {};
  @override
  void initState() {
    super.initState();

    fetchAppointments();
  }

  // Fetch appointments from Firestore and determine unavailable times
  Future<void> fetchAppointments() async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('appointment');

    // Get docs from collection reference
    QuerySnapshot querySnapshot = await collectionRef.get();

    _unavailableTimes.clear();

    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      if (data is Map<String, dynamic>) {
        // Check if data is a Map
        Appointment appointment = Appointment.fromJson(data);

        // If the appointment date is the same as the selected date, mark the time as unavailable
        if (appointment.date == _selectedDate) {

          _unavailableTimes.add(appointment.time);
        }
      }
    }

    // Now, refresh the available times
    refreshAvailableTimes();
  }

  // Refresh available times by removing the unavailable times from the full time slots list
  void refreshAvailableTimes() {
    List<TimeOfDay> times = [];
    for (int i = 9; i <= 17; i++) {
      TimeOfDay time = TimeOfDay(hour: i, minute: 0);
      if (!_unavailableTimes.contains(time)) {
        times.add(time);
      }
      time = TimeOfDay(hour: i, minute: 30);
      if (!_unavailableTimes.contains(time)) {
        times.add(time);
      }
    }

    setState(() {
      _availableTimes = times;
    });
  }

  // Future<void> getData() async {
  //   CollectionReference collectionRef =
  //   FirebaseFirestore.instance.collection('appointment');
  //   // Get docs from collection reference
  //   QuerySnapshot querySnapshot = await collectionRef.get();
  //   List<TimeOfDay> times = [];
  //   // Get data from docs and convert map to List
  //   final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  //   querySnapshot.docs.map((doc) => doc.data()).toList();
  //   for(int i=0; i<allData.length;i++) {
  //     Appointment? e = Appointment.fromJson(allData[i] );
  //     times.add(e!.getTime());
  //   }
  //   print(allData);
  //   print(times);
  // }
  fetchAvailableTimes() async {
    // Fetch times from Firebase and update _availableTimes and the UI accordingly
    // For demonstration, let's assume the work hours are from 9 AM to 5 PM
    List<TimeOfDay> times = [];
    for (int i = 9; i <= 17; i++) {
      times.add(TimeOfDay(hour: i, minute: 0));
      times.add(TimeOfDay(hour: i, minute: 30));
    }

    // Check Firestore for appointments on the selected day and mark those times as unavailable
    // ...
    // await getData();
    setState(() {
      _availableTimes = times;
    });
  }

  @override
  Widget build(BuildContext context) {
    var list = <String>['Online', 'Face-to-Face'];
    return Scaffold(
      appBar: AppBar(title: Text('Book Appointment')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _serviceType,
                hint: const Text('Select Service Type'),
                items: list.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _serviceType = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                    "Select Date: ${_selectedDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      // fetchAvailableTimes(); // Fetch new available times for the selected date
                    });
                    await fetchAppointments();
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                children: _availableTimes.map((time) {
                  return ChoiceChip(
                    label: Text(time.format(context)),
                    selected: _selectedTime == time, //tıklanmış olma durumunu neye göre tanımladığımızı tutuyor.
                    onSelected: (bool selected) { //false ise tıklanmamış şekilde renderlanıp ui'a katılacaklar.
                      setState(() {
                        _selectedTime = selected ? time : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Validation checks
                  if (_nameController.text.isEmpty ||
                      _serviceType == null ||
                      _selectedTime == null) {
                    // Show error
                    return;
                  }
                  // Create a new Appointment instance
                  var user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // User is signed in
                    print('User is signed in!');
                  } else {
                    // No user is signed in
                    print('No user is signed in.');
                  }

                  Appointment newAppointment = Appointment(
                    //   id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique id based on the current time
                    id: FirebaseAuth.instance.currentUser!.uid,
                    // Assuming the user is logged in
                    name: _nameController.text,
                    serviceType: _serviceType!,
                    date: _selectedDate,
                    time: _selectedTime!,
                  );
                  // print(newAppointment.toJson(context));
                  // Save the appointment to Firestore
                  FirebaseFirestore.instance
                      .collection('appointment')
                      .doc('${newAppointment.id}2')
                      // .doc('/asd')
                      .set(newAppointment.toJson(context)).then((_) {
                    // After successfully creating an appointment, refresh the available times
                    fetchAppointments();
                  }).catchError((error) {
                    // Handle any errors here
                  });
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
