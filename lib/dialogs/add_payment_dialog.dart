// dialogs/add_payment_dialog.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/logger.dart';
import '../models/subs_model.dart';
import '../providers/payment_provider.dart';

class AddPaymentDialog extends StatefulWidget {
  final String userId;
  final Function onPaymentAdded;
  final SubscriptionModel subscription;

  const AddPaymentDialog({
    Key? key,
    required this.userId,
    required this.onPaymentAdded,
    required this.subscription,
  }) : super(key: key);

  @override
  _AddPaymentDialogState createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final Logger logger = Logger.forClass(AddPaymentDialog);

  // Controllers and variables
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedPaymentDate;
  DateTime? _selectedDueDate;
  String _paymentStatus = 'Pending';
  File? _dekontImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // New variables for notifications
  bool _enableNotifications = false;
  final List<bool> _notificationOptions = [false, false, false, false];
  final List<int> _notificationTimes = [72, 48, 24, 6]; // Hours before due date

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDueDate == null
                  ? 'Select Due Date (Optional)'
                  : 'Due Date: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDueDate = pickedDate;
                    // If a due date is selected, clear the payment date
                    _selectedPaymentDate = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDueDate == null) ...[
              // Show payment date selection only if no due date is selected
              ListTile(
                title: Text(_selectedPaymentDate == null
                    ? 'Select Payment Date'
                    : 'Payment Date: ${_selectedPaymentDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedPaymentDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedPaymentDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickDekontImage(),
                child: const Text('Upload Dekont Image'),
              ),
              const SizedBox(height: 16),
              _dekontImage != null
                  ? Image.file(
                _dekontImage!,
                height: 100,
              )
                  : const Text('No image selected'),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentStatus,
              items: ['Completed', 'Pending', 'Failed'].map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _paymentStatus = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Payment Status'),
            ),
            const SizedBox(height: 16),
            if (_selectedDueDate != null) ...[
              CheckboxListTile(
                title: const Text('Enable Notifications'),
                value: _enableNotifications,
                onChanged: (bool? value) {
                  setState(() {
                    _enableNotifications = value ?? false;
                  });
                },
              ),
              if (_enableNotifications)
                Column(
                  children: [
                    const Text('Remind me before:'),
                    CheckboxListTile(
                      title: const Text('3 days'),
                      value: _notificationOptions[0],
                      onChanged: (bool? value) {
                        setState(() {
                          _notificationOptions[0] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('2 days'),
                      value: _notificationOptions[1],
                      onChanged: (bool? value) {
                        setState(() {
                          _notificationOptions[1] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('1 day'),
                      value: _notificationOptions[2],
                      onChanged: (bool? value) {
                        setState(() {
                          _notificationOptions[2] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('6 hours'),
                      value: _notificationOptions[3],
                      onChanged: (bool? value) {
                        setState(() {
                          _notificationOptions[3] = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
            ],
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
          onPressed: _isLoading ? null : () => _addPayment(context),
          child: _isLoading ? const CircularProgressIndicator() : const Text('Add Payment'),
        ),
      ],
    );
  }

  Future<void> _pickDekontImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _dekontImage = File(pickedFile.path);
        logger.info('Dekont image selected: ${pickedFile.path}');
      } else {
        logger.err('No dekont image selected.');
      }
    });
  }

  Future<void> _addPayment(BuildContext context) async {
    if (_amountController.text.isEmpty) {
      logger.err('Amount is required.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the amount.')),
        );
      }
      return;
    }

    if (_selectedDueDate == null && _selectedPaymentDate == null) {
      logger.err('Either Payment Date or Due Date must be selected.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payment date or a due date.')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare notification times if enabled
      List<int>? notificationTimes;
      if (_enableNotifications && _selectedDueDate != null) {
        notificationTimes = [];
        for (int i = 0; i < _notificationOptions.length; i++) {
          if (_notificationOptions[i]) {
            notificationTimes.add(_notificationTimes[i]);
          }
        }
        if (notificationTimes.isEmpty) {
          logger.err('At least one notification time must be selected.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select at least one notification time.')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

      await paymentProvider.addPayment(
        userId: widget.userId,
        subscription: widget.subscription,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedPaymentDate,
        status: _paymentStatus,
        dekontImage: _dekontImage,
        dueDate: _selectedDueDate,
        notificationTimes: notificationTimes,
      );

      // Notify parent widget to refresh data
      widget.onPaymentAdded();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment added successfully.')),
      );
    } catch (e) {
      logger.err('Error adding payment: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding payment: $e')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
