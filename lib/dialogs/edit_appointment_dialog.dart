import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_manager.dart';
import 'package:provider/provider.dart';

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
  late MeetingType _meetingType;
  late DateTime _appointmentDateTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meetingType = widget.appointment.meetingType;
    _appointmentDateTime = widget.appointment.appointmentDateTime;
    _notesController.text = widget.appointment.notes ?? '';
  }

  Future<void> _updateAppointment() async {
    try {
      final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
      appointmentManager.setUserId(widget.appointment.userId);

      AppointmentModel updatedAppointment = AppointmentModel(
        appointmentId: widget.appointment.appointmentId,
        userId: widget.appointment.userId,
        subscriptionId: widget.appointment.subscriptionId,
        meetingType: _meetingType,
        appointmentDateTime: _appointmentDateTime,
        status: widget.appointment.status,
        notes: _notesController.text,
        createdAt: widget.appointment.createdAt,
        updatedAt: DateTime.now(),
        createdBy: widget.appointment.createdBy,
        canceledBy: widget.appointment.canceledBy,
        canceledAt: widget.appointment.canceledAt,
      );

      await appointmentManager.updateAppointment(updatedAppointment);

      widget.onAppointmentUpdated();
      if(!mounted)return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Appointment'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text('Meeting Type'),
              trailing: DropdownButton<MeetingType>(
                value: _meetingType,
                onChanged: (MeetingType? newValue) {
                  setState(() {
                    _meetingType = newValue!;
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
            ),
            ListTile(
              title: Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(_appointmentDateTime)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _appointmentDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
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
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateAppointment,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
