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

// Extracted sizes:
const double kColumnWidth = 150.0;
const double kMainMargin = 4.0;
const double kVerticalMargin = 4.0;
const double kContainerPadding = 8.0;
const double kBorderRadiusValue = 8.0;
const double kIconButtonSize = 20.0;
const double kDayTitleFontSize = 16.0;

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
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('appointments')
          .get();

      List<AppointmentModel> fetchedAppointments =
      await Future.wait(snapshot.docs.map((doc) async {
        AppointmentModel appointment = AppointmentModel.fromDocument(doc);

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(appointment.userId)
            .get();

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
    List<AppointmentModel> filteredAppointments = appointments.where((appointment) {
      bool matchesDate = (startDate == null ||
          appointment.appointmentDateTime.isAfter(startDate!)) &&
          (endDate == null ||
              appointment.appointmentDateTime.isBefore(endDate!.add(const Duration(days: 1))));
      bool matchesType = selectedMeetingType == null ||
          appointment.meetingType == selectedMeetingType;
      bool matchesStatus = selectedMeetingStatus == null ||
          appointment.status == selectedMeetingStatus;

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
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
      final appointmentManager =
      Provider.of<AppointmentManager>(context, listen: false);

      bool canceled = await appointmentManager.cancelAppointment(
        appointment.appointmentId,
        appointment.userId,
        canceledBy: 'admin',
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
        SnackBar(content: Text('Randevu iptal edilirken hata: $e')),
      );
    }
  }

  void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () {
            setState(() {
              _fetchAllAppointments();
            });
          },
        );
      },
    );
  }

  bool get _isExactly7Days {
    if (startDate == null || endDate == null) return false;
    return endDate!.difference(startDate!).inDays == 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Randevuları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () {
              setState(() {
                _fetchAllAppointments();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Tarih Aralığı Seç',
            onPressed: _pickDateRange,
          ),
          DropdownButton<MeetingType?>(
            value: selectedMeetingType,
            hint: const Text('Toplantı Türü'),
            items: meetingTypes.map((type) {
              return DropdownMenuItem<MeetingType?>(
                value: type,
                child: Text(type == null ? 'Tümü' : type.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMeetingType = value;
                _fetchAllAppointments();
              });
            },
          ),
          DropdownButton<AppointmentStatus?>(
            value: selectedMeetingStatus,
            hint: const Text('Toplantı Durumu'),
            items: meetingStatuses.map((status) {
              return DropdownMenuItem<AppointmentStatus?>(
                value: status,
                child: Text(status == null ? 'Tümü' : status.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMeetingStatus = value;
                _fetchAllAppointments();
              });
            },
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
            onChanged: (value) {
              setState(() {
                sortOption = value;
                _fetchAllAppointments();
              });
            },
          ),
          if (startDate != null ||
              endDate != null ||
              selectedMeetingType != null ||
              selectedMeetingStatus != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Filtreleri Temizle',
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                  selectedMeetingType = null;
                  selectedMeetingStatus = null;
                  _fetchAllAppointments();
                });
              },
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
                          ...dayAppointments.map((appt) {
                            return GestureDetector(
                              onTap: () => _showEditAppointmentDialog(context, appt),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: kVerticalMargin),
                                padding: const EdgeInsets.all(kContainerPadding),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(kBorderRadiusValue),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appt.user?.name ?? 'Bilinmiyor',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(appt.appointmentDateTime),
                                    ),
                                    Text(
                                      'Durum: ${appt.status.label}',
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () async {
                                          bool? confirmDelete = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text("Randevu İptali"),
                                                content: const Text(
                                                    "Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
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
                                          if (confirmDelete == true) {
                                            await _deleteAppointment(appt);
                                          }
                                        },
                                        iconSize: kIconButtonSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            } else {
              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  AppointmentModel appointment = appointments[index];
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
                          onPressed: () {
                            _showEditAppointmentDialog(context, appointment);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            bool? confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Randevu İptali"),
                                  content: const Text(
                                      "Bu randevuyu iptal etmek istediğinizden emin misiniz?"),
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
