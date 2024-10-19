// add_subscription_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subs_model.dart';

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
      title: const Text('Add Subscription Package'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: [
              TextFormField(
                controller: _packageNameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter package name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalMeetingsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Meetings'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total meetings';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? 'Select Start Date'
                    : 'Start Date: ${_startDate!.toLocal().toString().split(' ')[0]}'),
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
                    ? 'Select End Date'
                    : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}'),
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
            ],
          ),
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
          onPressed: _isLoading ? null : _addSubscription,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Add Subscription'),
        ),
      ],
    );
  }

  Future<void> _addSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.')),
      );
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

      // Notify parent widget to refresh data
      widget.onSubscriptionAdded();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription added successfully.')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding subscription: $e')),
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
