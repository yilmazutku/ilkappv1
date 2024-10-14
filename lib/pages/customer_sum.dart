// customer_summary_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../commons/logger.dart';
import '../commons/userclass.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_payment_dialog.dart';
import '../dialogs/add_sub_dialog.dart';
import '../dialogs/add_test_dialog.dart';
import '../dialogs/dekont_viewer_page.dart';
import '../dialogs/edit_appointment_dialog.dart';
import '../dialogs/edit_payment_dialog.dart';

//TODO images ve tests de package göre gösterilebilir, ama all seçenmeği de eklenmelidir.
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
  bool showAllImages = false; // Default to showing all images

  UserModel? user;
  List<AppointmentModel> appointments = [];
  List<PaymentModel> payments = [];
  List<MealModel> meals = [];
  List<TestModel> tests = [];
  bool isLoading = true;

  List<SubscriptionModel> subscriptions = [];
  SubscriptionModel? selectedSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuilds the AppBar when the tab index changes
    });
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([
      fetchUserDetails(),
      fetchUserSubscriptions(),
      fetchUserAppointments(),
      fetchUserPayments(),
      fetchUserMeals(),
      fetchUserTests(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        user = UserModel.fromDocument(doc);
      }
    } catch (e) {
      logger.err('Error fetching user details: {}', [e]);
    }
  }

  Future<void> fetchUserSubscriptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .orderBy('startDate', descending: true)
          .get();

      subscriptions = snapshot.docs
          .map((doc) => SubscriptionModel.fromDocument(doc))
          .toList();

      if (subscriptions.isNotEmpty) {
        selectedSubscription = subscriptions.first;
      }
    } catch (e) {
      logger.err('Error fetching user subscriptions: {}', [e]);
    }
  }

