import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_manager.dart';
import '../dialogs/edit_appointment_dialog.dart';
import 'basetab.dart';

class AppointmentsTab extends BaseTab<AppointmentManager> {
  const AppointmentsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Appointments',
    subscriptionDataLabel: 'Subscription Appointments',
  );

  @override
  AppointmentManager getProvider(BuildContext context) {
    return Provider.of<AppointmentManager>(context);
  }

  @override
  List<dynamic> getDataList(AppointmentManager provider) {
    return provider.userAppointments;
  }

  @override
  bool getShowAllData(AppointmentManager provider) {
    return provider.showAllAppointments;
  }

  @override
  void setShowAllData(AppointmentManager provider, bool value) {
    provider.setShowAllAppointments(value);
    if (!value) {
      provider.setSelectedSubscriptionId(provider.selectedSubscriptionId);
    }
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<AppointmentModel> appointments = dataList.cast<AppointmentModel>();
    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        AppointmentModel appointment = appointments[index];
        return ListTile(
          title: Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
          subtitle: Text(
              'Type: ${appointment.meetingType.label}\nStatus: ${appointment.status.label}\nCanceled By: ${appointment.canceledBy ?? 'N/A'}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditAppointmentDialog(context, appointment);
            },
          ),
        );
      },
    );
  }

  void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () {
            Provider.of<AppointmentManager>(context, listen: false)
                .fetchAppointments();
          },
        );
      },
    );
  }
}
// tabs/base_tab.dart
// managers/loadable.dart
import 'package:flutter/material.dart';
mixin Loadable {
  bool get isLoading;
}



abstract class BaseTab<T extends Loadable> extends StatelessWidget {
  final String userId;
  final String allDataLabel;
  final String subscriptionDataLabel;

  const BaseTab({
    super.key,
    required this.userId,
    required this.allDataLabel,
    required this.subscriptionDataLabel,
  });

  T getProvider(BuildContext context);

  List<dynamic> getDataList(T provider);

  Widget buildList(BuildContext context, List<dynamic> dataList);

  bool getShowAllData(T provider);

  void setShowAllData(T provider, bool value);

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dataList = getDataList(provider);

    return Column(
      children: [
        // Toggle Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(getShowAllData(provider) ? allDataLabel : subscriptionDataLabel),
            Switch(
              value: getShowAllData(provider),
              onChanged: (value) {
                setShowAllData(provider, value);
              },
            ),
          ],
        ),
        Expanded(
          child: dataList.isEmpty
              ? const Center(child: Text('No data found.'))
              : buildList(context, dataList),
        ),
      ],
    );
  }
}
// tabs/details_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class DetailsTab extends StatelessWidget {
  final String userId;

  const DetailsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Fetch user details if not already fetched
    if (userProvider.user == null && !userProvider.isLoading) {
      userProvider.fetchUserDetails();
    }

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.user == null) {
      return const Center(child: Text('No user details available.'));
    }

    final user = userProvider.user!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          title: const Text('Name'),
          subtitle: Text(user.name),
        ),
        ListTile(
          title: const Text('Email'),
          subtitle: Text(user.email),
        ),
        // Add more user details as needed
      ],
    );
  }
}
// tabs/images_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/meal_state_and_upload_manager.dart';
import 'basetab.dart';

class ImagesTab extends BaseTab<MealStateManager> {
  const ImagesTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Images',
    subscriptionDataLabel: 'Subscription Images',
  );

  @override
  MealStateManager getProvider(BuildContext context) {
    return Provider.of<MealStateManager>(context);
  }

  @override
  List<MealModel> getDataList(MealStateManager provider) {
    return provider.meals;
  }

  @override
  bool getShowAllData(MealStateManager provider) {
    return provider.showAllImages;
  }

  @override
  void setShowAllData(MealStateManager provider, bool value) {
    provider.setShowAllImages(value);
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<MealModel> meals = dataList.cast<MealModel>();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        MealModel meal = meals[index];
        return InkWell(
          onTap: () {
            _showFullImage(context, meal.imageUrl, meal);
          },
          child: Image.network(
            meal.imageUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl, MealModel meal) {
    // Implement your image viewer dialog
  }
}
// tabs/payments_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/edit_payment_dialog.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import 'basetab.dart';

class PaymentsTab extends BaseTab<PaymentProvider> {
  const PaymentsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Payments',
    subscriptionDataLabel: 'Subscription Payments',
  );

  @override
  PaymentProvider getProvider(BuildContext context) {
    return Provider.of<PaymentProvider>(context);
  }

  @override
  List<PaymentModel> getDataList(PaymentProvider provider) {
    return provider.payments;
  }

  @override
  bool getShowAllData(PaymentProvider provider) {
    return provider.showAllPayments;
  }

  @override
  void setShowAllData(PaymentProvider provider, bool value) {
    provider.setShowAllPayments(value);
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<PaymentModel> payments = dataList.cast<PaymentModel>();
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        PaymentModel payment = payments[index];
        return ListTile(
          title: Text('Amount: ${payment.amount}'),
          subtitle: Text(
              'Payment Date: ${payment.paymentDate.toLocal().toString().split(' ')[0]}\nDue Date: ${payment.dueDate?.toLocal().toString().split(' ')[0] ?? '-'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${payment.status}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditPaymentDialog(context, payment);
                },
              ),
            ],
          ),
          onTap: () {
            // Handle onTap if necessary
          },
        );
      },
    );
  }

  void _showEditPaymentDialog(BuildContext context, PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditPaymentDialog(
            payment: payment,
            onPaymentUpdated:() {  Provider.of<PaymentProvider>(context, listen: false)
                .fetchPayments();}
        );
      },
    );
  }
}

