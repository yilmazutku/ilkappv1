import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../commons/common.dart';
import '../commons/logger.dart';
import '../commons/userclass.dart';

final Logger logger = Logger.forClass(AppointmentManager);

class AppointmentManager extends ChangeNotifier {
  final Map<DateTime, List<AppointmentModel>> _dailyAppointments = {};

  DateTime _selectedDate = DateTime.now(); // Tracks the selected date
  final ValueNotifier<MeetingType> _meetingTypeNotifier =
  ValueNotifier<MeetingType>(MeetingType.f2f); // Default value: f2f
  final ValueNotifier<TimeOfDay?> _selectedTimeNotifier =
  ValueNotifier<TimeOfDay?>(null);

  ValueNotifier<MeetingType> get meetingTypeNotifier => _meetingTypeNotifier;

  DateTime get selectedDate => _selectedDate;

  ValueNotifier<TimeOfDay?> get selectedTimeNotifier => _selectedTimeNotifier;

  void setMeetingType(MeetingType? newValue) {
    if (newValue != null) {
      _meetingTypeNotifier.value = newValue;
      notifyListeners();
    }
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    logger.info('Updated selected date: {}', [date]);
    await fetchAppointments(selectedDate: _selectedDate);
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay? time) {
    _selectedTimeNotifier.value = time;
  }

  Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
    logger.info('Getting available time slots for date: {}', [date]);
    await fetchAppointments(selectedDate: date);
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

  Future<List<AppointmentModel>> fetchCurrentUserAppointments(
      String userId) async {
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('appointments');

    final querySnapshot = await collectionRef.get();
    List<AppointmentModel> userAppointments = [];

    for (var doc in querySnapshot.docs) {
      AppointmentModel appointment = AppointmentModel.fromDocument(doc);
      if (!appointment.appointmentDateTime.isBefore(DateTime.now())) {
        userAppointments.add(appointment);
      }
    }

    return userAppointments;
  }

  Future<void> fetchAppointments({DateTime? selectedDate}) async {
    Query query = FirebaseFirestore.instance.collectionGroup('appointments');

    if (selectedDate != null) {
      DateTime startOfDay =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      query = query.where('appointmentDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          isLessThan: Timestamp.fromDate(endOfDay));
    }

    final snapshot = await query.get();

    _dailyAppointments.clear();
    for (var doc in snapshot.docs) {
      AppointmentModel appointment = AppointmentModel.fromDocument(doc);
      DateTime date = DateTime(
          appointment.appointmentDateTime.year,
          appointment.appointmentDateTime.month,
          appointment.appointmentDateTime.day);
      if (!_dailyAppointments.containsKey(date)) {
        _dailyAppointments[date] = [];
      }
      _dailyAppointments[date]!.add(appointment);
    }
  }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    bool isAvailable = isTimeSlotAvailable(
      appointment.appointmentDateTime,
      TimeOfDay.fromDateTime(appointment.appointmentDateTime),
    );
    if (isAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(appointment.userId)
            .collection('appointments')
            .doc(appointment.appointmentId)
            .set(appointment.toMap());
        await fetchAppointments();
        notifyListeners();
      } catch (error) {
        logger.err('Error booking appointment: {}', [error]);
        throw Exception('Error booking appointment.');
      }
    } else {
      throw Exception('Selected time slot is not available.');
    }
  }

  bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
    DateTime dateTimeWithHour =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    for (var appointment in _dailyAppointments[date] ?? []) {
      if (appointment.appointmentDateTime == dateTimeWithHour) {
        return false;
      }
    }
    return true;
  }

  Future<void> cancelAppointment(String userId, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      logger.info('Appointment with id={} has been canceled.', [appointmentId]);

      await fetchAppointments();
      notifyListeners();
    } catch (error) {
      logger.err('Error while canceling appointment with id={}: {}',
          [appointmentId, error]);
      throw Exception('Error canceling appointment.');
    }
  }
}
