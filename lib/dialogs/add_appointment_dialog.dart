// dialogs/add_appointment_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_manager.dart';

class AddAppointmentDialog extends StatefulWidget {
  final String userId;
  final String subscriptionId;
  final VoidCallback onAppointmentAdded;

  const AddAppointmentDialog({
    super.key,
    required this.userId,
    required this.subscriptionId,
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
      title: const Text('Add Appointment'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Date Picker
            ListTile(
              title: const Text('Select Date'),
              subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0]),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
            ),
            // Time Picker
            ListTile(
              title: const Text('Select Time'),
              subtitle: Text(_selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'No time selected'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addAppointment,
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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
        _errorMessage = 'Please select a time.';
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

      appointmentManager.setUserId(widget.userId);
      appointmentManager.setSelectedSubscriptionId(widget.subscriptionId);
      appointmentManager.setSelectedDate(_selectedDate);
      appointmentManager.setSelectedTime(_selectedTime);
      appointmentManager.setMeetingType(_meetingType);

      await appointmentManager.bookAppointmentForCurrentUser();

      widget.onAppointmentAdded();
      if(!context.mounted)return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
