import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../commons/logger.dart';
import '../commons/userclass.dart';

class AddPaymentDialog extends StatefulWidget {
  final String userId;
  final Function onPaymentAdded;

  const AddPaymentDialog({
    Key? key,
    required this.userId,
    required this.onPaymentAdded,
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
  List<bool> _notificationOptions = [false, false, false, false];
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
          onPressed: _isLoading ? null : () => _addPayment(),
          child:
          _isLoading ? const CircularProgressIndicator() : const Text('Add Payment'),
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

  Future<void> _addPayment() async {
    if (_amountController.text.isEmpty) {
      logger.err('Amount is required.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the amount.')),
      );
      return;
    }

    if (_selectedDueDate == null && _selectedPaymentDate == null) {
      logger.err('Either Payment Date or Due Date must be selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment date or a due date.')),
      );
      return;
    }

    if (_selectedPaymentDate != null && _dekontImage == null) {
      logger.err('Dekont image is required when Payment Date is selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a dekont image.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String? dekontUrl;

      // Upload the dekont image if it exists
      if (_dekontImage != null) {
        dekontUrl = await _uploadDekontImage();
      }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one notification time.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create a new payment document
      final paymentDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('payments')
          .doc(); // Generate a new payment ID

      PaymentModel paymentModel = PaymentModel(
        paymentId: paymentDocRef.id,
        userId: widget.userId,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedPaymentDate ?? DateTime.now(),
        status: _paymentStatus,
        dekontUrl: dekontUrl,
        dueDate: _selectedDueDate,
        notificationTimes: notificationTimes,
      );

      await paymentDocRef.set(paymentModel.toMap());
      logger.info('Payment added successfully for user ${widget.userId}');

      // Notify parent widget to refresh data
      widget.onPaymentAdded();

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment added successfully.')),
      );
    } catch (e) {
      logger.err('Error adding payment: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding payment: $e')),
      );
    }
  }

  Future<String> _uploadDekontImage() async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${widget.userId}/dekont/$fileName');
      final uploadTask = ref.putFile(_dekontImage!);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.info('Dekont image uploaded to $downloadUrl');

      return downloadUrl;
    } catch (e) {
      logger.err('Error uploading dekont image: $e');
      throw Exception('Error uploading dekont image: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class EditPaymentDialog extends StatefulWidget {
  final PaymentModel payment;
  final Function onPaymentUpdated;

  const EditPaymentDialog({
    Key? key,
    required this.payment,
    required this.onPaymentUpdated,
  }) : super(key: key);

  @override
  _EditPaymentDialogState createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  final Logger logger = Logger.forClass(EditPaymentDialog);

  // Controllers and variables
  late TextEditingController _amountController;
  File? _dekontImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _dekontDeleted = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.payment.amount.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Payment'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            if (widget.payment.status == 'Completed') ...[
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickDekontImage(),
                    child: const Text('Upload Dekont Image'),
                  ),
                  const SizedBox(width: 8),
                  if (widget.payment.dekontUrl != null && !_dekontDeleted)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteDekontImage(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_dekontImage != null)
                GestureDetector(
                  onTap: () => _viewDekontImage(_dekontImage!.path, isFile: true),
                  child: Image.file(
                    _dekontImage!,
                    height: 100,
                  ),
                )
              else if (widget.payment.dekontUrl != null && !_dekontDeleted)
                GestureDetector(
                  onTap: () => _viewDekontImage(widget.payment.dekontUrl!),
                  child: Image.network(
                    widget.payment.dekontUrl!,
                    height: 100,
                  ),
                )
              else
                const Text('No dekont image available'),
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
          onPressed: _isLoading ? null : () => _updatePayment(),
          child:
          _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
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
        _dekontDeleted = false; // Reset delete flag if a new image is selected
      } else {
        logger.err('No dekont image selected.');
      }
    });
  }

  void _deleteDekontImage() {
    setState(() {
      _dekontImage = null;
      _dekontDeleted = true;
      logger.info('Dekont image marked for deletion.');
    });
  }

  Future<void> _updatePayment() async {
    if (_amountController.text.isEmpty) {
      logger.err('Amount is required.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the amount.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String? dekontUrl = widget.payment.dekontUrl;

      // If dekont image is marked for deletion
      if (_dekontDeleted) {
        dekontUrl = null;
        // Delete the image from Firebase Storage
        await _deleteDekontFromStorage(widget.payment.dekontUrl);
      }

      // Upload the new dekont image if it exists
      if (_dekontImage != null) {
        dekontUrl = await _uploadDekontImage();
      }

      // Update the payment document
      final paymentDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.payment.userId)
          .collection('payments')
          .doc(widget.payment.paymentId);

      PaymentModel updatedPayment = PaymentModel(
        paymentId: widget.payment.paymentId,
        userId: widget.payment.userId,
        amount: double.parse(_amountController.text),
        paymentDate: widget.payment.paymentDate,
        status: widget.payment.status,
        dekontUrl: dekontUrl,
        dueDate: widget.payment.dueDate,
        notificationTimes: widget.payment.notificationTimes,
      );

      await paymentDocRef.update(updatedPayment.toMap());
      logger.info('Payment updated successfully for payment ID ${widget.payment.paymentId}');

      // Notify parent widget to refresh data
      widget.onPaymentUpdated();

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated successfully.')),
      );
    } catch (e) {
      logger.err('Error updating payment: $e');
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
    } catch (e) {
      logger.err('Error uploading dekont image: $e');
      throw Exception('Error uploading dekont image: $e');
    }
  }

  Future<void> _deleteDekontFromStorage(String? dekontUrl) async {
    if (dekontUrl == null) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(dekontUrl);
      await ref.delete();
      logger.info('Dekont image deleted from storage.');
    } catch (e) {
      logger.err('Error deleting dekont image from storage: $e');
    }
  }

  void _viewDekontImage(String dekontUrl, {bool isFile = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DekontViewerPage(
          dekontUrl: dekontUrl,
          isFile: isFile,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}


class DekontViewerPage extends StatefulWidget {
  final String dekontUrl;
  final bool isFile; // True if the dekont is a local file

  const DekontViewerPage({
    Key? key,
    required this.dekontUrl,
    this.isFile = false,
  }) : super(key: key);

  @override
  _DekontViewerPageState createState() => _DekontViewerPageState();
}

class _DekontViewerPageState extends State<DekontViewerPage> {
  final Logger logger = Logger.forClass(DekontViewerPage);
  bool _isPdf = false;

  @override
  void initState() {
    super.initState();
    _isPdf = widget.dekontUrl.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dekont Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadDekont(context),
          ),
        ],
      ),
      body: _isPdf
          ? Center(child: Text('PDF viewing not implemented.'))
          : Center(
        child: widget.isFile
            ? Image.file(File(widget.dekontUrl))
            : Image.network(widget.dekontUrl),
      ),
    );
  }

  Future<void> _downloadDekont(BuildContext context) async {
    try {
      // Request storage permission if necessary
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          logger.err('Storage permission not granted.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Storage permission is required to download files.')),
          );
          return;
        }
      }

      // Prepare the download path
      final dir = await getExternalStorageDirectory();
      final fileName = widget.dekontUrl.split('/').last;
      final filePath = '${dir!.path}/$fileName';

      // Download the file
      final dio = Dio();
      if (widget.isFile) {
        // Copy the local file
        final file = File(widget.dekontUrl);
        await file.copy(filePath);
      } else {
        // Download from URL
        await dio.download(widget.dekontUrl, filePath);
      }

      logger.info('Dekont downloaded to $filePath');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dekont downloaded to $filePath')),
      );
    } catch (e) {
      logger.err('Error downloading dekont: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading dekont: $e')),
      );
    }
  }
}


