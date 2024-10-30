import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/logger.dart';
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

  /// Bu constructor, admin bir kişinin özetine bastığında çağrılır.
  const CustomerSummaryPage({super.key, required this.userId});

  @override
   createState() => _CustomerSummaryPageState();
}

class _CustomerSummaryPageState extends State<CustomerSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _previousTabIndex = 0; // Track the previous index
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 6, vsync: this);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      logger.info('setting userId={}',[widget.userId]);
      userProvider.setUserId(widget.userId);

      Provider.of<AppointmentManager>(context, listen: false).setUserId(widget.userId);
      Provider.of<MealStateManager>(context, listen: false).setUserId(widget.userId);
      Provider.of<PaymentProvider>(context, listen: false).setUserId(widget.userId);
      logger.info('User ID set for providers = {}', [widget.userId]);

      _tabController.addListener(() {
        try {
          if (_tabController.index != _previousTabIndex) {
            logger.info('Tab index changed to = {}', [_tabController.index]);
            _previousTabIndex =
                _tabController.index; // Update the previous index
          }
        } catch (e) {
          logger.err('Error handling tab change = {}', [e]);
        }
      });
    } catch (e) {
      logger.err('Error in initState = {}', [e]);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final userProvider = Provider.of<UserProvider>(context);

      String title = 'Customer Summary';
      if (userProvider.user != null) {
        title = '${userProvider.user!.name}\'s Summary';
      }
      //logger.info('Building CustomerSummaryPage with title = {}', [title]);

      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            _buildSubscriptionDropdown(context),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                try {
                  _onAddButtonPressed();
                } catch (e) {
                  logger.err('Error during _onAddButtonPressed = {}', [e]);
                }
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
          onPressed: () {
            try {
              _onAddButtonPressed();
            } catch (e) {
              logger.err('Error during FAB _onAddButtonPressed = {}', [e]);
            }
          },
          label: const Text('Add'),
          icon: const Icon(Icons.add),
        ),
      );
    } catch (e) {
      logger.err('Error in build method = {}', [e]);
      return const Center(child: Text('An error occurred.'));
    }
  }
  Widget _buildSubscriptionDropdown(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    try {
      if (userProvider.isLoading) {
      //  logger.info('userProvider is currently loading.');
        return const CircularProgressIndicator();
      }
      if (userProvider.subscriptions.isEmpty) {
        return Container(); // Or any placeholder widget
      }
     // logger.info('userProvider is not loading. Starting to build.');
      return DropdownButton<String>(
        value: userProvider.selectedSubscription?.subscriptionId,
        onChanged: (String? newValue) {
          try {
            if (newValue == null) return;

            final newSubscription = userProvider.subscriptions.firstWhere(
                  (sub) => sub.subscriptionId == newValue,
            );

            userProvider.selectSubscription(newSubscription);
            logger.info('Subscription selected = {}', [newValue]);
            // Update other providers with new subscriptionId
            Provider.of<AppointmentManager>(context, listen: false)
                .setSelectedSubscriptionId(newValue);
            Provider.of<MealStateManager>(context, listen: false)
                .setSelectedSubscriptionId(newValue);
            Provider.of<PaymentProvider>(context, listen: false)
                .setSelectedSubscriptionId(newValue);
            logger.info('Subscription ID set for all providers = {}', [newValue]);
          } catch (e) {
            logger.err('Error in subscription change = {}', [e]);
          }
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
    } catch (e) {
      logger.err('Error in _buildSubscriptionDropdown = {}', [e]);
      return const SizedBox();
    }
  }

  void _onAddButtonPressed() {
    int currentIndex = _tabController.index;
    logger.info('Add button pressed on tab index = {}', [currentIndex]);

    try {
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
    } catch (e) {
      logger.err('Error in _onAddButtonPressed = {}', [e]);
    }
  }


void _showAddSubscriptionDialog() {
    final userId = widget.userId;
    logger.info('Showing add subscription dialog for userId = {}', [userId]);

    try {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddSubscriptionDialog(
              userId: userId,
              onSubscriptionAdded: () {
                try {
                  Provider.of<UserProvider>(context, listen: false)
                      .fetchSubscriptions(); // Refresh subscriptions
                  logger.info('Subscriptions fetched after adding subscription.');
                } catch (e) {
                  logger.err('Error fetching subscriptions = {}', [e]);
                }
              },
            );
          },
        );
      }
    } catch (e) {
      logger.err('Error in _showAddSubscriptionDialog = {}', [e]);
    }
  }

  void _showAddAppointmentDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscriptionId = userProvider.selectedSubscription?.subscriptionId;

    try {
      if (subscriptionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info('Showing AddAppointmentDialog for userId = {}, subscriptionId = {}', [userId, subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddAppointmentDialog(
              userId: userId,
              subscriptionId: subscriptionId,
              onAppointmentAdded: () {
                try {
                  Provider.of<AppointmentManager>(context, listen: false)
                      .fetchAppointments();
                  logger.info('Appointments fetched after adding.');
                } catch (e) {
                  logger.err('Error fetching appointments = {}', [e]);
                }
              },
            );
          },
        );
      }
    } catch (e) {
      logger.err('Error in _showAddAppointmentDialog = {}', [e]);
    }
  }

  void _showAddPaymentDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscription = userProvider.selectedSubscription;

    try {
      if (subscription == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info('Showing AddPaymentDialog for userId = {}, subscriptionId = {}', [userId, subscription.subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddPaymentDialog(
              userId: userId,
              subscription: subscription,
              onPaymentAdded: () {
                try {
                  Provider.of<PaymentProvider>(context, listen: false)
                      .fetchPayments();
                  logger.info('Payments fetched after adding.');
                } catch (e) {
                  logger.err('Error fetching payments = {}', [e]);
                }
              },
            );
          },
        );
      }
    } catch (e) {
      logger.err('Error in _showAddPaymentDialog = {}', [e]);
    }
  }

  void _showAddImageDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscriptionId = userProvider.selectedSubscription?.subscriptionId;

    try {
      if (subscriptionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info('Showing AddImageDialog for userId = {}, subscriptionId = {}', [userId, subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddImageDialog(
              userId: userId,
              subscriptionId: subscriptionId,
              onImageAdded: () {
                try {
                  Provider.of<MealStateManager>(context, listen: false)
                      .fetchMeals();
                  logger.info('Meals fetched after adding image.');
                } catch (e) {
                  logger.err('Error fetching meals = {}', [e]);
                }
              },
            );
          },
        );
      }
    } catch (e) {
      logger.err('Error in _showAddImageDialog = {}', [e]);
    }
  }

  void _showAddTestDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.userId;
    final subscriptionId = userProvider.selectedSubscription?.subscriptionId;

    try {
      if (subscriptionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info('Showing AddTestDialog for userId = {}, subscriptionId = {}', [userId, subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddTestDialog(
              userId: userId,
              onTestAdded: () {
                try {
                  // Implement fetchTests or similar method in the relevant provider
                  // Provider.of<TestProvider>(context, listen: false).fetchTests();
                  logger.info('Tests fetched after adding test.');
                } catch (e) {
                  logger.err('Error fetching tests = {}', [e]);
                }
              },
            );
          },
        );
      }
    } catch (e) {
      logger.err('Error in _showAddTestDialog = {}', [e]);
    }
  }
}
