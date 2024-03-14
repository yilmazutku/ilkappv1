import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../commons/common.dart';

class AppointmentManager extends ChangeNotifier {
  final Map<DateTime, List<Appointment>> _dailyAppointments = {};

  Map<DateTime, List<Appointment>> get dailyAppointments => _dailyAppointments;

  DateTime _selectedDate = DateTime.now(); // Tracks the selected date

  Future<void> updateSelectedDate(DateTime newDate) async {
    print('updatedSelectedDate=$newDate');
    _selectedDate = newDate;
    await fetchAppointments(
        selectedDate:
            _selectedDate); // Fetch appointments for the week of the new selected date
    notifyListeners(); // Notify listeners to rebuild widgets if necessary
  }

  /**
   * belirli bir gün için müsait saatleri bulur
   */
  Future<List<TimeOfDay>> getAvailableTimeSlots(DateTime date) async {
    print('gettingAvailableTimeSlots for=$date');
    await fetchAppointments(
        selectedDate: date); // Make sure the appointments are up to date
    List<TimeOfDay> availableSlots = [];

    // Example: Assuming appointments can be booked from 9 AM to 5 PM, every half hour
    for (int hour = 9; hour < 17; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
        if (isTimeSlotAvailable(date, time)) {
          availableSlots.add(time);
        }
      }
    }

    return availableSlots;
  }

  Future<void> fetchAppointments({DateTime? selectedDate}) async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(Constants.appointments);
    // QuerySnapshot querySnapshot = await collectionRef.get();
    QuerySnapshot? querySnapshot;
    if (selectedDate == null) {
      //admin çağırmış
      querySnapshot = await collectionRef.get();
    } else {
      //user çağırmış, günlük saatleri dolduracak
      querySnapshot =
          await collectionRef.where('dateTime', isEqualTo: selectedDate).get();
    }
    /*
  // Query for appointments within the specified date range
  QuerySnapshot querySnapshot = await collectionRef
      .where('dateTime', isGreaterThanOrEqualTo: startTimestamp)
      .where('dateTime', isLessThanOrEqualTo: endTimestamp)
      .get();
     */
    _dailyAppointments.clear();
    for (var doc in querySnapshot.docs) {
      Appointment appointment =
          Appointment.fromJson(doc.data() as Map<String, dynamic>);
      // DateTime date = appointment.dateTime;
      DateTime date = DateTime(appointment.dateTime.year,
          appointment.dateTime.month, appointment.dateTime.day);
      if (!_dailyAppointments.containsKey(date)) {
        _dailyAppointments[date] = [];
      }
      _dailyAppointments[date]!.add(appointment);
    }
  }

  Future<void> bookAppointment(Appointment appointment) async {
    bool isAvailable = isTimeSlotAvailable(
        appointment.dateTime, TimeOfDay.fromDateTime(appointment.dateTime));
    if (isAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection(Constants.appointments)
            .doc('${appointment.id}35')
            .set(appointment.toJson());
        fetchAppointments(); // Refresh the appointments after a new booking
        notifyListeners();
      } catch (error) {
        print("Error booking appointment: $error");
      }
    } else {
      print('selected date is not available.');
    }
  }

  bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
    // Convert TimeOfDay to DateTime for comparison
    DateTime dateYmd = //year month day
        DateTime(date.year, date.month, date.day);
    DateTime dateTimeWithHour =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    for (var appointment in _dailyAppointments[dateYmd] ?? []) {
      if (appointment.dateTime == dateTimeWithHour) {
        return false; // Slot is not available
      }
    }
    return true; // Slot is available
  }
}
