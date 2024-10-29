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
  bool _showAllAppointments = false;

  String? _userId;
  String? _selectedSubscriptionId;

  // Getters
  List<AppointmentModel> get userAppointments => _userAppointments;
  String? get userId => _userId;
  bool get showAllAppointments => _showAllAppointments;
  String? get selectedSubscriptionId => _selectedSubscriptionId;

  @override
  bool get isLoading => _isLoading;

  AppointmentManager();

  // Setters
  void setUserId(String userId) {
    _userId = userId;
    fetchAppointments();
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
    fetchAppointments();
  }

  void setShowAllAppointments(bool value) {
    if (_showAllAppointments != value) {
      logger.info('setShowAllAppointments is called with _showAllAppointments={}', [value]);
      _showAllAppointments = value;
      fetchAppointments();
    }
  }

  // Fetch Appointments based on the selected subscription and showAllAppointments flag
  Future<void> fetchAppointments() async {
    if (_userId == null) return;

    _isLoading = true;
   // notifyListeners();

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .orderBy('appointmentDateTime', descending: false);

      if (!_showAllAppointments && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      QuerySnapshot snapshot = await query.get();

      _userAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info('Appointments fetched successfully.');
    } catch (e) {
      logger.err('Error fetching appointments: {}', [e]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch appointments for the current user
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

  // Fetch appointments for a specific date to determine available time slots
  Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    _isLoading=true;
    List<TimeOfDay> availableSlots = [];
    try {
      // Query query = FirebaseFirestore.instance
      //     .collection('appointments')
      //     .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
      //     .where('appointmentDateTime', isLessThan: endOfDay);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDateTime', isLessThan: endOfDay)
          .get();

      //final snapshot = await query.get();

      _dayAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      logger.info(
          'Appointments for date {}/{}/{} fetched successfully.', [date.day, date.month, date.year]);

      for (int hour = 9; hour < 19; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
          if (isTimeSlotAvailable(date, time)) {
            availableSlots.add(time);
          }
        }
      }
    } catch (e) {
      logger.err('Error fetching appointments for date {}: {}', [date, e]);
    } finally {
      _isLoading=false;
      notifyListeners();
    }
    return availableSlots;
  }

  // Check if a time slot is available
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

      _userAppointments.add(appointment);

      logger.info('Appointment added successfully: {}', [appointment]);

    } catch (e) {
      logger.err('Error adding appointment: {}', [e]);
      throw Exception('Error adding appointment.');
    }finally {
     notifyListeners();
    }
  }

  // Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId, {required String canceledBy}) async {
    if (_userId == null) {
      return false;
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


      // Update local list
      int index = _userAppointments.indexWhere((a) => a.appointmentId == appointmentId);
      if (index != -1) {
        _userAppointments[index].status = MeetingStatus.canceled;
        _userAppointments[index].canceledBy = canceledBy;
        _userAppointments[index].canceledAt = DateTime.now();
      }

      logger.info('Appointment canceled successfully by {}.', [canceledBy]);
      return false;
    } catch (e) {
      logger.err('Error canceling appointment: {}', [e]);
      return false;
    }
    finally{
      notifyListeners();
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
    }finally{
      notifyListeners();
    }
  }
}