/*
* This assumes that when
*  selectedSubscription is null,
* you want to see appointments not associated with any subscription.
* */
  Future<void> fetchUserAppointments() async {
    try {
      if (selectedSubscription != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('appointments')
            .where('subscriptionId',
                isEqualTo: selectedSubscription!.subscriptionId)
            .orderBy('appointmentDateTime', descending: true)
            .get();

        appointments = snapshot.docs
            .map((doc) => AppointmentModel.fromDocument(doc))
            .toList();
      } else {
        // Fetch appointments without a subscriptionId
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('appointments')
            .where('subscriptionId', isNull: true)
            .orderBy('appointmentDateTime', descending: true)
            .get();

        appointments = snapshot.docs
            .map((doc) => AppointmentModel.fromDocument(doc))
            .toList();
      }
    } catch (e) {
      logger.err('Error fetching user appointments: {}', [e]);
    }
  }

  Future<void> fetchUserPayments() async {
    try {
      if (selectedSubscription != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('payments')
            .where('subscriptionId',
                isEqualTo: selectedSubscription!.subscriptionId)
            .orderBy('paymentDate', descending: true)
            .get();

        payments =
            snapshot.docs.map((doc) => PaymentModel.fromDocument(doc)).toList();
      } else {
        payments = [];
      }
    } catch (e) {
      logger.err('Error fetching user payments: {}', [e]);
    }
  }

  Future<void> fetchUserMeals() async {
    try {
      Query mealsQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('meals')
          .orderBy('timestamp', descending: true);

      if (!showAllImages && selectedSubscription != null) {
        mealsQuery = mealsQuery
            .where('subscriptionId', isEqualTo: selectedSubscription!.subscriptionId);
      }
      final snapshot = await mealsQuery.get();

      meals = snapshot.docs.map((doc) => MealModel.fromDocument(doc)).toList();
    } catch (e) {
      logger.err('Error fetching user meals: {}', [e]);
    }
  }



  Future<void> fetchUserTests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('tests')
          .orderBy('testDate', descending: true)
          .get();

      tests = snapshot.docs.map((doc) => TestModel.fromDocument(doc)).toList();
      logger
          .info('Fetched {} tests for user {}', [tests.length, widget.userId]);
    } catch (e) {
      logger.err('Error fetching user tests: {}', [e]);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Customer Summary';
    if (user != null) {
      title = '${user!.name}\'s Summary';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (subscriptions.isNotEmpty)
            DropdownButton<SubscriptionModel>(
              value: selectedSubscription,
              onChanged: (SubscriptionModel? newValue) {
                setState(() {
                  selectedSubscription = newValue;
                  appointments=[];
                  payments=[];
                  fetchUserAppointments();
                  fetchUserPayments();
                  fetchUserMeals(); // Fetch meals when subscription changes
                });
              },
              items: subscriptions.map<DropdownMenuItem<SubscriptionModel>>((SubscriptionModel sub) {
                return DropdownMenuItem<SubscriptionModel>(
                  value: sub,
                  child: Text('${sub.packageName} (${sub.startDate.toLocal().toString().split(' ')[0]})'),
                );
              }).toList(),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddSubscriptionDialog();
            },
          ),
          if (_tabController.index == 3) // Index 3 is Images tab
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Text(showAllImages ? 'All Images' : 'Subscription Images'),
                  Switch(
                    value: showAllImages,
                    onChanged: (value) {
                      setState(() {
                        showAllImages = value;
                        fetchUserMeals();
                      });
                    },
                  ),
                ],
              ),
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
                buildDetailsTab(),
                buildAppointmentsTab(),
                buildPaymentsTab(),
                buildImagesTab(),
                buildTestsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddButtonPressed(),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddSubscriptionDialog(
          userId: widget.userId,
          onSubscriptionAdded: () async {
            await fetchUserSubscriptions();
            if (mounted) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  void _onAddButtonPressed() {
    // Determine which tab is currently selected and show the corresponding add dialog or page
    switch (_tabController.index) {
      case 0:
        // Details tab - perhaps for editing user details
        // You can implement an edit functionality here if needed
        break;
      case 1:
        // Appointments tab
        if (selectedSubscription == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select a subscription package.')),
          );
          return;
        }
        _showAddAppointmentDialog();
        break;
      case 2:
        // Payments tab
        if (selectedSubscription == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select a subscription package.')),
          );
          return;
        }
        _showAddPaymentDialog();
        break;
      case 3:
        // Images tab
        // You might want to allow the admin to upload images on behalf of the user
        break;
      case 4:
        // Tests tab
        _showAddTestDialog();
        break;
      default:
        break;
    }
  }

  Widget buildDetailsTab() {
    if (user == null) {
      return const Center(child: Text('No user details available.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ListTile(
            title: const Text('Name'),
            subtitle: Text(user!.name),
          ),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(user!.email),
          ),
          // Add more user details as needed
        ],
      ),
    );
  }

  Widget buildAppointmentsTab() {
    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found.'));
    }

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        AppointmentModel appointment = appointments[index];
        return ListTile(
          title: Text('Date: ${appointment.appointmentDateTime.toLocal()}'),
          subtitle: Text('Type: ${appointment.meetingType.label}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${appointment.status.label}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditAppointmentDialog(appointment);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPaymentsTab() {
    if (selectedSubscription == null) {
      return const Center(child: Text('No active subscription found.'));
    }

    final amountRemaining =
        selectedSubscription!.totalAmount - selectedSubscription!.amountPaid;

    return Column(
      children: [
        if (amountRemaining > 0)
          Container(
            color: Colors.redAccent,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Remaining Amount to be Paid: \$${amountRemaining.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        Expanded(
          child: (payments.isEmpty)
              ? const Center(child: Text('No payments found.'))
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    PaymentModel payment = payments[index];

                    String paymentDateText = payment.paymentDate != null
                        ? payment.paymentDate.toLocal().toString().split(' ')[0]
                        : '-';

                    String dueDateText = payment.dueDate != null
                        ? payment.dueDate!.toLocal().toString().split(' ')[0]
                        : '-';

                    String statusText =
                        payment.status.isNotEmpty ? payment.status : '-';

                    String amountText = payment.amount != null
                        ? payment.amount.toString()
                        : '-';

                    return ListTile(
                      title: Text('Amount: $amountText'),
                      subtitle: Text(
                          'Payment Date: $paymentDateText\nDue Date: $dueDateText'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Status: $statusText'),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditPaymentDialog(payment);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        if (payment.dekontUrl != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DekontViewerPage(
                                dekontUrl: payment.dekontUrl!,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
  Widget buildImagesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text('Show All Images'),
              Switch(
                value: showAllImages,
                onChanged: (value) {
                  setState(() {
                    showAllImages = value;
                    fetchUserMeals();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: meals.isEmpty
              ? const Center(child: Text('No images found.'))
              : GridView.builder(
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
                  showFullImage(context, meal.imageUrl, meal);
                },
                child: Image.network(
                  meal.imageUrl,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget buildTestsTab() {
    if (tests.isEmpty) {
      return const Center(child: Text('No tests found.'));
    }

    return ListView.builder(
      itemCount: tests.length,
      itemBuilder: (context, index) {
        TestModel test = tests[index];
        return ListTile(
          title: Text(test.testName),
          subtitle:
              Text('Date: ${test.testDate.toLocal().toString().split(' ')[0]}'),
          onTap: () {
            if (test.testFileUrl != null) {
              showTestFile(context, test);
            }
          },
        );
      },
    );
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddAppointmentDialog(
          userId: widget.userId,
          onAppointmentAdded: () async {
            await fetchUserAppointments();
            if (mounted) {
              setState(() {});
            }
          },
          subscription: selectedSubscription!,
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddPaymentDialog(
          userId: widget.userId,
          onPaymentAdded: () async {
            await fetchUserPayments();
            if (mounted) {
              setState(() {});
            }
          },
          subscription: selectedSubscription!,
        );
      },
    );
  }

  void _showEditPaymentDialog(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditPaymentDialog(
          payment: payment,
          onPaymentUpdated: () async {
            await fetchUserPayments();
            if (mounted) {
              setState(() {}); // Refresh the payments tab
            }
          },
        );
      },
    );
  }

  void _showEditAppointmentDialog(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return EditAppointmentDialog(
          appointment: appointment,
          onAppointmentUpdated: () async {
            await fetchUserAppointments();
            if (mounted) {
              setState(() {}); // Refresh the appointments tab
            }
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
          userId: widget.userId,
          onTestAdded: () async {
            await fetchUserTests();
            if (mounted) {
              setState(() {}); // Refresh the tests tab
            }
          },
        );
      },
    );
  }

  void showFullImage(BuildContext context, String imageUrl, MealModel meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(imageUrl),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Meal Type: ${meal.mealType.label}\n'
                  'Timestamp: ${meal.timestamp}\n'
                  'Description: ${meal.description ?? 'N/A'}',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to show test file (image or PDF)
  void showTestFile(BuildContext context, TestModel test) {
    if (test.testFileUrl != null) {
      if (test.testFileUrl!.endsWith('.pdf')) {
        // Handle PDF viewing
        // You may use a package like 'flutter_full_pdf_viewer' or 'advance_pdf_viewer'
      } else {
        // Show image
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(test.testFileUrl!),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${test.testName}\n'
                      'Date: ${test.testDate.toLocal().toString().split(' ')[0]}\n'
                      'Description: ${test.testDescription ?? 'N/A'}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
