import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../tabs/basetab.dart';

class AppointmentManager extends ChangeNotifier with Loadable {
  final Logger logger = Logger.forClass(AppointmentManager);

  List<AppointmentModel> _userAppointments = [];
  List<AppointmentModel> _dayAppointments = [];
  bool _isLoading = false;

  String? _userId;


  // Getters
  List<AppointmentModel> get appointments => _userAppointments;
  String? get userId => _userId;
  @override
  bool get isLoading => _isLoading;

  AppointmentManager();

  void setUserId(String userId) {
    _userId = userId;
    fetchUserAppointments();
  }



  Future<void> fetchUserAppointments() async {
    if (_userId == null) return;

    _isLoading = true;
    //notifyListeners();

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .orderBy('appointmentDateTime', descending: false)
          .get();

      _userAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info('User appointments fetched successfully.');
    } catch (e) {
      logger.err('Error fetching user appointments: {}', [e]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
    await fetchAppointmentsForDate(date);
    List<TimeOfDay> availableSlots = [];

    for (int hour = 9; hour < 19; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
        if (isTimeSlotAvailable(date, time)) {
          availableSlots.add(time);
        }
      }
    }
    return availableSlots;
  }

  Future<void> fetchAppointmentsForDate(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      Query query = FirebaseFirestore.instance
          .collection('appointments')
          .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDateTime', isLessThan: endOfDay);

      final snapshot = await query.get();

      _dayAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info(
          'Appointments for date {}/{}/{} fetched successfully.', [date.day, date.month, date.year]);
    } catch (e) {
      logger.err('Error fetching appointments for date {}: {}', [date, e]);
    } finally {
      notifyListeners();
    }
  }

  bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
    DateTime dateTimeWithHour =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    for (var appointment in _dayAppointments) {
      if (appointment.appointmentDateTime == dateTimeWithHour &&
          appointment.status != MeetingStatus.canceled) {
        return false;
      }
    }
    return true;
  }

  Future<void> addAppointment(AppointmentModel appointment) async {
    try {
      // Save to user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(appointment.userId)
          .collection('appointments')
          .doc(appointment.appointmentId)
          .set(appointment.toMap());

      // Save to top-level appointments collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.appointmentId)
          .set(appointment.toMap());

      _userAppointments.add(appointment);

      logger.info('Appointment added successfully: {}', [appointment]);
      notifyListeners();
    } catch (e) {
      logger.err('Error adding appointment: {}', [e]);
      throw Exception('Error adding appointment.');
    }
  }

  Future<void> cancelAppointment(String appointmentId, {required String canceledBy}) async {
    if (_userId == null) {
      throw Exception('User ID is not set.');
    }

    try {
      // Update in user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': MeetingStatus.canceled.label,
        'canceledBy': canceledBy,
        'canceledAt': Timestamp.now(),
      });

      // Update in top-level appointments collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': MeetingStatus.canceled.label,
        'canceledBy': canceledBy,
        'canceledAt': Timestamp.now(),
      });

      // Update local list
      int index = _userAppointments.indexWhere((a) => a.appointmentId == appointmentId);
      if (index != -1) {
        _userAppointments[index].status = MeetingStatus.canceled;
        _userAppointments[index].canceledBy = canceledBy;
        _userAppointments[index].canceledAt = DateTime.now();
      }

      logger.info('Appointment canceled successfully by {}.', [canceledBy]);

    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      throw Exception('Error canceling appointment.');
    }
    finally {
      notifyListeners();
    }
  }

  Future<void> updateAppointment(AppointmentModel updatedAppointment) async {
    try {
      // Update in user's appointments subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedAppointment.userId)
          .collection('appointments')
          .doc(updatedAppointment.appointmentId)
          .update(updatedAppointment.toMap());

      // Update in top-level appointments collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(updatedAppointment.appointmentId)
          .update(updatedAppointment.toMap());

      // Update local list
      int index = _userAppointments.indexWhere(
              (a) => a.appointmentId == updatedAppointment.appointmentId);
      if (index != -1) {
        _userAppointments[index] = updatedAppointment;
      }

      logger.info('Appointment updated successfully: {}', [updatedAppointment]);

    } catch (e) {
      logger.err('Error updating appointment: {}', [e]);
      throw Exception('Error updating appointment.');
    }
    finally {
      notifyListeners();
    }
  }

  void setSelectedSubscriptionId(String newValue) {

  }
}
