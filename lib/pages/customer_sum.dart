// customer_summary_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/tabs/measurements_tab.dart';

import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_diet_dialog.dart';
import '../dialogs/add_image_dialog.dart';
import '../dialogs/add_payment_dialog.dart';
import '../dialogs/add_sub_dialog.dart';
import '../models/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
import '../providers/appointment_manager.dart';
import '../providers/meal_state_and_upload_manager.dart';
import '../providers/payment_provider.dart';
import '../providers/user_provider.dart';
import '../tabs/appointments_tab.dart';
import '../tabs/details_tab.dart';
import '../tabs/diet_tab.dart';
import '../tabs/images_tab.dart';
import '../tabs/payment_tab.dart';
import '../tabs/sub_tab.dart';

final Logger logger = Logger.forClass(CustomerSummaryPage);

class CustomerSummaryPage extends StatefulWidget {
  const CustomerSummaryPage({required this.user, super.key});
  final UserModel user;
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
    _tabController = TabController(length: 8, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _previousTabIndex) {
        logger.info('Tab changed: index={}', [_tabController.index]);
        _previousTabIndex = _tabController.index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context,listen: false);
    final userId = widget.user.userId;
  //  userProvider.setUserId(userId);
  //  final userId = userProvider.userId;

    return FutureBuilder<UserModel?>(
      future: userProvider.fetchUserDetails(userId:userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          logger.err('Error fetching user details: {}', [snapshot.error!]);
          return Scaffold(
            body: Center(
              child: Text('Kullanıcı detayları alınırken bir hata oluştu: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          logger.warn('User data not found for userId={}', [userId]);
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bilgisi bulunamadı.')),
          );
        } else {
          _user = snapshot.data;

          // Set MealStateManager and PaymentProvider with current userId
          Provider.of<MealStateManager>(context, listen: false).setUserId(userId);
          Provider.of<PaymentProvider>(context, listen: false).setUserId(userId);

          return _buildScaffold(_user!);
        }
      },
    );
  }

  Widget _buildScaffold(UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${user.name} - Özet'),
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
            Tab(text: 'Detaylar'),
            Tab(text: 'Randevular'),
            Tab(text: 'Ödemeler'),
            Tab(text: 'Resimler'),
            Tab(text: 'Testler'),
            Tab(text: 'Ölçümler'),
            Tab(text: 'Listeler'),  // ...
            Tab(text: 'Abonelikler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DetailsTab(userId: user.userId),
          AppointmentsTab(userId: user.userId),
          PaymentsTab(userId: user.userId),
          ImagesTab(userId: user.userId),
          const Center(child: Text('Testler Sekmesi')), // Placeholder
          MeasTab(userId: user.userId),
          DietTab(userId: user.userId), // ...
          SubscriptionsTab(userId: user.userId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddButtonPressed,
        label: const Text('Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubscriptionDropdown(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = widget.user.userId;

    return FutureBuilder<List<SubscriptionModel>>(
      future: userProvider.fetchSubscriptions(
        userId: userId, // Pass the userId explicitly
        showAllSubscriptions: false,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          logger.err('Error fetching subscriptions: {}', [snapshot.error!]);
          return const SizedBox();
        } else {
          _subscriptions = snapshot.data ?? [];
          if (_subscriptions.isEmpty) {
            logger.warn('No subscriptions found for userId={}', [userId]);
            return Container();
          }

          if (_selectedSubscription == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedSubscription = _subscriptions.first;
                  final newValue = _selectedSubscription!.subscriptionId;
                  Provider.of<AppointmentManager>(context, listen: false).setSelectedSubscriptionId(newValue);
                  Provider.of<MealStateManager>(context, listen: false).setSelectedSubscriptionId(newValue);
                  Provider.of<PaymentProvider>(context, listen: false).setSelectedSubscriptionId(newValue);
                  logger.info('Default subscription selected: subscriptionId={}', [newValue]);
                });
              }
            });
          }

          return DropdownButton<String>(
            value: _selectedSubscription?.subscriptionId,
            onChanged: (String? newValue) {
              if (newValue == null) return;
              setState(() {
                _selectedSubscription = _subscriptions.firstWhere((sub) => sub.subscriptionId == newValue);
                logger.info('Subscription selected: subscriptionId={}', [newValue]);
                Provider.of<AppointmentManager>(context, listen: false).setSelectedSubscriptionId(newValue);
                Provider.of<MealStateManager>(context, listen: false).setSelectedSubscriptionId(newValue);
                Provider.of<PaymentProvider>(context, listen: false).setSelectedSubscriptionId(newValue);
              });
            },
            items: _subscriptions.map<DropdownMenuItem<String>>((SubscriptionModel sub) {
              return DropdownMenuItem<String>(
                value: sub.subscriptionId,
                child: Text(
                  '${sub.packageName} (${sub.startDate.toLocal().toString().split(' ')[0]})',
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  void _onAddButtonPressed() {
    final currentIndex = _tabController.index;
    logger.info('Add button pressed: tabIndex={}', [currentIndex]);

    try {
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
        case 5:
          _showAddSubscriptionDialog();
          break;
        case 6: // <-- DIET TAB index
          _showAddDietDialog(); // We'll define this
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu sekme için ekleme yapılamaz.')),
          );
      }
    } catch (e) {
      logger.err('Error while handling add button: {}', [e]);
    }
  }
// Add this method:
  void _showAddDietDialog() {
    showDialog(
      context: context,
      builder: (_) => AddDietDialog(userId: widget.user.userId),
    );
  }
  void _showAddSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddSubscriptionDialog(
          userId: widget.user.userId,
          onSubscriptionAdded: () {
            setState(() {
              _selectedSubscription = null; // Reset selection
            });
            logger.info('Subscription added and refreshed for userId={}', [widget.user.userId]);
          },
        );
      },
    );
  }

  void _showAddAppointmentDialog() {
    final subscriptionId = _selectedSubscription?.subscriptionId;
    if (subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir abonelik seçin.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AddAppointmentDialog(
          userId: widget.user.userId,
          subscriptionId: subscriptionId,
          onAppointmentAdded: () {
            logger.info('Appointment added for userId={}, subscriptionId={}', [widget.user.userId, subscriptionId]);
          },
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    final subscription = _selectedSubscription;
    if (subscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir abonelik seçin.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AddPaymentDialog(
          userId: widget.user.userId,
          subscription: subscription,
          onPaymentAdded: () {
            logger.info('Payment added for userId={}, subscriptionId={}', [widget.user.userId, subscription.subscriptionId]);
          },
        );
      },
    );
  }

  void _showAddImageDialog() {
    final subscriptionId = _selectedSubscription?.subscriptionId;
    if (subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir abonelik seçin.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AddImageDialog(
          userId: widget.user.userId,
          subscriptionId: subscriptionId,
          onImageAdded: () {
            logger.info('Image added for userId={}, subscriptionId={}', [widget.user.userId, subscriptionId]);
          },
        );
      },
    );
  }
}
