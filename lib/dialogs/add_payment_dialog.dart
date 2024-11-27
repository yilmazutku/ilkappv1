// dialogs/add_payment_dialog.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/logger.dart';
import '../models/payment_model.dart';
import '../models/subs_model.dart';
import '../providers/payment_provider.dart';

class AddPaymentDialog extends StatefulWidget {
  final String userId;
  final Function onPaymentAdded;
  final SubscriptionModel subscription;

  const AddPaymentDialog({
    super.key,
    required this.userId,
    required this.onPaymentAdded,
    required this.subscription,
  });

  @override
   createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final Logger logger = Logger.forClass(AddPaymentDialog);

  @override
  void initState() {
    _paymentStatus= PaymentStatus.completed;
  }

  // Controllers and variables
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedPaymentDate;
  DateTime? _selectedDueDate;
  PaymentStatus _paymentStatus = PaymentStatus.completed;
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
      title: const Text('Ödeme Ekle'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Miktar'),
            ),
            const SizedBox(height: 16),
            //PAyment status dropdown
            DropdownButtonFormField<PaymentStatus>(
              value: _paymentStatus,
              items: PaymentStatus.values.map((PaymentStatus status) {
                return DropdownMenuItem<PaymentStatus>(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _paymentStatus = newValue!;
                  // If status is not completed, clear payment date
                  if (_paymentStatus != PaymentStatus.completed) {
                    _selectedPaymentDate = null;
                  }
                });
              },
              decoration: const InputDecoration(labelText: 'Ödeme Durumu'),
            ),
            const SizedBox(height: 16),
            // Due Date Picker
            ListTile(
              title: Text(_selectedDueDate == null
                  ? 'Planlanan Tarih Seç (Opsiyonel)'
                  : 'Planlanan Tarih: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}'),
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
                    // If a due date is selected and status is not 'Tamamlandı', clear payment date
                    if (_paymentStatus != PaymentStatus.completed) {
                      _selectedPaymentDate = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Payment Date Picker (Visible only when status is 'Tamamlandı')
            if (_paymentStatus == PaymentStatus.completed) ...[
              ListTile(
                title: Text(_selectedPaymentDate == null
                    ? 'Ödeme Tarihi Seç'
                    : 'Ödeme Tarihi: ${_selectedPaymentDate!.toLocal().toString().split(' ')[0]}'),
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
                child: const Text('Dekont Yükle (Opsiyonel)'),
              ),
              const SizedBox(height: 16),
              _dekontImage != null
                  ? Image.file(
                _dekontImage!,
                height: 100,
              )
                  : const Text('Dekont Seçilmedi'),
            ],

            // Notifications (Optional)
            // ... (if needed)
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _addPayment(context),
          child: _isLoading ? const CircularProgressIndicator() : const Text('Ödeme Ekle'),
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
      logger.err('_addPayment: Amount is required.');
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

    if (_paymentStatus == PaymentStatus.completed && _selectedPaymentDate == null) {
      // Show error: Payment date is required when status is 'Tamamlandı'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen ödeme tarihini seçiniz.')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare notification times if enabled
      // List<int>? notificationTimes;
      // if (_enableNotifications && _selectedDueDate != null) {
      //   notificationTimes = [];
      //   for (int i = 0; i < _notificationOptions.length; i++) {
      //     if (_notificationOptions[i]) {
      //       notificationTimes.add(_notificationTimes[i]);
      //     }
      //   }
      //   if (notificationTimes.isEmpty) {
      //     logger.err('At least one notification time must be selected.');
      //     if (mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Please select at least one notification time.')),
      //       );
      //     }
      //     setState(() {
      //       _isLoading = false;
      //     });
      //     return;
      //   }
      // }

      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

      await paymentProvider.addPayment(
        userId: widget.userId,
        subscription: widget.subscription,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedPaymentDate,
        status: _paymentStatus,
        dekontImage: _dekontImage,
        dueDate: _selectedDueDate,
        notificationTimes: [],//notificationTimes,
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
