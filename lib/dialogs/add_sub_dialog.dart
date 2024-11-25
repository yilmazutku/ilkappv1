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
          child: const ListBody(
            children: [
              // Your form fields here
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
