// dialogs/add_appointment_dialog.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../models/logger.dart';
import '../providers/appointment_manager.dart';
final Logger logger = Logger.forClass(AddAppointmentDialog);

class AddAppointmentDialog extends StatefulWidget {
  final String userId;
  final String? subscriptionId;
  final VoidCallback onAppointmentAdded;

  const AddAppointmentDialog({
    super.key,
    required this.userId,
    this.subscriptionId,
    required this.onAppointmentAdded,
  });

  @override
   createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  MeetingType _meetingType = MeetingType.f2f;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Randevu Ekle'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Date Picker
            ListTile(
              title: const Text('Tarih Seç'),
              subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0]),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
            ),
            // Time Picker
            ListTile(
              title: const Text('Saat Seç'),
              subtitle: Text(_selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Saat seçilmedi.'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: _pickTime,
              ),
            ),
            // Meeting Type
            DropdownButton<MeetingType>(
              value: _meetingType,
              onChanged: (MeetingType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _meetingType = newValue;
                  });
                }
              },
              items: MeetingType.values.map((MeetingType type) {
                return DropdownMenuItem<MeetingType>(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
            ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addAppointment, //TODO test setstate ve return err msglar
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Ekle'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addAppointment() async {
    if (_selectedTime == null) {
      setState(() {
        _errorMessage = 'Lütfen bir saat seçiniz.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointmentManager =
      Provider.of<AppointmentManager>(context, listen: false);

      DateTime appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      bool isAvailable = appointmentManager.isTimeSlotAvailable(
          _selectedDate, _selectedTime!,null); //TODO gelecekteki apptleri eklerken null verilemez

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçilen tarih/saat uygun değildir. Lütfen kontrol ediniz.')),
        );
        setState(() {
          _errorMessage = 'Seçilen tarih/saat uygun değildir. Lütfen kontrol ediniz.';
        });
        return;
      }

      AppointmentModel newAppointment = AppointmentModel(
        appointmentId: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('appointments')
            .doc()
            .id,
        userId: widget.userId,
        subscriptionId: widget.subscriptionId,
        meetingType: _meetingType,
        appointmentDateTime: appointmentDateTime,
        status: AppointmentStatus.scheduled,
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      await appointmentManager.addAppointment(newAppointment);
      widget.onAppointmentAdded();

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e,s) {
      setState(() {
        // _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _errorMessage = 'Randevu oluşturulurken bir hata oluştu. Geliştiriciden destek isteyiniz.';
      });
      logger.err('Exception:{}{}',[e,s]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
