import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
import '../providers/appointment_manager.dart';
import '../providers/meal_state_and_upload_manager.dart';
import '../providers/payment_provider.dart';
import '../providers/user_provider.dart';
import '../tabs/appointments_tab.dart';
import '../tabs/details_tab.dart';
import '../tabs/images_tab.dart';
import '../tabs/payment_tab.dart';
import '../tabs/sub_tab.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_image_dialog.dart';
import '../dialogs/add_payment_dialog.dart';
import '../dialogs/add_sub_dialog.dart';
import '../dialogs/add_test_dialog.dart';

final Logger logger = Logger.forClass(CustomerSummaryPage);

class CustomerSummaryPage extends StatefulWidget {
  final String userId;

  const CustomerSummaryPage({super.key, required this.userId});

  @override
  createState() => _CustomerSummaryPageState();
}

class _CustomerSummaryPageState extends State<CustomerSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _previousTabIndex = 0;

  UserModel? _user;
  List<SubscriptionModel> _subscriptions = [];
  SubscriptionModel? _selectedSubscription;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 6, vsync: this);

    try {
      // final userProvider = Provider.of<UserProvider>(context, listen: false);
      // logger.info('Setting userId={}', [widget.userId]);
      // userProvider.setUserId(widget.userId);
      //
      // Provider.of<MealStateManager>(context, listen: false)
      //     .setUserId(widget.userId);
      // Provider.of<PaymentProvider>(context, listen: false)
      //     .setUserId(widget.userId);
      // logger.info('User ID set for providers = {}', [widget.userId]);

      _tabController.addListener(() {
        try {
          if (_tabController.index != _previousTabIndex) {
            logger.info('Tab index changed to = {}', [_tabController.index]);
            _previousTabIndex = _tabController.index;
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    logger.info('Setting userId={}', [widget.userId]);
    userProvider.setUserId(widget.userId);

    Provider.of<MealStateManager>(context, listen: false)
        .setUserId(widget.userId);
    Provider.of<PaymentProvider>(context, listen: false)
        .setUserId(widget.userId);
    logger.info('User ID set for providers = {}', [widget.userId]);


    return FutureBuilder<UserModel?>(
      future:
          Provider.of<UserProvider>(context, listen: false).fetchUserDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
                child: Text('Error fetching user details: ${snapshot.error}')),
          );
        } else {
          _user = snapshot.data;
          String title = 'Customer Summary';
          if (_user != null) {
            title = '${_user!.name}\'s Summary';
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                _buildSubscriptionDropdown(context),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _onAddButtonPressed,
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
                  Tab(text: 'Subscriptions'),
                ],
              ),
            ),
            body: TabBarView(
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
              onPressed: _onAddButtonPressed,
              label: const Text('Add'),
              icon: const Icon(Icons.add),
            ),
          );
        }
      },
    );
  }

  Widget _buildSubscriptionDropdown(BuildContext context) {
    return FutureBuilder<List<SubscriptionModel>>(
      future: Provider.of<UserProvider>(context, listen: false)
          .fetchSubscriptions(showAllSubscriptions: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          logger.err('Error fetching subscriptions: {}',
              [snapshot.error ?? 'an error but snapshot has no error? weird']);
          return const SizedBox();
        } else {
          _subscriptions = snapshot.data ?? [];
          if (_subscriptions.isEmpty) {
            return Container();
          }

          if (_selectedSubscription == null && _subscriptions.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedSubscription = _subscriptions.first;
                  final newValue = _selectedSubscription!.subscriptionId;
                  Provider.of<AppointmentManager>(context, listen: false)
                      .setSelectedSubscriptionId(newValue);
                  Provider.of<MealStateManager>(context, listen: false)
                      .setSelectedSubscriptionId(newValue);
                  Provider.of<PaymentProvider>(context, listen: false)
                      .setSelectedSubscriptionId(newValue);
                  logger.info('Default subscription selected = {}', [newValue]);
                });
              }
            });
          }

          return DropdownButton<String>(
            value: _selectedSubscription?.subscriptionId,
            onChanged: (String? newValue) {
              if (newValue == null) return;
              setState(() {
                _selectedSubscription = _subscriptions.firstWhere(
                  (sub) => sub.subscriptionId == newValue,
                );

                logger.info('Subscription selected = {}', [newValue]);
                // Update other providers with new subscriptionId
                Provider.of<AppointmentManager>(context, listen: false)
                    .setSelectedSubscriptionId(newValue);
                Provider.of<MealStateManager>(context, listen: false)
                    .setSelectedSubscriptionId(newValue);
                Provider.of<PaymentProvider>(context, listen: false)
                    .setSelectedSubscriptionId(newValue);
                logger.info(
                    'Subscription ID set for all providers = {}', [newValue]);
              });
            },
            items: _subscriptions
                .map<DropdownMenuItem<String>>((SubscriptionModel sub) {
              return DropdownMenuItem<String>(
                value: sub.subscriptionId,
                child: Text(
                    '${sub.packageName} (${sub.startDate.toLocal().toString().split(' ')[0]})'),
              );
            }).toList(),
          );
        }
      },
    );
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
                setState(() {
                  _selectedSubscription = null; // Reset selected subscription
                });
                logger
                    .info('Subscriptions refreshed after adding subscription.');
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
    final userId = widget.userId;
    final subscriptionId = _selectedSubscription?.subscriptionId;

    try {
      if (subscriptionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info(
          'Showing AddAppointmentDialog for userId = {}, subscriptionId = {}',
          [userId, subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddAppointmentDialog(
              userId: userId,
              subscriptionId: subscriptionId,
              onAppointmentAdded: () {
                logger.info('Appointment added.');
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
    final userId = widget.userId;
    final subscription = _selectedSubscription;

    try {
      if (subscription == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info(
          'Showing AddPaymentDialog for userId = {}, subscriptionId = {}',
          [userId, subscription.subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddPaymentDialog(
              userId: userId,
              subscription: subscription,
              onPaymentAdded: () {
                logger.info('Payment added.');
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
    final userId = widget.userId;
    final subscriptionId = _selectedSubscription?.subscriptionId;

    try {
      if (subscriptionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info('Showing AddImageDialog for userId = {}, subscriptionId = {}',
          [userId, subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddImageDialog(
              userId: userId,
              subscriptionId: subscriptionId,
              onImageAdded: () {
                logger.info('Image added.');
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
    final userId = widget.userId;
    final subscriptionId = _selectedSubscription?.subscriptionId;

    try {
      if (subscriptionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a subscription.')),
          );
        }
        return;
      }

      logger.info('Showing AddTestDialog for userId = {}, subscriptionId = {}',
          [userId, subscriptionId]);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AddTestDialog(
              userId: userId,
              onTestAdded: () {
                logger.info('Test added.');
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
