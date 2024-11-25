import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';
import '../models/logger.dart';

final Logger logger = Logger.forClass(PastAppointmentsPage);

class PastAppointmentsPage extends StatefulWidget {
  final String userId;

  const PastAppointmentsPage({super.key, required this.userId});

  @override
  createState() => _PastAppointmentsPageState();
}

class _PastAppointmentsPageState extends State<PastAppointmentsPage> {
  static const int _pageSize = 5; // Number of items per page
  int _currentPage = 1; // Current page index
  int _totalPages = 1; // Total number of pages
  List<AppointmentModel> _allAppointments = []; // All fetched appointments
  List<AppointmentModel> _currentAppointments = []; // Appointments for the current page
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllAppointments();
  }

  /// Fetch all past appointments and initialize pagination.
  Future<void> _fetchAllAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      logger.info('Fetching all past appointments for user ${widget.userId}...');
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('appointments')
          .where('appointmentDateTime', isLessThan: Timestamp.now()) // Past appointments only
          .orderBy('appointmentDateTime', descending: true)
          .get();

      _allAppointments = snapshot.docs
          .map((doc) => AppointmentModel.fromDocument(doc))
          .toList();

      _totalPages = (_allAppointments.length / _pageSize).ceil();
      if (_totalPages == 0) _totalPages = 1; // Ensure at least one page

      logger.info('Total past appointments fetched: ${_allAppointments.length}');
      logger.info('Total pages calculated: $_totalPages');

      _setCurrentPageAppointments();
    } catch (e) {
      logger.err('Error fetching all past appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching appointments: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Set the appointments for the current page by slicing the _allAppointments list.
  void _setCurrentPageAppointments() {
    setState(() {
      int startIndex = (_currentPage - 1) * _pageSize;
      int endIndex = startIndex + _pageSize;
      if (endIndex > _allAppointments.length) {
        endIndex = _allAppointments.length;
      }
      _currentAppointments = _allAppointments.sublist(startIndex, endIndex);
      logger.info('Displaying appointments for page $_currentPage: $_currentAppointments');
    });
  }

  /// Handle page changes by updating _currentPage and setting the current appointments.
  void _changePage(int page) {
    if (page != _currentPage && page >= 1 && page <= _totalPages) {
      logger.info('Switching to page $page...');
      setState(() {
        _currentPage = page;
      });
      _setCurrentPageAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Appointments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allAppointments.isEmpty
                ? const Center(child: Text('No past appointments found.'))
                : ListView.builder(
              itemCount: _currentAppointments.length,
              itemBuilder: (context, index) {
                final appointment = _currentAppointments[index];
                return ListTile(
                  title: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime),
                  ),
                  subtitle: Text('Status: ${appointment.status.label}'),
                );
              },
            ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  int page = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TextButton(
                      onPressed: () {
                        _changePage(page);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _currentPage == page
                            ? Colors.blue
                            : Colors.grey[200],
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          color: _currentPage == page ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
