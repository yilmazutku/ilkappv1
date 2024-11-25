import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/subs_model.dart';

class EditSubscriptionDialog extends StatefulWidget {
  final SubscriptionModel subscription;
  final VoidCallback onSubscriptionUpdated;

  const EditSubscriptionDialog({
    super.key,
    required this.subscription,
    required this.onSubscriptionUpdated,
  });

  @override
  createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<EditSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _packageNameController;
  late TextEditingController _totalMeetingsController;
  late TextEditingController _totalAmountController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  late SubActiveStatus _status;

  @override
  void initState() {
    super.initState();
    _packageNameController = TextEditingController(text: widget.subscription.packageName);
    _totalMeetingsController = TextEditingController(text: widget.subscription.totalMeetings.toString());
    _totalAmountController = TextEditingController(text: widget.subscription.totalAmount.toString());
    _startDate = widget.subscription.startDate;
    _endDate = widget.subscription.endDate;
    _status = widget.subscription.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Subscription'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              TextFormField(
                controller: _packageNameController,
                decoration: const InputDecoration(labelText: 'Paket İsmi'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen paket ismini giriniz./n(ör: 1 ay,ekim-kasım)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalMeetingsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Toplam Görüşme Sayısını'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Toplam görüşme sayısını giriniz.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçersiz görüşme sayısı. Lütfen girdiğiniz sayıyı kontrol ediniz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Toplam Ödeme Miktarı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen toplam ödeme miktarını giriniz.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçersiz ödeme miktarı. Lütfen kontrol ediniz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? 'Başlangıç Tarihi Seçimi'
                    : 'Başlangıç Tarihi: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _startDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_endDate == null
                    ? 'Bitiş Tarihi Seçimi'
                    : 'Bitiş Tarihi: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime initialDate = _startDate != null
                      ? _startDate!.add(const Duration(days: 30))
                      : DateTime.now().add(const Duration(days: 30));
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? initialDate,
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubActiveStatus>(
                value: _status,
                items: SubActiveStatus.values.map((SubActiveStatus status) {
                  return DropdownMenuItem<SubActiveStatus>(
                    value: status,
                    child: Text(status.label),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Paket Durumu'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateSubscription,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Paket Güncelle'),
        ),
      ],
    );
  }

  Future<void> _updateSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlangıç/bitiş tarihlerini seçiniz.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = widget.subscription.userId;
      final subscriptionId = widget.subscription.subscriptionId;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .doc(subscriptionId)
          .update({
        'packageName': _packageNameController.text,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'totalMeetings': int.parse(_totalMeetingsController.text),
        'totalAmount': double.parse(_totalAmountController.text),
        'status': _status.label,
        // Update other fields as necessary
      });

      widget.onSubscriptionUpdated();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating subscription: $e')),
      );
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