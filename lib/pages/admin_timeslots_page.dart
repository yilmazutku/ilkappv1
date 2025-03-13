import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/logger.dart';
import '../models/appointment_model.dart';


final Logger logger = Logger.forClass(AdminTimeSlotsPage);

class AdminTimeSlotsPage extends StatefulWidget {
  const AdminTimeSlotsPage({super.key});

  @override
   createState() => _AdminTimeSlotsPageState();
}

class _AdminTimeSlotsPageState extends State<AdminTimeSlotsPage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  /// For displaying "what is stored in Firebase" for this day.
  List<String> _storedTimesForDay = [];

  /// For showing which times have appointments on them.
  /// e.g. {'09:00': true, '09:30': false, ...}
  final Map<String, bool> _hasAppointment = {};

  /// Text field controller where admin can type new times
  final TextEditingController _timeInputController = TextEditingController();

  /// Reference to your AppointmentManager (or you can simply create a new instance)

  @override
  void initState() {
    super.initState();
    _fetchDayData(_selectedDate);
  }

  /// Whenever a date is selected, fetch data
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
    });
    _fetchDayData(_selectedDate);
  }

  /// Fetch stored times from `admininput/timeslots/dates/<YYYY-MM-DD>`
  /// and also fetch appointments from your `AppointmentManager`.
  Future<void> _fetchDayData(DateTime date) async {
    setState(() {
      _isLoading = true;
      _storedTimesForDay.clear();
      _hasAppointment.clear();
    });

    final String dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      // 1) Fetch times from Firestore
      final docSnap = await FirebaseFirestore.instance
          .collection('admininput')
          .doc('timeslots')
          .collection('dates')
          .doc(dateString)
          .get();

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        final List<dynamic> storedTimes = data['times'] ?? [];
        _storedTimesForDay = storedTimes.map((e) => e.toString()).toList();
      }

      // 2) Fetch existing appointments for this day
      //    Adjust the userId or other filters as needed
      //    If you want to fetch ALL appointments from all users, you might do a collectionGroup query
      List<AppointmentModel> dayAppointments = [];
      {
        // Example approach: fetch from AppointmentManager
        // But if your AppointmentManager requires a specific user ID or subscription,
        // adapt accordingly. This is just the idea.
        // This snippet tries to emulate a "fetch all appointments for that day".
        dayAppointments = await _fetchAppointmentsForDate(date);
      }

      // 3) Mark which stored times have appointments
      for (final timeStr in _storedTimesForDay) {
        // parse the time into hour + minute
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        bool appointmentExists = false;
        for (final appt in dayAppointments) {
          final apptTime = appt.appointmentDateTime;
          if (apptTime.year == date.year &&
              apptTime.month == date.month &&
              apptTime.day == date.day &&
              apptTime.hour == hour &&
              apptTime.minute == minute &&
              appt.status != AppointmentStatus.canceled) {
            appointmentExists = true;
            break;
          }
        }
        _hasAppointment[timeStr] = appointmentExists;
      }

      // Optionally, populate the text field with the stored times
      // (If you only want the text field to show new times, you can skip this.)
      // Here, we just clear it or keep it separate.
      _timeInputController.text = _storedTimesForDay.join(',');

      setState(() {});
    } catch (e) {
      logger.err('Error fetching day data: {}', [e]);
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching day data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Example function: fetch all appointments on the given date.
  /// You might do a collectionGroup query to get from all users, or filter, etc.
  Future<List<AppointmentModel>> _fetchAppointmentsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('appointmentDateTime', isLessThan: endOfDay)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();
    } catch (e) {
      logger.err('Error fetching appointments for date {}: {}', [date, e]);
      return [];
    }
  }

  /// When "Save" is pressed, update the times in Firestore with the new values
  Future<void> _onSaveTimes() async {
    final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // 1) Parse times from text field (comma-separated)
    final rawInput = _timeInputController.text.trim();
    final inputs = rawInput.split(',');
    // Clean them up, removing extra spaces, ignoring empty
    final newTimes = <String>[];
    for (final input in inputs) {
      final t = input.trim();
      if (t.isNotEmpty) newTimes.add(t);
    }

    // 2) Save times in Firestore
    final docRef = FirebaseFirestore.instance
        .collection('admininput')
        .doc('timeslots')
        .collection('dates')
        .doc(dateString);

    try {
      await docRef.set({'times': newTimes});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Times updated successfully!')),
      );
      // Optionally re-fetch to see updated data
      _fetchDayData(_selectedDate);
    } catch (e) {
      logger.err('Error saving times: {}', [e]);
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zamanları kaydederken hata oluştu: $e')),
      );
    }
  }

  Widget _buildStoredTimesSection() {
    if (_storedTimesForDay.isEmpty) {
      return const Text(
        'No times stored for this date.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    // Show them in a Wrap or Column as tags/rectangles, plus whether they have an appointment
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _storedTimesForDay.map((timeStr) {
        final hasAppt = _hasAppointment[timeStr] ?? false;
        // color or style them accordingly
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hasAppt ? Colors.orangeAccent : Colors.lightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (hasAppt)
                const Text(
                  'Appointment Booked',
                  style: TextStyle(fontSize: 12),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  CalendarFormat _calendarFormat = CalendarFormat.week;
  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Time Slots (Refactor)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: _onDaySelected,
              calendarFormat: _calendarFormat,
              // IMPORTANT: add onFormatChanged callback
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              // ...
            ),
            const SizedBox(height: 16),

            // Selected date text
            Text(
              'Selected Date: $dateString',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Section: showing stored times from Firestore
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Times in Firestore for $dateString:',
                //style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            const SizedBox(height: 8),

            // Build the stored times with appointment info
            _buildStoredTimesSection(),
            const SizedBox(height: 24),

            // Section: text field to input new times
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter available times (comma-separated, 24h format):',
              //  style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _timeInputController,
              decoration: const InputDecoration(
                hintText: 'Örn. 09:00,09:30,10:00,17:30...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _onSaveTimes,
              child: const Text('Save Times'),
            ),
          ],
        ),
      ),
    );
  }
}
