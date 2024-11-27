// edit_payment_dialog.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/logger.dart';
import '../models/payment_model.dart';

class EditPaymentDialog extends StatefulWidget {
  final PaymentModel payment;
  final Function onPaymentUpdated;

  const EditPaymentDialog({
    super.key,
    required this.payment,
    required this.onPaymentUpdated,
  });

  @override
   createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  final Logger logger = Logger.forClass(EditPaymentDialog);

  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedPaymentDate;
  DateTime? _selectedDueDate;
  PaymentStatus _paymentStatus = PaymentStatus.planned;
  File? _dekontImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;


  // New variables for notifications
  bool _enableNotifications = false;
  // final List<bool> _notificationOptions = [false, false, false, false];
  // final List<int> _notificationTimes = [72, 48, 24, 6]; // Hours before due date

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.payment.amount.toString();
    _selectedPaymentDate = widget.payment.paymentDate;
    _selectedDueDate = widget.payment.dueDate;
    _paymentStatus = widget.payment.status;
    // _enableNotifications = widget.payment.notificationTimes != null;
    // if (_enableNotifications && widget.payment.notificationTimes != null) {
    //   for (int i = 0; i < _notificationTimes.length; i++) {
    //     _notificationOptions[i] =
    //         widget.payment.notificationTimes!.contains(_notificationTimes[i]);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ödemeyi Düzenle'),
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

            // Due Date Picker
            ListTile(
              title: Text(_selectedDueDate == null
                  ? 'Planlanan Tarih Seç (Opsiyonel)'
                  : 'Planlanan Tarih: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                //  initialDate: _selectedDueDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDueDate = pickedDate;
                    // If a due date is selected, clear the payment date
                    if (_paymentStatus != PaymentStatus.completed) {
                      _selectedPaymentDate = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Payment Status Dropdown
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
                child: const Text('Dekont Görseli Yükle (Opsiyonel)'),
              ),
              const SizedBox(height: 16),
              _dekontImage != null
                  ? Image.file(
                _dekontImage!,
                height: 100,
              )
                  : widget.payment.dekontUrl != null
                  ? Image.network(
                widget.payment.dekontUrl!,
                height: 100,
              )
                  : const Text('Dekont Görseli Seçilmedi'),
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
          onPressed: _isLoading ? null : () => _updatePayment(),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Ödemeyi Güncelle'),
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

  Future<void> _updatePayment() async {
    if (_amountController.text.isEmpty) {
      logger.warn('Amount is required on _updatePayment.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen miktarı giriniz.')),
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
    // if (_selectedPaymentDate != null &&
    //     _dekontImage == null &&
    //     widget.payment.dekontUrl == null) {
    //   logger.err('Dekont image is required when Payment Date is selected.');
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('Please upload a dekont image.')),
    //     );
    //   }
    //   return;
    // }

    try {
      setState(() {
        _isLoading = true;
      });

      String? dekontUrl = widget.payment.dekontUrl;

      // Upload the new dekont image if it exists
      if (_dekontImage != null) {
        dekontUrl = await _uploadDekontImage();
      }

      // Prepare notification times if enabled
       List<int>? notificationTimes;
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

      // Update the payment document
      PaymentModel updatedPayment = PaymentModel(
        paymentId: widget.payment.paymentId,
        userId: widget.payment.userId,
        subscriptionId: widget.payment.subscriptionId,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedPaymentDate ?? widget.payment.paymentDate,
        status: _paymentStatus,
        dekontUrl: dekontUrl,
        dueDate: _selectedDueDate,
        notificationTimes: notificationTimes,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.payment.userId)
          .collection('payments')
          .doc(widget.payment.paymentId)
          .update(updatedPayment.toMap());

      logger.info('Payment updated successfully for user ${widget.payment.userId}');

      // Optionally, update the subscription's amountPaid if the amount has changed
      // You can implement this logic based on your application's requirements

      // Notify parent widget to refresh data
      widget.onPaymentUpdated();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated successfully.')),
      );
    } catch (e) {
      logger.err('Error updating payment: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating payment: $e')),
      );
    }
  }

  Future<String> _uploadDekontImage() async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${widget.payment.userId}/dekont/$fileName');
      final uploadTask = ref.putFile(_dekontImage!);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.info('Dekont image uploaded to $downloadUrl');

      return downloadUrl;
    } catch (e,s) {
      logger.err('Error uploading dekont image: $s');
      throw Exception('Error uploading dekont image: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
