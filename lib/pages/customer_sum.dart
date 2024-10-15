// customer_summary_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../commons/userclass.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_payment_dialog.dart';
import '../dialogs/add_test_dialog.dart';
import '../managers/appointment_manager.dart';
import '../managers/meal_state_and_upload_manager.dart';
import '../managers/payment_provider.dart';
import '../managers/test_provider.dart';
import '../managers/user_provider.dart';
import '../tabs/appointments_tab.dart';
import '../tabs/details_tab.dart';
import '../tabs/images_tab.dart';
import '../tabs/payment_tab.dart';
import '../tabs/tests_tab.dart';

class CustomerSummaryPage extends StatefulWidget {
  final String userId;

  const CustomerSummaryPage({super.key, required this.userId});

  @override
   createState() => _CustomerSummaryPageState();
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
          TestsTab(userId: widget.userId),
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
    final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
    final mealManager = Provider.of<MealStateManager>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final testProvider = Provider.of<TestProvider>(context, listen: false);

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
        testProvider.setSelectedSubscriptionId(subscriptionId);
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
      case 0:
      // Details Tab - Maybe add user details or edit profile
        break;
      case 1:
      // Appointments Tab - Show dialog to add appointment
        _showAddAppointmentDialog();
        break;
      case 2:
      // Payments Tab - Show dialog to add payment
        _showAddPaymentDialog();
        break;
      case 3:
      // Images Tab - Show dialog to add/upload an image
        _showAddImageDialog();
        break;
      case 4:
      // Tests Tab - Show dialog to add a test
        _showAddTestDialog();
        break;
      default:
        break;
    }
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddAppointmentDialog(
          onAppointmentAdded: () {
            Provider.of<AppointmentManager>(context, listen: false)
                .fetchAppointments();
          },
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final subscriptionId = Provider.of<UserProvider>(context, listen: false).selectedSubscription?.subscriptionId;
    showDialog(
      context: context,
      builder: (context) {
        return AddPaymentDialog(
          onPaymentAdded: () {
            Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
          },
        );
      },
    );
  }

  void _showAddImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddImageDialog(
          onImageAdded: () {
            Provider.of<MealStateManager>(context, listen: false).fetchMeals();
          },
        );
      },
    );
  }

  void _showAddTestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddTestDialog(
          onTestAdded: () {
            Provider.of<TestProvider>(context, listen: false).fetchTests();
          },
        );
      },
    );
  }
}
