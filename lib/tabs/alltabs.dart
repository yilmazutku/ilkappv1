// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../models/appointment_model.dart';
// import '../providers/appointment_manager.dart';
// import '../dialogs/edit_appointment_dialog.dart';
// import 'basetab.dart';
//
// class AppointmentsTab extends BaseTab<AppointmentManager> {
//
//   const AppointmentsTab({super.key, required super.userId})
//       : super(
//     allDataLabel: 'All Appointments',
//     subscriptionDataLabel: 'Subscription Appointments',
//   );
//
//   @override
//   AppointmentManager getProvider(BuildContext context) {
//     final provider = Provider.of<AppointmentManager>(context, listen: false);
//     return provider;
//   }
//
//   @override
//   Future<List<dynamic>> getDataList(AppointmentManager provider, bool showAllData) {
//     return provider.fetchAppointments(showAllAppointments: showAllData, userId: userId);
//   }
//
//   @override
//   _AppointmentsTabState createState() => _AppointmentsTabState();
// }
//
// class _AppointmentsTabState extends BaseTabState<AppointmentManager, AppointmentsTab> {
//   @override
//   Widget buildList(BuildContext context, List<dynamic> dataList) {
//     List<AppointmentModel> appointments = dataList.cast<AppointmentModel>();
//     return ListView.builder(
//       itemCount: appointments.length,
//       itemBuilder: (context, index) {
//         AppointmentModel appointment = appointments[index];
//         return ListTile(
//           title: Text(
//               'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
//           subtitle: Text(
//               'Type: ${appointment.meetingType.label}\nStatus: ${appointment.status.label}\nCanceled By: ${appointment.canceledBy ?? 'N/A'}'),
//           trailing: IconButton(
//             icon: const Icon(Icons.edit),
//             onPressed: () {
//               _showEditAppointmentDialog(context, appointment);
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   void _showEditAppointmentDialog(BuildContext context, AppointmentModel appointment) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return EditAppointmentDialog(
//           appointment: appointment,
//           onAppointmentUpdated: () {
//             setState(() {
//               // Re-fetch data when the appointment is updated
//               fetchData();
//             });
//           },
//         );
//       },
//     );
//   }
// }
// import 'package:flutter/material.dart';
//
// abstract class BaseTab<T> extends StatefulWidget {
//   final String userId;
//   final String allDataLabel;
//   final String subscriptionDataLabel;
//
//   const BaseTab({
//     super.key,
//     required this.userId,
//     required this.allDataLabel,
//     required this.subscriptionDataLabel,
//   });
//
//   T getProvider(BuildContext context);
//
//   Future<List<dynamic>> getDataList(T provider, bool showAllData);
//
//   @override
//   BaseTabState<T, BaseTab<T>> createState();
// }
//
// abstract class BaseTabState<T, W extends BaseTab<T>> extends State<W> {
//   bool showAllData = false;
//   Future<List<dynamic>>? dataFuture;
//
//   @override
//   void initState() {
//     super.initState();
//    // fetchData();
//     //   // Avoid calling fetchData or similar logic here if it depends on Provider
//   }
//
//   bool _dataFetched = false;
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_dataFetched) {
//       fetchData();
//       _dataFetched = true;
//     }
//   }
//
//   void fetchData() {
//     final provider = widget.getProvider(context);
//     dataFuture = widget.getDataList(provider, showAllData);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Toggle Button
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(showAllData ? widget.allDataLabel : widget.subscriptionDataLabel),
//             Switch(
//               value: showAllData,
//               onChanged: (value) {
//                 setState(() {
//                   showAllData = value;
//                   fetchData();
//                 });
//               },
//             ),
//           ],
//         ),
//         Expanded(
//           child: FutureBuilder<List<dynamic>>(
//             future: dataFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               } else if (snapshot.hasError) {
//                 return Center(child: Text('Error fetching data: ${snapshot.error}'));
//               } else {
//                 final dataList = snapshot.data ?? [];
//                 if (dataList.isEmpty) {
//                   return const Center(child: Text('No data found.'));
//                 }
//                 return buildList(context, dataList);
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Abstract method
//   Widget buildList(BuildContext context, List<dynamic> dataList);
// }
// import 'package:flutter/material.dart';
// import '../models/user_model.dart';
// import '../pages/admin_create_user_page.dart';
// import '../providers/user_provider.dart';
//
// class DetailsTab extends StatefulWidget {
//   final String userId;
//
//   const DetailsTab({super.key, required this.userId});
//
//   @override
//   createState() => _DetailsTabState();
// }
//
// class _DetailsTabState extends State<DetailsTab> {
//   late Future<UserModel?> _userFuture;
//
//   // Controllers for all fields including optional ones
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _surnameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _referenceController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();
//
//   bool _isEditing = false; // Toggle editing mode
//   bool _isLoading = false; // Show loading indicator during save
//
//   @override
//   void initState() {
//     super.initState();
//     _userFuture = UserProvider().fetchUserDetails();
//   }
//
//   void _populateFields(UserModel user) {
//     _nameController.text = user.name;
//     _emailController.text = user.email;
//     _surnameController.text = user.surname ?? '';
//     _ageController.text = user.age?.toString() ?? '';
//     _referenceController.text = user.reference ?? '';
//     _notesController.text = user.notes ?? '';
//   }
//
//   Future<void> _saveChanges(UserModel originalUser) async {
//     if (_isLoading) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final updatedUser = UserModel(
//       userId: originalUser.userId,
//       name: _nameController.text.trim(),
//       email: _emailController.text.trim(),
//       password: originalUser.password,
//       role: originalUser.role,
//       createdAt: originalUser.createdAt,
//       surname: _surnameController.text.trim().isNotEmpty
//           ? _surnameController.text.trim()
//           : null,
//       age: _ageController.text.trim().isNotEmpty
//           ? int.tryParse(_ageController.text.trim())
//           : null,
//       reference: _referenceController.text.trim().isNotEmpty
//           ? _referenceController.text.trim()
//           : null,
//       notes: _notesController.text.trim().isNotEmpty
//           ? _notesController.text.trim()
//           : null,
//     );
//
//     try {
//       if (originalUser.email != updatedUser.email) {
//         // If email has changed, perform migration
//         final success = await UserProvider().updateEmailAndMigrate(
//           oldUid: originalUser.userId,
//           oldEmail: originalUser.email,
//           password: CreateUserPage.tempPw,
//           newEmail: updatedUser.email,
//           updatedUser: updatedUser,
//         );
//
//         if (success) {
//           _showMessageDialog('Başarılı',
//               'E-posta değiştirildi ve kullanıcı bilgileri taşındı.');
//         } else {
//           _showMessageDialog(
//               'Hata', 'E-posta değişimi sırasında bir hata oluştu.');
//         }
//       } else {
//         // If email hasn't changed, update user details
//         final success = await UserProvider().updateUserDetails(updatedUser);
//         if (success) {
//           _showMessageDialog('Başarılı', 'Kullanıcı bilgileri güncellendi.');
//         } else {
//           _showMessageDialog('Hata', 'Bilgiler güncellenirken hata oluştu.');
//         }
//       }
//     } catch (e) {
//       _showMessageDialog('Hata', 'Bir hata oluştu: $e');
//     } finally {
//       setState(() {
//         _isEditing = false;
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showMessageDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             child: const Text('Tamam'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReadOnlyField(String label, String value) {
//     return ListTile(
//       title: Text(label),
//       subtitle: Text(value.isNotEmpty ? value : 'Yok'),
//     );
//   }
//
//   Widget _buildEditableField(String label, TextEditingController controller,
//       {TextInputType? keyboardType}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 4),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           decoration: const InputDecoration(
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<UserModel?>(
//       future: _userFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(
//               child: Text(
//                   'Kullanıcı detayları alınırken hata oluştu: ${snapshot.error}'));
//         } else if (snapshot.data == null) {
//           return const Center(child: Text('Kullanıcı bilgisi bulunamadı.'));
//         } else {
//           final user = snapshot.data!;
//           // Populate fields once the data is loaded
//           if (!_isEditing) {
//             _populateFields(user);
//           }
//
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (!_isEditing) ...[
//                     _buildReadOnlyField('Ad', user.name),
//                     _buildReadOnlyField('E-posta', user.email),
//                     _buildReadOnlyField('Soyisim', user.surname ?? ''),
//                     _buildReadOnlyField('Yaş', user.age?.toString() ?? ''),
//                     _buildReadOnlyField('Referans', user.reference ?? ''),
//                     _buildReadOnlyField('Notlar', user.notes ?? ''),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _isEditing = true;
//                         });
//                       },
//                       child: const Text('Düzenle'),
//                     ),
//                   ] else ...[
//                     _buildEditableField('Ad', _nameController),
//                     _buildEditableField('E-posta', _emailController,
//                         keyboardType: TextInputType.emailAddress),
//                     _buildEditableField('Soyisim', _surnameController),
//                     _buildEditableField('Yaş', _ageController,
//                         keyboardType: TextInputType.number),
//                     _buildEditableField('Referans', _referenceController),
//                     _buildEditableField('Notlar', _notesController),
//                     Row(
//                       children: [
//                         ElevatedButton(
//                           onPressed: () => _saveChanges(user),
//                           child: _isLoading
//                               ? const CircularProgressIndicator()
//                               : const Text('Kaydet'),
//                         ),
//                         const SizedBox(width: 16),
//                         ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _isEditing = false;
//                             });
//                           },
//                           child: const Text('İptal'),
//                         ),
//                       ],
//                     ),
//                   ]
//                 ],
//               ),
//             ),
//           );
//         }
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _surnameController.dispose();
//     _ageController.dispose();
//     _referenceController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }
// }
// // tabs/images_tab.dart
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/meal_model.dart';
// import '../providers/meal_state_and_upload_manager.dart';
// import 'basetab.dart';
//
// class ImagesTab extends BaseTab<MealStateManager> {
//   const ImagesTab({super.key, required super.userId})
//       : super(
//     allDataLabel: 'All Images',
//     subscriptionDataLabel: 'Subscription Images',
//   );
//
//   @override
//   MealStateManager getProvider(BuildContext context) {
//     final provider = Provider.of<MealStateManager>(context,listen: false);
//     provider.setUserId(userId);
//     return provider;
//   }
//
//   @override
//   Future<List<dynamic>> getDataList(MealStateManager provider, bool showAllData) {
//     return provider.fetchMeals(showAllImages: showAllData);
//   }
//
//   @override
//    createState() => _ImagesTabState();
// }
//
// class _ImagesTabState extends BaseTabState<MealStateManager, ImagesTab> {
//   @override
//   Widget buildList(BuildContext context, List<dynamic> dataList) {
//     List<MealModel> meals = dataList.cast<MealModel>();
//     return GridView.builder(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 4.0,
//         mainAxisSpacing: 4.0,
//       ),
//       itemCount: meals.length,
//       itemBuilder: (context, index) {
//         MealModel meal = meals[index];
//         return InkWell(
//           onTap: () {
//             _showFullImage(context, meal.imageUrl, meal);
//           },
//           child: Image.network(
//             meal.imageUrl,
//             fit: BoxFit.cover,
//           ),
//         );
//       },
//     );
//   }
//
//   void _showFullImage(BuildContext context, String imageUrl, MealModel meal) { //TODO
//     // Implement your image viewer dialog
//     // You can call setState here if needed
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../dialogs/edit_payment_dialog.dart';
// import '../providers/payment_provider.dart';
// import '../models/payment_model.dart';
// import 'basetab.dart';
//
// class PaymentsTab extends BaseTab<PaymentProvider> {
//   const PaymentsTab({super.key, required super.userId})
//       : super(
//     allDataLabel: 'Tüm ödemeler',
//     subscriptionDataLabel: 'Paket Ödemeleri',
//   );
//
//   @override
//   PaymentProvider getProvider(BuildContext context) {
//     final provider = Provider.of<PaymentProvider>(context, listen:false);
//     provider.setUserId(userId);
//     return provider;
//   }
//
//   @override
//   Future<List<dynamic>> getDataList(PaymentProvider provider, bool showAllData) {
//     return provider.fetchPayments(showAllPayments: showAllData);
//   }
//
//   @override
//   BaseTabState<PaymentProvider, BaseTab<PaymentProvider>> createState() => _PaymentsTabState();
// }
//
// class _PaymentsTabState extends BaseTabState<PaymentProvider, PaymentsTab> {
//   @override
//   Widget buildList(BuildContext context, List<dynamic> dataList) {
//     List<PaymentModel> payments = dataList.cast<PaymentModel>();
//     return ListView.builder(
//       itemCount: payments.length,
//       itemBuilder: (context, index) {
//         PaymentModel payment = payments[index];
//
//         // Build the subtitle based on whether paymentDate is null
//         String subtitleText = '';
//         if (payment.paymentDate != null) {
//           subtitleText +=
//           'Ödendiği Tarih: ${payment.paymentDate!.toLocal().toString().split(' ')[0]}\n';
//         }
//         if (payment.dueDate != null) {
//           subtitleText +=
//           'Planlanan Ödeme Tarihi: ${payment.dueDate!.toLocal().toString().split(' ')[0]}';
//         }
//
//         return ListTile(
//           title: Text('Miktar: ${payment.amount}'),
//           subtitle: Text(subtitleText),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Durum: ${payment.status.label}'),
//               IconButton(
//                 icon: const Icon(Icons.edit),
//                 onPressed: () {
//                   _showEditPaymentDialog(context, payment);
//                 },
//               ),
//             ],
//           ),
//           onTap: () {
//             // Handle onTap if necessary
//           },
//         );
//       },
//     );
//   }
//
//   void _showEditPaymentDialog(BuildContext context, PaymentModel payment) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return EditPaymentDialog(
//           payment: payment,
//           onPaymentUpdated: () {
//             setState(() {
//               fetchData(); // Re-fetch data when payment is updated
//             });
//           },
//         );
//       },
//     );
//   }
// }
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../dialogs/edit_sub_dialog.dart';
// import '../models/subs_model.dart';
// import '../providers/user_provider.dart';
// import 'basetab.dart';
//
// class SubscriptionsTab extends BaseTab<UserProvider> {
//   const SubscriptionsTab({super.key, required super.userId})
//       : super(
//     allDataLabel: 'All Subscriptions',
//     subscriptionDataLabel: 'Active Subscriptions',
//   );
//
//   @override
//   UserProvider getProvider(BuildContext context) {
//     final provider = Provider.of<UserProvider>(context,listen: false);
//     provider.setUserId(userId);
//     return provider;
//   }
//
//   @override
//   Future<List<dynamic>> getDataList(UserProvider provider, bool showAllData) {
//     return provider.fetchSubscriptions(showAllSubscriptions: showAllData);
//   }
//
//   @override
//   BaseTabState<UserProvider, BaseTab<UserProvider>> createState() => _SubscriptionsTabState();
// }
//
// class _SubscriptionsTabState extends BaseTabState<UserProvider, SubscriptionsTab> {
//   @override
//   Widget buildList(BuildContext context, List<dynamic> dataList) {
//     List<SubscriptionModel> subscriptions = dataList.cast<SubscriptionModel>();
//     return ListView.builder(
//       itemCount: subscriptions.length,
//       itemBuilder: (context, index) {
//         SubscriptionModel subscription = subscriptions[index];
//         return ListTile(
//           title: Text(subscription.packageName),
//           subtitle: Text(
//               'Start Date: ${subscription.startDate.toLocal().toString().split(' ')[0]}\n'
//                   'End Date: ${subscription.endDate.toLocal().toString().split(' ')[0]}'),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Status: ${subscription.status.label}'),
//               IconButton(
//                 icon: const Icon(Icons.edit),
//                 onPressed: () {
//                   _showEditSubscriptionDialog(context, subscription);
//                 },
//               ),
//             ],
//           ),
//           onTap: () {
//             // Handle onTap if necessary
//           },
//         );
//       },
//     );
//   }
//
//   void _showEditSubscriptionDialog(
//       BuildContext context, SubscriptionModel subscription) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return EditSubscriptionDialog(
//           subscription: subscription,
//           onSubscriptionUpdated: () {
//             Provider.of<UserProvider>(context, listen: false).fetchSubscriptions(showAllSubscriptions: showAllData);
//           },
//         );
//       },
//     );
//   }
// }
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/test_model.dart';
// import '../providers/test_provider.dart';
// import 'basetab.dart';
//
// class TestsTab extends BaseTab<TestProvider> {
//   const TestsTab({super.key, required super.userId})
//       : super(
//     allDataLabel: 'All Tests',
//     subscriptionDataLabel: 'Subscription Tests',
//   );
//
//   @override
//   TestProvider getProvider(BuildContext context) {
//     final provider = Provider.of<TestProvider>(context);
//     provider.setUserId(userId);
//     return provider;
//   }
//
//   @override
//   Future<List<dynamic>> getDataList(TestProvider provider, bool showAllData) {
//     return provider.fetchTests(); //hep tum testleri döner
//   }
//
//   @override
//   BaseTabState<TestProvider, BaseTab<TestProvider>> createState() => _TestsTabState();
// }
//
// class _TestsTabState extends BaseTabState<TestProvider, TestsTab> {
//   @override
//   Widget buildList(BuildContext context, List<dynamic> dataList) {
//     List<TestModel> tests = dataList.cast<TestModel>();
//     return ListView.builder(
//       itemCount: tests.length,
//       itemBuilder: (context, index) {
//         TestModel test = tests[index];
//         return ListTile(
//           title: Text('Test Name: ${test.testName}'),
//           subtitle: Text('Date: ${test.testDate.toLocal().toString().split(' ')[0]}'),
//         );
//       },
//     );
//   }
// }
