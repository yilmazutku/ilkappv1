import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../commons/common.dart';
import '../commons/logger.dart';

final Logger logger = Logger.forClass(AppointmentManager);

class AppointmentManager extends ChangeNotifier {
  final Map<DateTime, List<Appointment>> _dailyAppointments = {};

  final List<MeetingType> meetingTypeList = MeetingType.values; // Use the enum directly

  Map<DateTime, List<Appointment>> get dailyAppointments => _dailyAppointments;

  DateTime _selectedDate = DateTime.now(); // Tracks the selected date
  final ValueNotifier<MeetingType> _meetingTypeNotifier = ValueNotifier<MeetingType>(MeetingType.f2f); // Default value: f2f
  final ValueNotifier<TimeOfDay?> _selectedTimeNotifier = ValueNotifier<TimeOfDay?>(null);

  ValueNotifier<MeetingType> get meetingTypeNotifier => _meetingTypeNotifier; // Use MeetingType instead of String

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
    logger.info('updatedSelectedDate as {}', [date]);
    await fetchAppointments(selectedDate: _selectedDate);
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay? time) {
    _selectedTimeNotifier.value = time;
  }

  Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
    logger.info('gettingAvailableTimeSlots for date={}', [date]);
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

  Future<List<Appointment>> fetchCurrentUserAppointments(String userId) async {
    CollectionReference collectionRef = FirebaseFirestore.instance.collection('appointments');
    QuerySnapshot querySnapshot = await collectionRef.where('id', isEqualTo: userId).get();
    List<Appointment> userAppointments = [];

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        Appointment appointment = Appointment.fromJson(doc.data() as Map<String, dynamic>);
        if (!appointment.dateTime.isBefore(DateTime.now())) {
          userAppointments.add(appointment);
        }
      }
    }
    return userAppointments;
  }

  Future<void> fetchAppointments({DateTime? selectedDate}) async {
    CollectionReference collectionRef = FirebaseFirestore.instance.collection('appointments');
    QuerySnapshot? querySnapshot;

    if (selectedDate == null) {
      querySnapshot = await collectionRef.get();
    } else {
      DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0);
      DateTime endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59);
      querySnapshot = await collectionRef
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay, isLessThanOrEqualTo: endOfDay)
          .get();
    }

    _dailyAppointments.clear();
    for (var doc in querySnapshot.docs) {
      Appointment appointment = Appointment.fromJson(doc.data() as Map<String, dynamic>);
      DateTime date = DateTime(appointment.dateTime.year, appointment.dateTime.month, appointment.dateTime.day);
      if (!_dailyAppointments.containsKey(date)) {
        _dailyAppointments[date] = [];
      }
      _dailyAppointments[date]!.add(appointment);
    }
  }

  Future<void> bookAppointment(Appointment appointment) async {
    bool isAvailable = isTimeSlotAvailable(appointment.dateTime, TimeOfDay.fromDateTime(appointment.dateTime));
    if (isAvailable) {
      try {
        await FirebaseFirestore.instance.collection('appointments').doc(appointment.id).set(appointment.toJson());
        fetchAppointments();
        notifyListeners();
      } catch (error) {
        logger.err('Error booking appointment:{}', [error]);
      }
    }
  }

  bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
    DateTime dateTimeWithHour = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    for (var appointment in _dailyAppointments[DateTime(date.year, date.month, date.day)] ?? []) {
      if (appointment.dateTime == dateTimeWithHour) {
        return false;
      }
    }
    return true;
  }


  Future<void> cancelAppointment(String id) async {
    try {
      // Remove the appointment from Firestore using its id
      await FirebaseFirestore.instance.collection('appointments').doc(id).delete();

      // Log success
      logger.info('Appointment with id={} has been canceled.', [id]);

      // Optionally, refresh the appointments list after cancellation
      await fetchAppointments(); // Assuming fetchAppointments refreshes the list

      notifyListeners(); // Notify listeners to update the UI after cancellation
    } catch (error) {
      // Log error if something goes wrong
      logger.err('Error while canceling appointment with id={}: {}', [id, error]);
    }
  }

}
