// customer_summary_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/add_image_dialog.dart';
import '../models/subs_model.dart';
import '../providers/appointment_manager.dart';
import '../providers/meal_state_and_upload_manager.dart';
import '../providers/payment_provider.dart';
import '../providers/user_provider.dart';
import '../tabs/details_tab.dart';
import '../tabs/appointments_tab.dart';
import '../tabs/images_tab.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_payment_dialog.dart';
import '../dialogs/add_test_dialog.dart';
import '../tabs/payment_tab.dart';

class CustomerSummaryPage extends StatefulWidget {
  final String userId;

  const CustomerSummaryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CustomerSummaryPageState createState() => _CustomerSummaryPageState();
}

class _CustomerSummaryPageState extends State<CustomerSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    // Fetch initial data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.fetchUserDetails(widget.userId).then((_) {
      setState(() {
        isLoading = false;
      });

      // Set userId in other providers
      Provider.of<AppointmentManager>(context, listen: false)
          .setUserId(widget.userId);
      Provider.of<MealStateManager>(context, listen: false)
          .setUserId(widget.userId);
      Provider.of<PaymentProvider>(context, listen: false)
          .setUserId(widget.userId);
      // Similarly for TestProvider if needed
    });

    // Listen for tab changes to refresh data if needed
    _tabController.addListener(() {
      setState(() {}); // Rebuilds the AppBar when the tab index changes
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    String title = 'Customer Summary';
    if (userProvider.user != null) {
      title = '${userProvider.user!.name}\'s Summary';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          _buildSubscriptionDropdown(context),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _onAddButtonPressed();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Appointments'),
            Tab(text: 'Payments'),
            Tab(text: 'Images'),
            Tab(text: 'Tests'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          DetailsTab(userId: widget.userId),
          AppointmentsTab(userId: widget.userId),
          PaymentsTab(userId: widget.userId),
          ImagesTab(userId: widget.userId),
          Center(child: Text('Tests Tab')), // Placeholder
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddButtonPressed(),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubscriptionDropdown(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final appointmentManager =
    Provider.of<AppointmentManager>(context, listen: false);
    final mealManager =
    Provider.of<MealStateManager>(context, listen: false);
    final paymentProvider =
    Provider.of<PaymentProvider>(context, listen: false);
    // final testProvider = Provider.of<TestProvider>(context, listen: false);

    // Use the subscriptions from userProvider
    if (userProvider.subscriptions.isEmpty) {
      return Container();
    }

    return DropdownButton<SubscriptionModel>(
      value: userProvider.selectedSubscription,
      onChanged: (SubscriptionModel? newValue) {
        userProvider.selectSubscription(newValue);

        final subscriptionId = newValue?.subscriptionId;

        // Update providers with new subscriptionId
        appointmentManager.setSelectedSubscriptionId(subscriptionId);
        mealManager.setSelectedSubscriptionId(subscriptionId);
        paymentProvider.setSelectedSubscriptionId(subscriptionId);
        // testProvider.setSelectedSubscriptionId(subscriptionId);
      },
      items: userProvider.subscriptions
          .map<DropdownMenuItem<SubscriptionModel>>((SubscriptionModel sub) {
        return DropdownMenuItem<SubscriptionModel>(
          value: sub,
          child: Text(
              '${sub.packageName} (${sub.startDate.toLocal().toString().split(' ')[0]})'),
        );
      }).toList(),
    );
  }

  void _onAddButtonPressed() {
    int currentIndex = _tabController.index;
    switch (currentIndex) {
      case 1:
        _showAddAppointmentDialog();
        break;
      case 2:
        _showAddPaymentDialog();
        break;
      case 3:
        _showAddImageDialog();
        break;
      case 4:
        _showAddTestDialog();
        break;
      default:
      // You can handle the Details tab or other tabs if necessary
        break;
    }
  }

  void _showAddAppointmentDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscriptionId = userProvider.selectedSubscription?.subscriptionId;

    if (subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AddAppointmentDialog(
          userId: userId,
          subscriptionId: subscriptionId,
          onAppointmentAdded: () {
            Provider.of<AppointmentManager>(context, listen: false)
                .fetchAppointments();
          },
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscription = userProvider.selectedSubscription;

    if (subscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AddPaymentDialog(
          userId: userId,
          subscription: subscription, // Pass the full subscription object
          onPaymentAdded: () {
            Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
          },
        );
      },
    );
  }


  void _showAddImageDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscriptionId = userProvider.selectedSubscription?.subscriptionId;

    if (subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AddImageDialog(
          userId: userId,
          subscriptionId: subscriptionId,
          onImageAdded: () {
            Provider.of<MealStateManager>(context, listen: false).fetchMeals();
          },
        );
      },
    );
  }

  void _showAddTestDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscriptionId = userProvider.selectedSubscription?.subscriptionId;

    if (subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AddTestDialog(
          userId: userId,
          onTestAdded: () {
            // Implement fetchTests or similar method in the relevant provider
            // Provider.of<TestProvider>(context, listen: false).fetchTests();
          },
        );
      },
    );
  }

}
