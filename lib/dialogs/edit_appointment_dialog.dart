// edit_appointment_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../commons/logger.dart';
import '../commons/userclass.dart';

class EditAppointmentDialog extends StatefulWidget {
  final AppointmentModel appointment;
  final Function onAppointmentUpdated;

  const EditAppointmentDialog({
    super.key,
    required this.appointment,
    required this.onAppointmentUpdated,
  });

  @override
  createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  final Logger logger = Logger.forClass(EditAppointmentDialog);

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  MeetingType? _meetingType;
  MeetingStatus? _meetingStatus;
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.appointmentDateTime;
    _selectedTime =
        TimeOfDay.fromDateTime(widget.appointment.appointmentDateTime);
    _meetingType = widget.appointment.meetingType;
    _meetingStatus = widget.appointment.status;
    _notesController.text = widget.appointment.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Appointment'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime initialDate = DateTime.now();
                DateTime firstDate =
                    DateTime.now().subtract(const Duration(days: 365));
                DateTime lastDate =
                    DateTime.now().add(const Duration(days: 365));

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
                TimeOfDay initialTime = TimeOfDay.now();

                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? initialTime,
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
            const SizedBox(height: 16),
            DropdownButtonFormField<MeetingStatus>(
              value: _meetingStatus,
              items: MeetingStatus.values.map((MeetingStatus status) {
                return DropdownMenuItem<MeetingStatus>(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _meetingStatus = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Meeting Status'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
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
          onPressed: _isLoading ? null : _updateAppointment,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Update Appointment'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteAppointment,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Delete Appointment'),
        ),
      ],
    );
  }

  Future<void> _deleteAppointment() async {
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

      // Update the appointment document
      AppointmentModel updatedAppointment = AppointmentModel(
        appointmentId: widget.appointment.appointmentId,
        userId: widget.appointment.userId,
        subscriptionId: widget.appointment.subscriptionId,
        meetingType: _meetingType!,
        appointmentDateTime: appointmentDateTime,
        status: _meetingStatus!,
        notes: _notesController.text,
        createdAt: widget.appointment.createdAt,
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .delete();

      logger.info('Appointment deleted successfully for user {}',
          [widget.appointment.userId]);

      // Notify parent widget to refresh data
      widget.onAppointmentUpdated();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully.')),
      );
    } catch (e) {
      logger.err('Error deleting appointment: {}', [e]);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting appointment: $e')),
      );
    }
  }

  Future<void> _updateAppointment() async {
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

      // Update the appointment document
      AppointmentModel updatedAppointment = AppointmentModel(
        appointmentId: widget.appointment.appointmentId,
        userId: widget.appointment.userId,
        subscriptionId: widget.appointment.subscriptionId,
        meetingType: _meetingType!,
        appointmentDateTime: appointmentDateTime,
        status: _meetingStatus!,
        notes: _notesController.text,
        createdAt: widget.appointment.createdAt,
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .collection('appointments')
          .doc(widget.appointment.appointmentId)
          .update(updatedAppointment.toMap());

      logger.info('Appointment updated successfully for user {}',
          [widget.appointment.userId]);

      // Notify parent widget to refresh data
      widget.onAppointmentUpdated();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment updated successfully.')),
      );
    } catch (e) {
      logger.err('Error updating appointment: {}', [e]);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
