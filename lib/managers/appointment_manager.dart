// appointment_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Future<List<AppointmentModel>> fetchCurrentUserAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.err('User not authenticated.');
      return [];
    }

    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
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

  Future<void> fetchAppointments({DateTime? selectedDate}) async {
    Query query = FirebaseFirestore.instance.collectionGroup('appointments');

    if (selectedDate != null) {
      DateTime startOfDay =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

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

  Future<void> bookAppointmentForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.err('User not authenticated.');
      throw Exception('User not authenticated.');
    }

    final subscription = await getCurrentSubscription();
    if (subscription == null) {
      throw Exception('No active subscription found.');
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

    bool isAvailable = isTimeSlotAvailable(
      _selectedDate,
      _selectedTimeNotifier.value!,
    );

    if (!isAvailable) {
      throw Exception('Selected time slot is not available.');
    }

    try {
      final appointmentId = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .doc()
          .id;

      AppointmentModel appointment = AppointmentModel(
        appointmentId: appointmentId,
        userId: user.uid,
        subscriptionId: subscription.subscriptionId,
        meetingType: _meetingTypeNotifier.value,
        appointmentDateTime: appointmentDateTime,
        status: MeetingStatus.scheduled,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .doc(appointmentId)
          .set(appointment.toMap());

      // Update the subscription's meetingsRemaining
      //BEN: NO, ADMIN ONAYIYLA OLMALI. TODO
      // subscription.meetingsRemaining -= 1;
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(user.uid)
      //     .collection('subscriptions')
      //     .doc(subscription.subscriptionId)
      //     .update({
      //   'meetingsRemaining': subscription.meetingsRemaining,
      // });

      await fetchAppointments();
      notifyListeners();
    } catch (error) {
      logger.err('Error booking appointment: {}', [error]);
      throw Exception('Error booking appointment.');
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

  Future<void> cancelAppointment(String appointmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.err('User not authenticated.');
      throw Exception('User not authenticated.');
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      logger.info('Appointment with id={} has been canceled.', [appointmentId]);

      // Optionally, you might want to update the subscription's meetingsRemaining
      //BEN: NO, ADMIN TARAFININ GUNCELLEMESIYLE OLMALI. TODO
      // final subscription = await getCurrentSubscription();
      // if (subscription != null) {
      //   subscription.meetingsRemaining += 1;
      //   await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(user.uid)
      //       .collection('subscriptions')
      //       .doc(subscription.subscriptionId)
      //       .update({
      //     'meetingsRemaining': subscription.meetingsRemaining,
      //   });
      // }

      await fetchAppointments();
      notifyListeners();
    } catch (error) {
      logger.err('Error while canceling appointment with id={}: {}',
          [appointmentId, error]);
      throw Exception('Error canceling appointment.');
    }
  }

  Future<SubscriptionModel?> getCurrentSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.err('User not authenticated.');
      return null;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
}