// tabs/subscriptions_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/logger.dart';
import '../models/subs_model.dart';
import '../providers/user_provider.dart';
import 'basetab.dart';

final Logger logger = Logger.forClass(SubscriptionsTab);

class SubscriptionsTab extends BaseTab<UserProvider> {
  const SubscriptionsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Subscriptions',
    subscriptionDataLabel: 'Active Subscriptions',
  );

  @override
  UserProvider getProvider(BuildContext context) {
    return Provider.of<UserProvider>(context);
  }

  @override
  List<SubscriptionModel> getDataList(UserProvider provider) {
    return provider.subscriptions;
  }

  @override
  bool getShowAllData(UserProvider provider) {
    return provider.showAllSubscriptions;
  }

  @override
  void setShowAllData(UserProvider provider, bool value) {
    provider.setShowAllSubscriptions(value);
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<SubscriptionModel> subscriptions = dataList.cast<SubscriptionModel>();
    return ListView.builder(
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        SubscriptionModel subscription = subscriptions[index];
        return ListTile(
          title: Text(subscription.packageName),
          subtitle: Text(
              'Start Date: ${subscription.startDate.toLocal().toString().split(' ')[0]}\n'
                  'End Date: ${subscription.endDate.toLocal().toString().split(' ')[0]}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${subscription.status.label}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditSubscriptionDialog(context, subscription);
                },
              ),
            ],
          ),
          onTap: () {
            // Handle onTap if necessary
          },
        );
      },
    );
  }

  void _showEditSubscriptionDialog(
      BuildContext context, SubscriptionModel subscription) {
    showDialog(
      context: context,
      builder: (context) {
        return EditSubscriptionDialog(
          subscription: subscription,
          onSubscriptionUpdated: () {
            Provider.of<UserProvider>(context, listen: false).fetchSubscriptions();
          },
        );
      },
    );
  }
}

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
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
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
                  if (double.tryParse(value) == null) {
                    return 'Invalid amount';
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
                decoration: const InputDecoration(labelText: 'Subscription Status'),
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
              : const Text('Update Subscription'),
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
        const SnackBar(content: Text('Please select start and end dates.')),
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
// tabs/tests_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_model.dart';
import '../providers/test_provider.dart';
import 'basetab.dart';

class TestsTab extends BaseTab<TestProvider> {
  const TestsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Tests',
    subscriptionDataLabel: 'Subscription Tests',
  );

  @override
  TestProvider getProvider(BuildContext context) {
    return Provider.of<TestProvider>(context);
  }r

  @override
  List<TestModel> getDataList(TestProvider provider) {
    return provider.tests;
  }

  @override
  bool getShowAllData(TestProvider provider) {
    return provider.showAllTests;
  }

  @override
  void setShowAllData(TestProvider provider, bool value) {
    provider.setShowAllTests(value);
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<TestModel> tests = dataList.cast<TestModel>();
    return ListView.builder(
      itemCount: tests.length,
      itemBuilder: (context, index) {
        TestModel test = tests[index];
        return ListTile(
          title: Text('Test Name: ${test.testName}'),
          subtitle: Text(
              'Date: ${test.testDate.toLocal().toString().split(' ')[0]}'),
          onTap: () {
            // Handle onTap if necessary
          },
        );
      },
    );
  }
}
