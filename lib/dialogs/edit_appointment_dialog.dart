import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_manager.dart';

class EditAppointmentDialog extends StatefulWidget {
  final AppointmentModel appointment;
  final Function onAppointmentUpdated;

  const EditAppointmentDialog({
    Key? key,
    required this.appointment,
    required this.onAppointmentUpdated,
  }) : super(key: key);

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  late MeetingType _meetingType;
  late AppointmentStatus _appointmentStatus;
  late DateTime _appointmentDateTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meetingType = widget.appointment.meetingType;
    _appointmentStatus = widget.appointment.status;
    _appointmentDateTime = widget.appointment.appointmentDateTime;
    _notesController.text = widget.appointment.notes ?? '';
  }

  Future<void> _updateAppointment() async {
    try {
      final appointmentManager =
      Provider.of<AppointmentManager>(context, listen: false);

      // Build the updated appointment object
      AppointmentModel updatedAppointment = AppointmentModel(
        appointmentId: widget.appointment.appointmentId,
        userId: widget.appointment.userId,
        subscriptionId: widget.appointment.subscriptionId,
        meetingType: _meetingType,
        appointmentDateTime: _appointmentDateTime,
        status: _appointmentStatus,
        notes: _notesController.text,
        createdAt: widget.appointment.createdAt,
        updatedAt: DateTime.now(),
        createdBy: widget.appointment.createdBy,
        canceledBy: widget.appointment.canceledBy,
        canceledAt: widget.appointment.canceledAt,
      );

      // Send update to Firestore
      await appointmentManager.updateAppointment(updatedAppointment);

      // Notify parent & close
      widget.onAppointmentUpdated();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    }
  }

  Future<void> _cancelAppointment() async {
    // Ask the user to confirm cancellation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed
    if (confirm == true) {
      try {
        final appointmentManager =
        Provider.of<AppointmentManager>(context, listen: false);

        // Indicate who canceled it. Adjust as needed ("user", "admin", etc.).
        final success = await appointmentManager.cancelAppointment(
          widget.appointment.appointmentId,
          widget.appointment.userId,
          canceledBy: 'User',
        );

        if (success) {
          if (!mounted) return;
          // Show success dialog, then close everything
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Appointment Canceled'),
                content:
                const Text('Your appointment has been canceled successfully.'),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // close success dialog
                      Navigator.of(context).pop(); // close edit dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error canceling appointment')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Appointment'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // 1) Meeting Type
            ListTile(
              title: const Text('Meeting Type'),
              trailing: DropdownButton<MeetingType>(
                value: _meetingType,
                onChanged: (MeetingType? newValue) {
                  setState(() {
                    _meetingType = newValue!;
                  });
                },
                items: MeetingType.values.map<DropdownMenuItem<MeetingType>>(
                      (MeetingType type) {
                    return DropdownMenuItem<MeetingType>(
                      value: type,
                      child: Text(type.label),
                    );
                  },
                ).toList(),
              ),
            ),
            // 2) Appointment Status
            ListTile(
              title: const Text('Appointment Status'),
              trailing: DropdownButton<AppointmentStatus>(
                value: _appointmentStatus,
                onChanged: (AppointmentStatus? newValue) {
                  setState(() {
                    _appointmentStatus = newValue!;
                  });
                },
                items: AppointmentStatus.values
                    .map<DropdownMenuItem<AppointmentStatus>>(
                        (AppointmentStatus status) {
                      return DropdownMenuItem<AppointmentStatus>(
                        value: status,
                        child: Text(status.label),
                      );
                    }).toList(),
              ),
            ),
            // 3) Date & Time
            ListTile(
              title: Text(
                'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(_appointmentDateTime)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _appointmentDateTime,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  if (!context.mounted) return;
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_appointmentDateTime),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _appointmentDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                }
              },
            ),
            // 4) Notes
            ElevatedButton(
              onPressed: _cancelAppointment,
              child: const Text('Cancel Appointment'),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        // Renamed "Cancel" to "Close" to avoid confusion
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        // Save button
        ElevatedButton(
          onPressed: _updateAppointment,
          child: const Text('Save'),
        )
        // Cancel Appointment button
        // ElevatedButton(
        //   onPressed: _cancelAppointment,
        //   child: const Text('Cancel Appointment'),
        // ),
      ],
    );
  }
}
