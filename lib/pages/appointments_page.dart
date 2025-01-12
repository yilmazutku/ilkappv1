import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../providers/appointment_manager.dart';
import 'meal_upload_page.dart';

final Logger logger = Logger.forClass(AppointmentsPage);

class AppointmentsPage extends StatefulWidget {
  final String userId;
  final String subscriptionId;

  const AppointmentsPage({
    Key? key,
    required this.userId,
    required this.subscriptionId,
  }) : super(key: key);

  @override
  createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _selectedDate = DateTime.now();
  MeetingType _selectedMeetingType = MeetingType.f2f;
  TimeOfDay? _selectedTime;
  late Future<List<TimeOfDay>> _availableTimesFuture;
  late Future<List<AppointmentModel>> _userAppointmentsFuture;

  @override
  void initState() {
    super.initState();
    logger.info('Initializing AppointmentsPage state.');
    _fetchAvailableTimes();
    _fetchUserAppointments();
  }

  void _fetchAvailableTimes() {
    final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
    _availableTimesFuture = appointmentManager.getAvailableTimesForDate(_selectedDate);
  }

  void _fetchUserAppointments() {
    final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
    _userAppointmentsFuture =
        appointmentManager.fetchAppointments(showAllAppointments: true, userId: widget.userId);
  }

  Future<void> _bookAppointment() async {
    if (_selectedTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir zaman dilimi seçin.')),
      );
      return;
    }

    try {
      final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);

      DateTime appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Check if the selected time slot is still available
      List<TimeOfDay> availableTimes =
      await appointmentManager.getAvailableTimesForDate(_selectedDate);
      bool isAvailable = availableTimes.contains(_selectedTime);

      if (!mounted) return;
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçtiğiniz saat/tarih uygun değildir.')),
        );
        return;
      }

      String appointmentId = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('appointments')
          .doc()
          .id;

      AppointmentModel appointment = AppointmentModel(
        appointmentId: appointmentId,
        userId: widget.userId,
        subscriptionId: widget.subscriptionId,
        meetingType: _selectedMeetingType,
        appointmentDateTime: appointmentDateTime,
        status: AppointmentStatus.scheduled,
        createdAt: DateTime.now(),
        createdBy: 'user',
      );

      await appointmentManager.addAppointment(appointment);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu başarıyla oluşturuldu.')),
      );

      // Refresh available times and user's appointments
      setState(() {
        _fetchAvailableTimes();
        _fetchUserAppointments();
        _selectedTime = null;
      });
    } catch (e, stackTrace) {
      logger.err('Error booking appointment: {}', [e]);
      logger.err('Stack trace: {}', [stackTrace]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu oluşturulurken bir hata oluştu.')),
      );
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    try {
      final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);

      if (await appointmentManager.cancelAppointment(
          appointment.appointmentId, appointment.userId,
          canceledBy: 'user')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu iptal edildi.')),
        );
      }
      setState(() {
        _fetchAvailableTimes();
        _fetchUserAppointments();
      });
    } catch (e, stackTrace) {
      logger.err('Error canceling appointment: {}', [e]);
      logger.err('Stack trace: {}', [stackTrace]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu iptal edilirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.info('Building AppointmentsPage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevularım'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting Type Selector
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.event_available, color: Colors.deepPurple, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      'Görüşme Türü:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<MeetingType>(
                      value: _selectedMeetingType,
                      onChanged: (MeetingType? newValue) {
                        setState(() {
                          _selectedMeetingType = newValue!;
                        });
                      },
                      items: MeetingType.values
                          .map<DropdownMenuItem<MeetingType>>((MeetingType type) {
                        return DropdownMenuItem<MeetingType>(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date Picker
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.blueAccent),
                title: Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit_calendar, color: Colors.blueAccent),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 45)),
                    locale: const Locale('tr', 'TR'),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      _selectedTime = null;
                    });
                    _fetchAvailableTimes();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Available Time Slots
           const Text(
              'Uygun Saatler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<TimeOfDay>>(
              future: _availableTimesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  logger.err('Error fetching available times: {}', [snapshot.error!]);
                  return Text('Zaman dilimleri alınırken bir hata oluştu: ${snapshot.error}');
                } else {
                  List<TimeOfDay> availableTimes = snapshot.data ?? [];
                  // Sort the times
                  availableTimes.sort((a, b) {
                    if (a.hour != b.hour) {
                      return a.hour.compareTo(b.hour);
                    } else {
                      return a.minute.compareTo(b.minute);
                    }
                  });
                  if (availableTimes.isEmpty) {
                    return const Text('Seçilen tarih için uygun zaman dilimi yok.');
                  } else {
                    return Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: availableTimes.map((time) {
                        return ChoiceChip(
                          label: Text(
                            MealUploadPage.formatTimeOfDay24(time),
                            style: TextStyle(
                              color: _selectedTime == time ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: _selectedTime == time,
                          selectedColor: Colors.deepPurple,
                          backgroundColor: Colors.grey[200],
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedTime = selected ? time : null;
                            });
                          },
                        );
                      }).toList(),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            // Book Appointment Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _bookAppointment,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Randevu Al'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // User's Appointments
            Text(
              'Randevularım',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<AppointmentModel>>(
              future: _userAppointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  logger.err('Error fetching appointments: {}', [snapshot.error!]);
                  return Text('Randevular alınırken bir hata oluştu: ${snapshot.error}');
                } else {
                  List<AppointmentModel> appointments = snapshot.data ?? [];
                  return _buildAppointmentsList(appointments);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
    final upcomingAppointments = appointments.where((appointment) {
      return appointment.appointmentDateTime.isAfter(DateTime.now()) &&
          appointment.status != AppointmentStatus.canceled &&
          !(appointment.isDeleted ?? false);
    }).toList();

    if (upcomingAppointments.isEmpty) {
      return const Text('Gelecek randevunuz bulunmamaktadır.');
    }
    logger.info('Upcoming Appointments: {}', [upcomingAppointments]);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: upcomingAppointments.length,
      itemBuilder: (context, index) {
        AppointmentModel appointment = upcomingAppointments[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.event_note, color: Colors.deepPurple),
            title: Text(
              DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR')
                  .format(appointment.appointmentDateTime),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Görüşme Türü: ${appointment.meetingType.label}'),
            trailing: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                bool? confirmCancel = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Randevuyu İptal Et"),
                      content: const Text("Bu randevuyu iptal etmek istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text("Hayır"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text("Evet"),
                        ),
                      ],
                    );
                  },
                );

                if (confirmCancel == true) {
                  await _cancelAppointment(appointment);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
