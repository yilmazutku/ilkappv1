import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/logger.dart';

final Logger logger = Logger.forClass(AdminTimeSlotsPage);

class AdminTimeSlotsPage extends StatefulWidget {
  const AdminTimeSlotsPage({Key? key}) : super(key: key);

  @override
  _AdminTimeSlotsPageState createState() => _AdminTimeSlotsPageState();
}

class _AdminTimeSlotsPageState extends State<AdminTimeSlotsPage> {
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _timeSlots = {}; // Map of time string to availability
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTimeSlotsForDate(_selectedDate);
  }

  Future<void> _fetchTimeSlotsForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _timeSlots.clear();
    });

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      DocumentSnapshot timeslotDoc = await FirebaseFirestore.instance
          .collection('admininput')
          .doc('timeslots')
          .collection('dates')
          .doc(dateString)
          .get();

      List<String> availableTimes = [];
      if (timeslotDoc.exists) {
        Map<String, dynamic> data = timeslotDoc.data() as Map<String, dynamic>;
        availableTimes = List<String>.from(data['times'] ?? []);
      }

      // Generate all possible time slots for the day
      _timeSlots = _generateAllTimeSlots();

      // Mark available times
      for (String time in availableTimes) {
        if (_timeSlots.containsKey(time)) {
          _timeSlots[time] = true;
        }
      }

      setState(() {});
    } catch (e) {
      logger.err('Error fetching time slots: {}', [e]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching time slots: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, bool> _generateAllTimeSlots() {
    Map<String, bool> timeSlots = {};
    DateTime startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 9, 0);
    DateTime endDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 19, 0);

    DateTime currentTime = startDateTime;
    while (!currentTime.isAfter(endDateTime)) {
      String timeString = DateFormat('HH:mm').format(currentTime);
      timeSlots[timeString] = false; // Initially set all slots to unavailable
      currentTime = currentTime.add(const Duration(minutes: 30));
    }

    return timeSlots;
  }

  Future<void> _updateTimeSlot(String timeString, bool isAvailable) async {
    setState(() {
      _timeSlots[timeString] = isAvailable;
    });

    String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('admininput')
        .doc('timeslots')
        .collection('dates')
        .doc(dateString);

    try {
      DocumentSnapshot timeslotDoc = await docRef.get();
      List<String> availableTimes = [];
      if (timeslotDoc.exists) {
        Map<String, dynamic> data = timeslotDoc.data() as Map<String, dynamic>;
        availableTimes = List<String>.from(data['times'] ?? []);
      }

      if (isAvailable) {
        // Add time to available times
        if (!availableTimes.contains(timeString)) {
          availableTimes.add(timeString);
        }
      } else {
        // Remove time from available times
        availableTimes.remove(timeString);
      }

      await docRef.set({'times': availableTimes});
    } catch (e) {
      logger.err('Error updating time slot: {}', [e]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating time slot: $e')),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _fetchTimeSlotsForDate(_selectedDate);
    });
  }

  Widget _buildTimeSlotsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: _timeSlots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Adjust according to your UI preference
        childAspectRatio: 2,
      ),
      itemBuilder: (context, index) {
        String timeString = _timeSlots.keys.elementAt(index);
        bool isAvailable = _timeSlots[timeString]!;
        return GestureDetector(
          onTap: () {
            bool newAvailability = !isAvailable;
            _updateTimeSlot(timeString, newAvailability);
          },
          child: Card(
            color: isAvailable ? Colors.green[200] : Colors.red[200],
            child: Center(
              child: Text(
                timeString,
                style: TextStyle(
                  color: isAvailable ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Time Slots'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Calendar Widget
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: _onDaySelected,
          ),
          const SizedBox(height: 16),
          // Date Display
          Text(
            'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Time Slots Grid
          Expanded(
            child: _buildTimeSlotsGrid(),
          ),
        ],
      ),
    );
  }
}
