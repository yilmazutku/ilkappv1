import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';

class AppointmentManager extends ChangeNotifier {
  final Logger logger = Logger.forClass(AppointmentManager);


  // Fetch Appointments
  Future<List<AppointmentModel>> fetchAppointments(String? subscriptionId,
      {required bool showAllAppointments, required String userId}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .orderBy('appointmentDateTime', descending: false);

      if (!showAllAppointments && subscriptionId != null) {
        query =
            query.where('subscriptionId', isEqualTo: subscriptionId);
      }

      QuerySnapshot snapshot = await query.get();

      List<AppointmentModel> appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info('Appointments fetched successfully.');

      return appointments;
    } catch (e, s) {
      logger.err('Error fetching app2ointments: {}', [s]);
      return [];
    }
  }

  // Fetch appointments for a specific date to determine available time slots
  Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
    try {
      // Fetch available times from Firebase
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      DocumentSnapshot timeslotDoc = await FirebaseFirestore.instance
          .collection('admininput')
          .doc('timeslots')
          .collection('dates')
          .doc(dateString)
          .get();

      if (!timeslotDoc.exists) {
        // No available times for the date
        logger.info('No available times for date {}', [dateString]);
        return [];
      }

      Map<String, dynamic> data = timeslotDoc.data() as Map<String, dynamic>;
      List<dynamic> timesList = data['times'] ?? [];

      // Convert timesList to List<TimeOfDay>
      List<TimeOfDay> availableTimes = timesList.map<TimeOfDay>((timeString) {
        // Assume timeString is in format 'HH:mm'
        List<String> parts = timeString.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }).toList();

      // Fetch appointments already booked for that date
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDateTime', isLessThan: endOfDay)
          .get();

      List<AppointmentModel> dayAppointments = appointmentSnapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      // Filter out times that are already booked
      availableTimes = availableTimes.where((time) {
        return isTimeSlotAvailable(date, time, dayAppointments);
      }).toList();

      logger.info(
          'Available times for date {}: {}', [dateString, availableTimes]);

      return availableTimes;
    } catch (e) {
      logger.err('Error fetching available times for date {}: {}', [date, e]);
      return [];
    }
  }


  // Fetch appointments for a specific date to determine available time slots
  // Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
  //   DateTime startOfDay = DateTime(date.year, date.month, date.day);
  //   DateTime endOfDay = startOfDay.add(const Duration(days: 1));
  //
  //   try {
  //     QuerySnapshot snapshot = await FirebaseFirestore.instance
  //         .collectionGroup('appointments')
  //         .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
  //         .where('appointmentDateTime', isLessThan: endOfDay)
  //         .get();
  //
  //     List<AppointmentModel> dayAppointments = snapshot.docs
  //         .map((doc) => AppointmentModel.fromDocument(doc))
  //         .toList();
  //
  //     logger.info('Appointments for date {}/{}/{} fetched successfully.', [date.day, date.month, date.year]);
  //
  //     List<TimeOfDay> availableSlots = [];
  //     for (int hour = 9; hour < 19; hour++) {
  //       for (int minute = 0; minute < 60; minute += 30) {
  //         TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
  //         if (isTimeSlotAvailable(date, time, dayAppointments)) {
  //           availableSlots.add(time);
  //         }
  //       }
  //     }
  //     return availableSlots;
  //   } catch (e) {
  //     logger.err('Error fetching appointments for date {}: {}', [date, e]);
  //     return [];
  //   }
  // }

  // Check if a time slot is available
  bool isTimeSlotAvailable(DateTime date, TimeOfDay time, List<AppointmentModel>? dayAppointments) {
    DateTime dateTimeWithHour =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Check if the time slot is in the past
    if (dayAppointments != null) {
    if (dateTimeWithHour.isBefore(DateTime.now())) return false;
      for (var appointment in dayAppointments!) {
        // appt book etmeden once cagirilirsa diye
        if (appointment.appointmentDateTime == dateTimeWithHour &&
            appointment.status != AppointmentStatus.canceled) {
          return false;
        }
      }
    }
    return true;
  }
//TODO add appt oncesiş de i ss lot availabel check yapak
  // Add a new appointment
  Future<void> addAppointment(AppointmentModel appointment) async {
    try {
      // Save to user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(appointment.userId)
          .collection('appointments')
          .doc(appointment.appointmentId)
          .set(appointment.toMap());

      logger.info('Appointment added successfully: {}', [appointment]);
    } catch (e) {
      logger.err('Error adding appointment: {}', [e]);
      throw Exception('Error adding appointment.');
    }
  }

  // Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId, String userId,
      {required String canceledBy}) async {
    try {
      // Update in user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': AppointmentStatus.canceled.label,
        'canceledBy': canceledBy,
        'canceledAt': Timestamp.now(),
      });

      logger.info('Appointment canceled successfully by {}.', [canceledBy]);
      return true;
    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      return false;
    }
  }

  // Update an existing appointment
  Future<void> updateAppointment(AppointmentModel updatedAppointment) async {
    try {
      // Update in user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedAppointment.userId)
          .collection('appointments')
          .doc(updatedAppointment.appointmentId)
          .update(updatedAppointment.toMap());

      logger.info('Appointment updated successfully: {}', [updatedAppointment]);
    } catch (e) {
      logger.err('Error updating appointment: {}', [e]);
      throw Exception('Error updating appointment.');
    }
  }
}
