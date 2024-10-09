import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../commons/logger.dart';
import '../commons/userclass.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/add_test_dialog.dart';
import '../dialogs/payment_dialog.dart';


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

  UserModel? user;
  List<AppointmentModel> appointments = [];
  List<PaymentModel> payments = [];
  List<MealModel> meals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([
      fetchUserDetails(),
      fetchUserAppointments(),
      fetchUserPayments(),
      fetchUserMeals(),
      fetchUserTests(), // Fetch tests data

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

  Future<void> fetchUserAppointments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('appointments')
          .orderBy('appointmentDateTime', descending: true)
          .get();

      appointments =
          snapshot.docs.map((doc) => AppointmentModel.fromDocument(doc)).toList();
    } catch (e) {
      logger.err('Error fetching user appointments: {}', [e]);
    }
  }

  Future<void> fetchUserPayments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .get();

      payments =
          snapshot.docs.map((doc) => PaymentModel.fromDocument(doc)).toList();
    } catch (e) {
      logger.err('Error fetching user payments: {}', [e]);
    }
  }

  Future<void> fetchUserMeals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('meals')
          .orderBy('timestamp', descending: true)
          .get();

      meals = snapshot.docs.map((doc) => MealModel.fromDocument(doc)).toList();
    } catch (e) {
      logger.err('Error fetching user meals: {}', [e]);
    }
  }

// Fetch test results
  Future<void> fetchUserTests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('tests')
          .orderBy('testDate', descending: true)
          .get();

      tests = snapshot.docs.map((doc) => TestModel.fromDocument(doc)).toList();
      logger.info('Fetched {} tests for user {}', [tests.length, widget.userId]);
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Appointments'),
            Tab(text: 'Payments'),
            Tab(text: 'Images'),
            Tab(text: 'Tests'), // New tab
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
          buildTestsTab(), // New method for Tests tab

        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddButtonPressed(),
        label: const Text('Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
  List<TestModel> tests = [];


  void _onAddButtonPressed() {
    // Determine which tab is currently selected and show the corresponding add dialog or page
    switch (_tabController.index) {
      case 0:
      // Details tab - perhaps for editing user details
      // You can implement an edit functionality here if needed
        break;
      case 1:
      // Appointments tab
        _showAddAppointmentDialog();
        break;
      case 2:
      // Payments tab
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
          subtitle: Text('Date: ${test.testDate.toLocal().toString().split(' ')[0]}'),
          onTap: () {
            if (test.testFileUrl != null) {
              showTestFile(context, test);
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
            setState(() {}); // Refresh the tests tab
          },
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
  // Build methods for viewing data (same as before)
  Widget buildDetailsTab() {
    // ... (same as before)
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
    // ... (same as before)
    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found.'));
    }

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        AppointmentModel appointment = appointments[index];
        return ListTile(
          title:
          Text('Date: ${appointment.appointmentDateTime.toLocal().toString()}'),
          subtitle: Text('Type: ${appointment.meetingType.label}'),
          trailing: Text('Status: ${appointment.status}'),
        );
      },
    );
  }

  Widget buildPaymentsTab() {
    if (payments.isEmpty) {
      return const Center(child: Text('No payments found.'));
    }

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        PaymentModel payment = payments[index];

        String paymentDateText = payment.paymentDate != null
            ? payment.paymentDate.toLocal().toString().split(' ')[0]
            : '-';

        String dueDateText = payment.dueDate != null
            ? payment.dueDate!.toLocal().toString().split(' ')[0]
            : '-';

        String statusText = payment.status.isNotEmpty ? payment.status : '-';

        String amountText = payment.amount != null ? payment.amount.toString() : '-';

        return ListTile(
          title: Text('Amount: $amountText'),
          subtitle: Text('Payment Date: $paymentDateText\nDue Date: $dueDateText'),
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
            setState(() {}); // Refresh the payments tab
          },
        );
      },
    );
  }


  Widget buildImagesTab() {
    // ... (same as before)
    if (meals.isEmpty) {
      return const Center(child: Text('No images found.'));
    }

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
            showFullImage(context, meal.imageUrl, meal);
          },
          child: Image.network(
            meal.imageUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  // Implement the add dialogs
  void _showAddAppointmentDialog() {
    // Implement the UI and functionality to add an appointment
    // You can use a dialog or navigate to a new page
    // For simplicity, let's use a dialog here
    showDialog(
      context: context,
      builder: (context) {
        return AddAppointmentDialog(
          userId: widget.userId,
          onAppointmentAdded: () async {
            await fetchUserAppointments();
            setState(() {}); // Refresh the appointments tab
          },
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    // Implement the UI and functionality to add a payment
    showDialog(
      context: context,
      builder: (context) {
        return AddPaymentDialog(
          userId: widget.userId,
          onPaymentAdded: () async {
            await fetchUserPayments();
            setState(() {}); // Refresh the payments tab
          },
        );
      },
    );
  }

  void showFullImage(BuildContext context, String imageUrl, MealModel meal) {
    // ... (same as before)
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

  void showReceiptImage(BuildContext context, String imageUrl) {
    // ... (same as before)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Image.network(imageUrl),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}