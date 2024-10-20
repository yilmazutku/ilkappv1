import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../commons/logger.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_image_dialog.dart';
import '../dialogs/add_payment_dialog.dart';
import '../dialogs/add_sub_dialog.dart';
import '../dialogs/add_test_dialog.dart';
import '../models/subs_model.dart';
import '../providers/appointment_manager.dart';
import '../providers/meal_state_and_upload_manager.dart';
import '../providers/payment_provider.dart';
import '../providers/user_provider.dart';
import '../tabs/appointments_tab.dart';
import '../tabs/details_tab.dart';
import '../tabs/images_tab.dart';
import '../tabs/payment_tab.dart';
import '../tabs/sub_tab.dart';

final Logger logger = Logger.forClass(CustomerSummaryPage);

class CustomerSummaryPage extends StatefulWidget {
  final String userId;

  const CustomerSummaryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _CustomerSummaryPageState createState() => _CustomerSummaryPageState();
}

class _CustomerSummaryPageState extends State<CustomerSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Removed isLoading variable

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 6, vsync: this);

    // Fetch initial data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUserId(widget.userId);

    // Set userId in other providers
    Provider.of<AppointmentManager>(context, listen: false).setUserId(widget.userId);
    Provider.of<MealStateManager>(context, listen: false).setUserId(widget.userId);
    Provider.of<PaymentProvider>(context, listen: false).setUserId(widget.userId);

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
            Tab(text: 'Subs'),
          ],
        ),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          DetailsTab(userId: widget.userId),
          AppointmentsTab(userId: widget.userId),
          PaymentsTab(userId: widget.userId),
          ImagesTab(userId: widget.userId),
          const Center(child: Text('Tests Tab')), // Placeholder
          SubscriptionsTab(userId: widget.userId),
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

    if (userProvider.isLoading) {
      return const CircularProgressIndicator();
    }
    if (userProvider.subscriptions.isEmpty) {
      return Container(); // Or any placeholder widget
    }

    return DropdownButton<String>(
      value: userProvider.selectedSubscription?.subscriptionId,
      onChanged: (String? newValue) {
        if (newValue == null) return;

        final newSubscription = userProvider.subscriptions.firstWhere(
              (sub) => sub.subscriptionId == newValue,
        );

        userProvider.selectSubscription(newSubscription);

        // Update other providers with new subscriptionId
        Provider.of<AppointmentManager>(context, listen: false)
            .setSelectedSubscriptionId(newValue);
        Provider.of<MealStateManager>(context, listen: false)
            .setSelectedSubscriptionId(newValue);
        Provider.of<PaymentProvider>(context, listen: false)
            .setSelectedSubscriptionId(newValue);
      },
      items: userProvider.subscriptions
          .map<DropdownMenuItem<String>>((SubscriptionModel sub) {
        return DropdownMenuItem<String>(
          value: sub.subscriptionId,
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
      // Handle Details tab if needed
        break;
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
      case 5:
        _showAddSubscriptionDialog();
        break;
      default:
        break;
    }
  }

  void _showAddSubscriptionDialog() {
    final userId = widget.userId;

    showDialog(
      context: context,
      builder: (context) {
        return AddSubscriptionDialog(
          userId: userId,
          onSubscriptionAdded: () {
            Provider.of<UserProvider>(context, listen: false)
                .fetchSubscriptions(); // Refresh subscriptions
          },
        );
      },
    );
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
          subscription: subscription,
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
