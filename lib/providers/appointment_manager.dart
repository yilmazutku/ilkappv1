import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';

class AppointmentManager extends ChangeNotifier {
  final Logger logger = Logger.forClass(AppointmentManager);

  String? _selectedSubscriptionId;

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
  }

  // Fetch Appointments
  Future<List<AppointmentModel>> fetchAppointments({required bool showAllAppointments, required String userId}) async {

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .orderBy('appointmentDateTime', descending: false);

      if (!showAllAppointments && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      QuerySnapshot snapshot = await query.get();

      List<AppointmentModel> appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info('Appointments fetched successfully.');

      return appointments;
    } catch (e) {
      logger.err('Error fetching appointments: {}', [e]);
      return [];
    }
  }

  // Fetch appointments for a specific date to determine available time slots
  Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDateTime', isLessThan: endOfDay)
          .get();

      List<AppointmentModel> dayAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info('Appointments for date {}/{}/{} fetched successfully.', [date.day, date.month, date.year]);

      List<TimeOfDay> availableSlots = [];
      for (int hour = 9; hour < 19; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
          if (isTimeSlotAvailable(date, time, dayAppointments)) {
            availableSlots.add(time);
          }
        }
      }
      return availableSlots;
    } catch (e) {
      logger.err('Error fetching appointments for date {}: {}', [date, e]);
      return [];
    }
  }

  // Check if a time slot is available
  bool isTimeSlotAvailable(DateTime date, TimeOfDay time, List<AppointmentModel> dayAppointments) {
    DateTime dateTimeWithHour =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (dayAppointments != null) { // appt book etmeden once cagirilirsa diye
      for (var appointment in dayAppointments) {
        if (appointment.appointmentDateTime == dateTimeWithHour &&
            appointment.status != MeetingStatus.canceled) {
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
  Future<bool> cancelAppointment(String appointmentId, String userId, {required String canceledBy}) async {
    try {
      // Update in user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': MeetingStatus.canceled.label,
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
