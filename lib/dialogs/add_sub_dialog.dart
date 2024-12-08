import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/logger.dart';
import '../models/subs_model.dart';

final Logger logger = Logger.forClass(AddSubscriptionDialog);

class AddSubscriptionDialog extends StatefulWidget {
  final String userId;
  final Function onSubscriptionAdded;

  const AddSubscriptionDialog({
    super.key,
    required this.userId,
    required this.onSubscriptionAdded,
  });

  @override
  createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<AddSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _totalMeetingsController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Abonelik Paketi Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              // Package Name
              TextFormField(
                controller: _packageNameController,
                decoration: const InputDecoration(
                  labelText: 'Paket Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir paket adı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Total Meetings
              TextFormField(
                controller: _totalMeetingsController,
                decoration: const InputDecoration(
                  labelText: 'Toplam Toplantı Sayısı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen toplam toplantı sayısını girin.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Total Amount
              TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(
                  labelText: 'Toplam Ücret',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen toplam ücreti girin.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir ücret girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Start Date
              ListTile(
                title: const Text('Başlangıç Tarihi'),
                subtitle: Text(_startDate != null
                    ? _startDate!.toLocal().toString().split(' ')[0]
                    : 'Bir tarih seçin'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _startDate = pickedDate;
                    });
                    logger.info('Başlangıç tarihi seçildi: {}', [_startDate!]);
                  }
                },
              ),
              const SizedBox(height: 10),

              // End Date
              ListTile(
                title: const Text('Bitiş Tarihi'),
                subtitle: Text(_endDate != null
                    ? _endDate!.toLocal().toString().split(' ')[0]
                    : 'Bir tarih seçin'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                    logger.info('Bitiş tarihi seçildi: {}', [_endDate!]);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addSubscription,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Abonelik Ekle'),
        ),
      ],
    );
  }

  Future<void> _addSubscription() async {
    if (!_formKey.currentState!.validate()) {
      logger.warn('Form doğrulama başarısız.');
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlangıç ve bitiş tarihlerini seçin.')),
      );
      logger.warn('Başlangıç veya bitiş tarihi seçilmedi.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final subscriptionId = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .doc()
          .id;

      SubscriptionModel subscription = SubscriptionModel(
        subscriptionId: subscriptionId,
        userId: widget.userId,
        packageName: _packageNameController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        totalMeetings: int.parse(_totalMeetingsController.text),
        meetingsCompleted: 0,
        meetingsRemaining: int.parse(_totalMeetingsController.text),
        meetingsBurned: 0,
        postponementsUsed: 0,
        allowedPostponementsPerMonth: 1,
        totalAmount: double.parse(_totalAmountController.text),
        amountPaid: 0.0,
        status: SubActiveStatus.active,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .doc(subscriptionId)
          .set(subscription.toMap());

      logger.info('Yeni abonelik eklendi: {}', [subscription]);

      widget.onSubscriptionAdded();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abonelik başarıyla eklendi.')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abonelik eklenirken hata oluştu: $e')),
      );
      logger.err('Abonelik eklenirken hata oluştu: {}', [e]);
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _totalMeetingsController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }
}
