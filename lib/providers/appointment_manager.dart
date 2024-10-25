// providers/appointment_manager.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

import '../models/logger.dart';
import '../models/subs_model.dart';
import '../tabs/basetab.dart';

final Logger logger = Logger.forClass(AppointmentManager);

class AppointmentManager extends ChangeNotifier with Loadable {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;

  String? _userId;
  String? _selectedSubscriptionId;
  bool _showAllAppointments = false;

  DateTime _selectedDate = DateTime.now();
  final ValueNotifier<MeetingType> _meetingTypeNotifier =
  ValueNotifier<MeetingType>(MeetingType.f2f);
  final ValueNotifier<TimeOfDay?> _selectedTimeNotifier =
  ValueNotifier<TimeOfDay?>(null);

  @override
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  ValueNotifier<MeetingType> get meetingTypeNotifier => _meetingTypeNotifier;
  ValueNotifier<TimeOfDay?> get selectedTimeNotifier => _selectedTimeNotifier;

  List<AppointmentModel> get appointments => _appointments;
  bool get showAllAppointments => _showAllAppointments;

  AppointmentManager();

  void setUserId(String userId) {
    _userId = userId;
    fetchAppointments();
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
    fetchAppointments();
  }

  void setShowAllAppointments(bool value) {
    _showAllAppointments = value;
    fetchAppointments();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay? time) {
    _selectedTimeNotifier.value = time;
  }

  void setMeetingType(MeetingType? newValue) {
    if (newValue != null) {
      _meetingTypeNotifier.value = newValue;
    }
  }

  Future<void> fetchAppointments() async {
    if (_userId == null) return;

    _isLoading = true;
    // notifyListeners();

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .orderBy('appointmentDateTime', descending: true);

      if (!_showAllAppointments && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      _appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();
    } catch (e) {
      logger.err('Error fetching appointments: {}', [e]);
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
    if (_userId == null) return;

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('appointmentDateTime', isLessThan: endOfDay);

    final snapshot = await query.get();

    _appointments = snapshot.docs
        .map((doc) => AppointmentModel.fromDocument(doc))
        .toList();
  }

  bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
    DateTime dateTimeWithHour =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    for (var appointment in _appointments) {
      if (appointment.appointmentDateTime == dateTimeWithHour) {
        return false;
      }
    }
    return true;
  }

  Future<SubscriptionModel?> getCurrentSubscription() async {
    if (_userId == null) return null;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SubscriptionModel.fromDocument(snapshot.docs.first);
      }
    } catch (e) {
      logger.err('Error fetching current subscription: {}', [e]);
    }
    return null;
  }

  Future<void> bookAppointmentForCurrentUser() async {
    if (_userId == null || _selectedSubscriptionId == null) {
      throw Exception('User ID or Subscription ID is not set.');
    }

    if (_selectedTimeNotifier.value == null) {
      throw Exception('Please select a time slot.');
    }

    DateTime appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTimeNotifier.value!.hour,
      _selectedTimeNotifier.value!.minute,
    );

    bool isAvailable = isTimeSlotAvailable(_selectedDate, _selectedTimeNotifier.value!);

    if (!isAvailable) {
      throw Exception('Selected time slot is not available.');
    }

    try {
      String appointmentId = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .doc()
          .id;

      AppointmentModel appointment = AppointmentModel(
        appointmentId: appointmentId,
        userId: _userId!,
        subscriptionId: _selectedSubscriptionId!,
        meetingType: _meetingTypeNotifier.value,
        appointmentDateTime: appointmentDateTime,
        status: MeetingStatus.scheduled,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .doc(appointmentId)
          .set(appointment.toMap());

      _appointments.insert(0, appointment);

      logger.info('Appointment booked successfully.');

      notifyListeners();
    } catch (e) {
      logger.err('Error booking appointment: {}', [e]);
      throw Exception('Error booking appointment.');
    }
  }

  Future<List<AppointmentModel>> fetchCurrentUserAppointments() async {
    if (_userId == null) return [];

    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('appointments');

    final querySnapshot = await collectionRef
        .orderBy('appointmentDateTime', descending: false)
        .get();

    List<AppointmentModel> userAppointments = [];

    for (var doc in querySnapshot.docs) {
      AppointmentModel appointment = AppointmentModel.fromDocument(doc);
      if (!appointment.appointmentDateTime.isBefore(DateTime.now())) {
        userAppointments.add(appointment);
      }
    }

    return userAppointments;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    if (_userId == null) {
      throw Exception('User ID is not set.');
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      _appointments.removeWhere((a) => a.appointmentId == appointmentId);

      logger.info('Appointment canceled successfully.');

      notifyListeners();
    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      throw Exception('Error canceling appointment.');
    }
  }
}
