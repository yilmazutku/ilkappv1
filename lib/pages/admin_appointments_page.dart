import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../models/user_model.dart';
import '../providers/appointment_manager.dart';
import '../dialogs/edit_appointment_dialog.dart';

final Logger logger = Logger.forClass(AdminAppointmentsPage);

// Adjust these values to suit your design:
const double kColumnWidth = 150.0;        // width of each day's column
const double kMainMargin = 4.0;          // margin around the day columns
const double kDayTitleFontSize = 16.0;   // font size for the day header
const double kFixedDayHeight = 500.0;    // total vertical space each day column occupies
const double kMaxCardHeight = 135.0;      // max height of each appointment "blue box"

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  DateTime? startDate;
  DateTime? endDate;

  MeetingType? selectedMeetingType;
  AppointmentStatus? selectedMeetingStatus;
  String? sortOption = 'Tarih Artan';

  final List<MeetingType?> meetingTypes = [null, ...MeetingType.values];
  final List<AppointmentStatus?> meetingStatuses = [null, ...AppointmentStatus.values];
  final List<String> sortOptions = [
    'Tarih Artan',
    'Tarih Azalan',
    'İsim A-Z',
    'İsim Z-A',
  ];

  late Future<List<AppointmentModel>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final difference = now.weekday - DateTime.monday;
    final monday = now.subtract(Duration(days: difference));

    startDate = DateTime(monday.year, monday.month, monday.day);
    endDate = startDate!.add(const Duration(days: 6));

    _fetchAllAppointments();
  }

  void _fetchAllAppointments() {
    _appointmentsFuture = _fetchAppointmentsWithUsers();
  }

  Future<List<AppointmentModel>> _fetchAppointmentsWithUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .get();

      final usersCollection = FirebaseFirestore.instance.collection('users');

      final fetchedAppointments = await Future.wait(snapshot.docs.map((doc) async {
        final appointment = AppointmentModel.fromDocument(doc);
        final userDoc = await usersCollection.doc(appointment.userId).get();

        appointment.user = UserModel.fromDocument(userDoc);
        return appointment;
      }).toList());

      return _applyFiltersAndSort(fetchedAppointments);
    } catch (e) {
      logger.err('Randevular getirilirken hata oluştu: {}', [e]);
      return [];
    }
  }

  List<AppointmentModel> _applyFiltersAndSort(List<AppointmentModel> appointments) {
    final filteredAppointments = appointments.where((appointment) {
      final matchesDate = (startDate == null ||
          appointment.appointmentDateTime.isAfter(startDate!)) &&
          (endDate == null ||
              appointment.appointmentDateTime
                  .isBefore(endDate!.add(const Duration(days: 1))));
      final matchesType = (selectedMeetingType == null) ||
          (appointment.meetingType == selectedMeetingType);
      final matchesStatus = (selectedMeetingStatus == null) ||
          (appointment.status == selectedMeetingStatus);

      return matchesDate && matchesType && matchesStatus;
    }).toList();

    filteredAppointments.sort((a, b) {
      switch (sortOption) {
        case 'Tarih Artan':
          return a.appointmentDateTime.compareTo(b.appointmentDateTime);
        case 'Tarih Azalan':
          return b.appointmentDateTime.compareTo(a.appointmentDateTime);
        case 'İsim A-Z':
          return (a.user?.name ?? '').compareTo(b.user?.name ?? '');
        case 'İsim Z-A':
          return (b.user?.name ?? '').compareTo(a.user?.name ?? '');
        default:
          return 0;
      }
    });

    return filteredAppointments;
  }

  void _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
        _fetchAllAppointments();
      });
    }
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    try {
      final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
      final canceled = await appointmentManager.cancelAppointment(
        appointment.appointmentId,
        appointment.userId,
        canceledBy: 'admin', // or "Nilay"/"Nuray" if you have that info
      );

      if (!mounted) return;
      if (canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu iptal edildi.')),
        );
      }
      _fetchAllAppointments();
    } catch (e) {
      logger.err('Randevu iptal edilirken hata: {}', [e]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu iptal edilirken hata oluştu: $e')),
      );
    }
  }

  void _onDeleteClicked(AppointmentModel appt) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Randevu İptali"),
          content: const Text("Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Hayır"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Evet"),
            ),
          ],
        );
      },
    );
    if (confirmDelete == true) {
      await _deleteAppointment(appt);
    }
  }

  void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (_) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () {
            setState(() => _fetchAllAppointments());
          },
        );
      },
    );
  }

  bool get _isExactly7Days {
    if (startDate == null || endDate == null) return false;
    return endDate!.difference(startDate!).inDays == 6;
  }

  /// Build the blue "box" for a single appointment.
  ///
  /// - **Delete icon** is in the top-right corner using a Stack/Positioned.
  /// - **Meeting info** is on a single line: "meetingType time status".
  Widget _buildAppointmentCard(AppointmentModel appt) {
    // Combine meeting info into one line, e.g.: "Yüzyüze 19:30 İptal Edildi"
    final String combinedLine = [
      appt.meetingType.label,
      DateFormat('HH:mm').format(appt.appointmentDateTime),
      appt.status.label,
    ].join(' ');

    return GestureDetector(
      onTap: () => _showEditAppointmentDialog(context, appt),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // The textual content (name + one-line meeting info)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.user?.name ?? 'Bilinmiyor',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  combinedLine,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            // Delete icon in the top-right corner
            // Positioned(
            //   top: 0,
            //   right: 0,
            //   child: IconButton(
            //     icon: const Icon(Icons.cancel, color: Colors.red),
            //     iconSize: 16,
            //     onPressed: () => _onDeleteClicked(appt),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Randevuları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _fetchAllAppointments()),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          DropdownButton<MeetingType?>(
            value: selectedMeetingType,
            hint: const Text('Görüşme Türü'),
            items: meetingTypes.map((type) {
              return DropdownMenuItem<MeetingType?>(
                value: type,
                child: Text(type == null ? 'Tümü' : type.label),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              selectedMeetingType = value;
              _fetchAllAppointments();
            }),
          ),
          DropdownButton<AppointmentStatus?>(
            value: selectedMeetingStatus,
            hint: const Text('Görüşme Durumu'),
            items: meetingStatuses.map((status) {
              return DropdownMenuItem<AppointmentStatus?>(
                value: status,
                child: Text(status == null ? 'Tümü' : status.label),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              selectedMeetingStatus = value;
              _fetchAllAppointments();
            }),
          ),
          DropdownButton<String>(
            value: sortOption,
            hint: const Text('Sırala'),
            items: sortOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              sortOption = value;
              _fetchAllAppointments();
            }),
          ),
          if (startDate != null ||
              endDate != null ||
              selectedMeetingType != null ||
              selectedMeetingStatus != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                startDate = null;
                endDate = null;
                selectedMeetingType = null;
                selectedMeetingStatus = null;
                _fetchAllAppointments();
              }),
            ),
        ],
      ),
      body: FutureBuilder<List<AppointmentModel>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            logger.err('Randevular getirilirken hata: {}', [snapshot.error ?? '']);
            return Center(
              child: Text('Randevular getirilirken hata: ${snapshot.error}'),
            );
          } else {
            final appointments = snapshot.data ?? [];
            if (appointments.isEmpty) {
              return const Center(child: Text('Randevu bulunamadı.'));
            }

            // If the range is exactly 7 days, display columns for each day
            if (_isExactly7Days) {
              final List<DateTime> weekDays = List.generate(
                7,
                    (index) => startDate!.add(Duration(days: index)),
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weekDays.map((day) {
                    final dayAppointments = appointments.where((appt) {
                      return appt.appointmentDateTime.year == day.year &&
                          appt.appointmentDateTime.month == day.month &&
                          appt.appointmentDateTime.day == day.day;
                    }).toList();

                    final dayTitle = DateFormat('EEEE d.MM', 'tr_TR').format(day);

                    return Container(
                      width: kColumnWidth,
                      margin: const EdgeInsets.all(kMainMargin),
                      child: SizedBox(
                        height: kFixedDayHeight, // e.g. 500 px
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: kDayTitleFontSize,
                              ),
                            ),
                            const Divider(),
                            if (dayAppointments.isEmpty)
                              const Text('Bu gün boş.'),
                            if (dayAppointments.isNotEmpty)
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: dayAppointments.map((appt) {
                                      return SizedBox(
                                        height: kMaxCardHeight, // up to 60 px
                                        child: _buildAppointmentCard(appt),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            } else {
              // Otherwise, just show them in a simple ListView
              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return ListTile(
                    title: Text(
                      'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}',
                    ),
                    subtitle: Text(
                      'Kullanıcı: ${appointment.user?.name ?? 'Bilinmiyor'}\n'
                          'Tür: ${appointment.meetingType.label}\n'
                          'Durum: ${appointment.status.label}\n'
                          'İptal Eden: ${appointment.canceledBy ?? 'Yok'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditAppointmentDialog(context, appointment),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Randevu İptali"),
                                  content: const Text(
                                      "Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Hayır"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("Evet"),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmDelete == true) {
                              await _deleteAppointment(appointment);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}
