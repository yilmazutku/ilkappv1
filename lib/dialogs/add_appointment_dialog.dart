// add_appointment_dialog.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../commons/logger.dart';
import '../commons/userclass.dart';

class AddAppointmentDialog extends StatefulWidget {
  final String userId;
  final Function onAppointmentAdded;
  final SubscriptionModel subscription;

  const AddAppointmentDialog({
    super.key,
    required this.userId,
    required this.onAppointmentAdded,
    required this.subscription,
  });

  @override
   createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final Logger logger = Logger.forClass(AddAppointmentDialog);

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  MeetingType _meetingType = MeetingType.f2f;
  bool _isLoading = false;
  bool _isPastAppointment = false; // New variable

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Appointment'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            SwitchListTile(
              title: const Text('Add Past Appointment'),
              value: _isPastAppointment,
              onChanged: (value) {
                setState(() {
                  _isPastAppointment = value;
                });
              },
            ),
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime firstDate = _isPastAppointment
                    ? DateTime.now().subtract(const Duration(days: 30))
                    : DateTime.now();
                DateTime initialDate = /*_isPastAppointment
                    ? DateTime.now().subtract(const Duration(days: 30))
                    : */DateTime.now();
                DateTime lastDate = DateTime.now().add(const Duration(days: 365));

                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
            ),
            ListTile(
              title: Text(_selectedTime == null
                  ? 'Select Time'
                  : 'Time: ${_selectedTime!.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MeetingType>(
              value: _meetingType,
              items: MeetingType.values.map((MeetingType type) {
                return DropdownMenuItem<MeetingType>(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _meetingType = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Meeting Type'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addAppointment,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Add Appointment'),
        ),
      ],
    );
  }

  Future<void> _addAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      logger.err('Please select date and time.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time.')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      DateTime appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create a new appointment document
      final appointmentDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('appointments')
          .doc(); // Generate a new appointment ID

      AppointmentModel appointmentModel = AppointmentModel(
        appointmentId: appointmentDocRef.id,
        userId: widget.userId,
        subscriptionId: widget.subscription.subscriptionId,
        meetingType: _meetingType,
        appointmentDateTime: appointmentDateTime,
        status: MeetingStatus.scheduled,
        createdAt: DateTime.now(),
      );

      await appointmentDocRef.set(appointmentModel.toMap());
      logger.info('Appointment added successfully for user {}', [widget.userId]);

      // Update the subscription's meetingsRemaining and meetingsCompleted
      if (appointmentDateTime.isBefore(DateTime.now())) {
        // Past appointment
        widget.subscription.meetingsCompleted += 1;
      } else {
        // Future appointment
        widget.subscription.meetingsRemaining -= 1;
      }

      // Update the subscription in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .doc(widget.subscription.subscriptionId)
          .update({
        'meetingsRemaining': widget.subscription.meetingsRemaining,
        'meetingsCompleted': widget.subscription.meetingsCompleted,
      });

      // Notify parent widget to refresh data
      widget.onAppointmentAdded();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment added successfully.')),
      );
    } catch (e) {
      logger.err('Error adding appointment: {}', [e]);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding appointment: $e')),
      );
    }
  }
}
