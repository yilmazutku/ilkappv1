import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'commons/common.dart';

class AppointmentManager extends ChangeNotifier {
  Map<DateTime, List<Appointment>> weeklyAppointments = {};

  Future<void> fetchAppointmentsForWeek() async {
    CollectionReference collectionRef =
    FirebaseFirestore.instance.collection(Constants.adminAppointments);
    QuerySnapshot querySnapshot = await collectionRef.get();

    weeklyAppointments.clear();
    for (var doc in querySnapshot.docs) {
      Appointment appointment =
      Appointment.fromJson(doc.data() as Map<String, dynamic>);
      DateTime date = appointment.dateTime;
      if (!weeklyAppointments.containsKey(date)) {
        weeklyAppointments[date] = [];
      }
      weeklyAppointments[date]!.add(appointment);
    }
    notifyListeners(); // Notify listeners that the data has been updated
  }

// Add any other methods you need to manage the appointments
}
