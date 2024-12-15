// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../models/appointment_model.dart';
// import '../models/logger.dart';
// import '../models/user_model.dart';
// import '../providers/appointment_manager.dart';
// import '../dialogs/edit_appointment_dialog.dart';
//
// final Logger logger = Logger.forClass(AdminAppointmentsPage);
//
// class AdminAppointmentsPage extends StatefulWidget {
//   const AdminAppointmentsPage({super.key});
//
//   @override
//   createState() => _AdminAppointmentsPageState();
// }
//
// class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
//   DateTime? startDate;
//   DateTime? endDate;
//   MeetingType? selectedMeetingType;
//   AppointmentStatus? selectedMeetingStatus;
//   String? sortOption = 'Date Descending';
//
//   final List<MeetingType?> meetingTypes = [null, ...MeetingType.values];
//   final List<AppointmentStatus?> meetingStatuses = [null, ...AppointmentStatus.values];
//   final List<String> sortOptions = ['Date Ascending', 'Date Descending', 'Name A-Z', 'Name Z-A'];
//
//   late Future<List<AppointmentModel>> _appointmentsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAllAppointments();
//   }
//
//   void _fetchAllAppointments() {
//     _appointmentsFuture = _fetchAppointmentsWithUsers();
//   }
//
//   Future<List<AppointmentModel>> _fetchAppointmentsWithUsers() async {
//     try {
//       QuerySnapshot snapshot = await FirebaseFirestore.instance.collectionGroup('appointments').get();
//
//       // Fetch appointments and associated user details
//       List<AppointmentModel> fetchedAppointments = await Future.wait(snapshot.docs.map((doc) async {
//         AppointmentModel appointment = AppointmentModel.fromDocument(doc);
//
//         DocumentSnapshot userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(appointment.userId)
//             .get();
//
//         appointment.user = UserModel.fromDocument(userDoc);
//         return appointment;
//       }).toList());
//
//       // Apply filters and sorting
//       return _applyFiltersAndSort(fetchedAppointments);
//     } catch (e) {
//       logger.err('Error fetching appointments: {}', [e]);
//       return [];
//     }
//   }
//
//   List<AppointmentModel> _applyFiltersAndSort(List<AppointmentModel> appointments) {
//     List<AppointmentModel> filteredAppointments = appointments.where((appointment) {
//       bool matchesDate = (startDate == null || appointment.appointmentDateTime.isAfter(startDate!)) &&
//           (endDate == null || appointment.appointmentDateTime.isBefore(endDate!.add(const Duration(days: 1))));
//
//       bool matchesType = selectedMeetingType == null || appointment.meetingType == selectedMeetingType;
//       bool matchesStatus = selectedMeetingStatus == null || appointment.status == selectedMeetingStatus;
//
//       return matchesDate && matchesType && matchesStatus;
//     }).toList();
//
//     // Sort appointments based on selected option
//     filteredAppointments.sort((a, b) {
//       switch (sortOption) {
//         case 'Date Ascending':
//           return a.appointmentDateTime.compareTo(b.appointmentDateTime);
//         case 'Date Descending':
//           return b.appointmentDateTime.compareTo(a.appointmentDateTime);
//         case 'Name A-Z':
//           return (a.user?.name ?? '').compareTo(b.user?.name ?? '');
//         case 'Name Z-A':
//           return (b.user?.name ?? '').compareTo(a.user?.name ?? '');
//         default:
//           return 0;
//       }
//     });
//
//     return filteredAppointments;
//   }
//
//   void _pickDateRange() async {
//     DateTimeRange? pickedRange = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       initialDateRange: startDate != null && endDate != null
//           ? DateTimeRange(start: startDate!, end: endDate!)
//           : null,
//     );
//
//     if (pickedRange != null) {
//       setState(() {
//         startDate = pickedRange.start;
//         endDate = pickedRange.end;
//         _fetchAllAppointments();
//       });
//     }
//   }
//
//   Future<void> _deleteAppointment(AppointmentModel appointment) async {
//     try {
//       final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
//
//       if (await appointmentManager.cancelAppointment(appointment.appointmentId, appointment.userId, canceledBy: 'admin')) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Appointment canceled.')),
//         );
//       }
//
//       _fetchAllAppointments();
//     } catch (e) {
//       logger.err('Error canceling appointment: {}', [e]);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error canceling appointment: $e')),
//       );
//     }
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
//               _fetchAllAppointments();
//             });
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Appointments'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 _fetchAllAppointments();
//               });
//             },
//             tooltip: 'Refresh',
//           ),
//           IconButton(
//             icon: const Icon(Icons.date_range),
//             onPressed: _pickDateRange,
//           ),
//           DropdownButton<MeetingType?>(
//             value: selectedMeetingType,
//             hint: const Text('Meeting Type'),
//             items: meetingTypes.map((type) {
//               return DropdownMenuItem<MeetingType?>(
//                 value: type,
//                 child: Text(type == null ? 'All' : type.label),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 selectedMeetingType = value;
//                 _fetchAllAppointments();
//               });
//             },
//           ),
//           DropdownButton<AppointmentStatus?>(
//             value: selectedMeetingStatus,
//             hint: const Text('Meeting Status'),
//             items: meetingStatuses.map((status) {
//               return DropdownMenuItem<AppointmentStatus?>(
//                 value: status,
//                 child: Text(status == null ? 'All' : status.label),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 selectedMeetingStatus = value;
//                 _fetchAllAppointments();
//               });
//             },
//           ),
//           DropdownButton<String>(
//             value: sortOption,
//             hint: const Text('Sort by'),
//             items: sortOptions.map((option) {
//               return DropdownMenuItem<String>(
//                 value: option,
//                 child: Text(option),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 sortOption = value;
//                 _fetchAllAppointments();
//               });
//             },
//           ),
//           if (startDate != null || endDate != null || selectedMeetingType != null || selectedMeetingStatus != null)
//             IconButton(
//               icon: const Icon(Icons.clear),
//               onPressed: () {
//                 setState(() {
//                   startDate = null;
//                   endDate = null;
//                   selectedMeetingType = null;
//                   selectedMeetingStatus = null;
//                   _fetchAllAppointments();
//                 });
//               },
//             ),
//         ],
//       ),
//       body: FutureBuilder<List<AppointmentModel>>(
//         future: _appointmentsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             logger.err('Error fetching appointments in build method: {}', [snapshot.error??'snapshot error']);
//             return Center(child: Text('Error fetching appointments: ${snapshot.error}'));
//           } else {
//             final appointments = snapshot.data ?? [];
//
//             if (appointments.isEmpty) {
//               return const Center(child: Text('No appointments found.'));
//             }
//
//             return ListView.builder(
//               itemCount: appointments.length,
//               itemBuilder: (context, index) {
//                 AppointmentModel appointment = appointments[index];
//                 return ListTile(
//                   title: Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.appointmentDateTime)}'),
//                   subtitle: Text(
//                       'User: ${appointment.user?.name ?? 'Unknown'}\nType: ${appointment.meetingType.label}\nStatus: ${appointment.status.label}\nCanceled By: ${appointment.canceledBy ?? 'N/A'}'),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.edit),
//                         onPressed: () {
//                           _showEditAppointmentDialog(context, appointment);
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.cancel, color: Colors.red),
//                         onPressed: () async {
//                           bool? confirmDelete = await showDialog<bool>(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 title: const Text("Cancel Appointment"),
//                                 content: const Text("Are you sure you want to cancel this appointment?"),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop(false);
//                                     },
//                                     child: const Text("No"),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop(true);
//                                     },
//                                     child: const Text("Yes"),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//
//                           if (confirmDelete == true) {
//                             await _deleteAppointment(appointment);
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../models/logger.dart';
// import '../models/user_model.dart';
//
// final Logger logger = Logger.forClass(CreateUserPage);
//
// class CreateUserPage extends StatefulWidget {
//   const CreateUserPage({super.key});
//   static const String tempPw='TempPassword123!';
//   @override
//   createState() => _CreateUserPageState();
// }
//
// class _CreateUserPageState extends State<CreateUserPage> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _surnameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _referenceController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   String _statusMessage = '';
//
//   Future<void> createUser({
//     required String name,
//     String? email,
//     String? password,
//     String? surname,
//     int? age,
//     String? reference,
//     String? notes,
//   }) async {
//     if (name.isEmpty) {
//       _showMessageDialog('Hata', 'Lütfen isim alanını doldurunuz.');
//       return;
//     }
//
//     // Generate email and password if not provided
//     email ??= '${name.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}@example.com';
//     password ??= CreateUserPage.tempPw; // Temporary default password
//
//     try {
//       // Check if a user with the same email already exists
//       final existingUserQuery = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();
//
//       if (existingUserQuery.docs.isNotEmpty) {
//         _showMessageDialog(
//           'Hata',
//           'Bu e-posta adresiyle bir kullanıcı zaten mevcut. Lütfen farklı bir e-posta giriniz.',
//         );
//         return;
//       }
//
//       // Create Firebase Authentication user
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       final userId = userCredential.user?.uid;
//
//       if (userId == null) {
//         throw Exception('Firebase Authentication kullanıcı oluşturulamadı.');
//       }
//
//       // Create a UserModel instance
//       final newUser = UserModel(
//         userId: userId,
//         name: name,
//         email: email,
//         password: password,
//         role: 'customer',
//         createdAt: DateTime.now(),
//         surname: surname,
//         age: age,
//         reference: reference,
//         notes: notes,
//       );
//
//       // Store user data in Firestore
//       await _firestore.collection('users').doc(userId).set(newUser.toMap());
//
//       _showMessageDialog('Başarılı', 'Kullanıcı $name başarıyla oluşturuldu.');
//       logger.info('User created: {}', [newUser]);
//     } catch (e) {
//       logger.err('Kullanıcı oluşturulamadı: {}', [e.toString()]);
//       _showMessageDialog('Hata', 'Kullanıcı oluşturulamadı. Hata: $e');
//     }
//   }
//
//   void _showMessageDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Tamam'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Yeni Kullanıcı Oluştur'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'İsim Giriniz',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _surnameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Soyisim Giriniz (Opsiyonel)',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _ageController,
//                 decoration: const InputDecoration(
//                   labelText: 'Yaş Giriniz (Opsiyonel)',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _referenceController,
//                 decoration: const InputDecoration(
//                   labelText: 'Referans Giriniz (Opsiyonel)',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _notesController,
//                 decoration: const InputDecoration(
//                   labelText: 'Notlar (Opsiyonel)',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'E-posta Giriniz (Opsiyonel)',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(
//                   labelText: 'Şifre Giriniz (Opsiyonel)',
//                   border: OutlineInputBorder(),
//                 ),
//                 obscureText: true,
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () {
//                   final name = _nameController.text.trim();
//                   final surname = _surnameController.text.trim();
//                   final age = int.tryParse(_ageController.text.trim());
//                   final reference = _referenceController.text.trim();
//                   final notes = _notesController.text.trim();
//                   final email = _emailController.text.trim().isNotEmpty
//                       ? _emailController.text.trim()
//                       : null;
//                   final password = _passwordController.text.trim().isNotEmpty
//                       ? _passwordController.text.trim()
//                       : null;
//
//                   createUser(
//                     name: name,
//                     email: email,
//                     password: password,
//                     surname: surname.isNotEmpty ? surname : null,
//                     age: age,
//                     reference: reference.isNotEmpty ? reference : null,
//                     notes: notes.isNotEmpty ? notes : null,
//                   );
//                 },
//                 child: const Text('Kullanıcı Oluştur'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _surnameController.dispose();
//     _ageController.dispose();
//     _referenceController.dispose();
//     _notesController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/logger.dart';
// import '../models/user_model.dart';
// import '../providers/user_provider.dart';
// import 'customer_sum.dart';
//
// final Logger logger = Logger.forClass(AdminImages);
//
// class AdminImages extends StatefulWidget {
//   const AdminImages({super.key});
//
//   @override
//   State<AdminImages> createState() => _AdminImagesState();
// }
//
// class _AdminImagesState extends State<AdminImages> {
//   late Future<List<UserModel>> _usersFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _usersFuture = Provider.of<UserProvider>(context, listen: false).fetchUsers();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Panel - Users'),
//       ),
//       body: FutureBuilder<List<UserModel>>(
//         future: _usersFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             logger.err('Error fetching users: {}', [snapshot.error??'snapshot error']);
//             return Center(child: Text('Error fetching users: ${snapshot.error}'));
//           } else {
//             final users = snapshot.data ?? [];
//
//             if (users.isEmpty) {
//               return const Center(child: Text('No users found.'));
//             }
//
//             return ListView.builder(
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 final user = users[index];
//                 return ListTile(
//                   title: Text(user.name),
//                   subtitle: Text(user.email),
//                   onTap: () {
//                     Navigator.of(context).push(
//                       MaterialPageRoute(
//                         builder: (context) => CustomerSummaryPage(userId: user.userId),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// import '../models/logger.dart';
//
// final Logger logger = Logger.forClass(AdminTimeSlotsPage);
//
// class AdminTimeSlotsPage extends StatefulWidget {
//   const AdminTimeSlotsPage({Key? key}) : super(key: key);
//
//   @override
//   _AdminTimeSlotsPageState createState() => _AdminTimeSlotsPageState();
// }
//
// class _AdminTimeSlotsPageState extends State<AdminTimeSlotsPage> {
//   DateTime _selectedDate = DateTime.now();
//   Map<String, bool> _timeSlots = {}; // Map of time string to availability
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchTimeSlotsForDate(_selectedDate);
//   }
//
//   Future<void> _fetchTimeSlotsForDate(DateTime date) async {
//     setState(() {
//       _isLoading = true;
//       _timeSlots.clear();
//     });
//
//     try {
//       String dateString = DateFormat('yyyy-MM-dd').format(date);
//       DocumentSnapshot timeslotDoc = await FirebaseFirestore.instance
//           .collection('admininput')
//           .doc('timeslots')
//           .collection('dates')
//           .doc(dateString)
//           .get();
//
//       List<String> availableTimes = [];
//       if (timeslotDoc.exists) {
//         Map<String, dynamic> data = timeslotDoc.data() as Map<String, dynamic>;
//         availableTimes = List<String>.from(data['times'] ?? []);
//       }
//
//       // Generate all possible time slots for the day
//       _timeSlots = _generateAllTimeSlots();
//
//       // Mark available times
//       for (String time in availableTimes) {
//         if (_timeSlots.containsKey(time)) {
//           _timeSlots[time] = true;
//         }
//       }
//
//       setState(() {});
//     } catch (e) {
//       logger.err('Error fetching time slots: {}', [e]);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching time slots: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Map<String, bool> _generateAllTimeSlots() {
//     Map<String, bool> timeSlots = {};
//     DateTime startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 9, 0);
//     DateTime endDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 19, 0);
//
//     DateTime currentTime = startDateTime;
//     while (!currentTime.isAfter(endDateTime)) {
//       String timeString = DateFormat('HH:mm').format(currentTime);
//       timeSlots[timeString] = false; // Initially set all slots to unavailable
//       currentTime = currentTime.add(const Duration(minutes: 30));
//     }
//
//     return timeSlots;
//   }
//
//   Future<void> _updateTimeSlot(String timeString, bool isAvailable) async {
//     setState(() {
//       _timeSlots[timeString] = isAvailable;
//     });
//
//     String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
//     DocumentReference docRef = FirebaseFirestore.instance
//         .collection('admininput')
//         .doc('timeslots')
//         .collection('dates')
//         .doc(dateString);
//
//     try {
//       DocumentSnapshot timeslotDoc = await docRef.get();
//       List<String> availableTimes = [];
//       if (timeslotDoc.exists) {
//         Map<String, dynamic> data = timeslotDoc.data() as Map<String, dynamic>;
//         availableTimes = List<String>.from(data['times'] ?? []);
//       }
//
//       if (isAvailable) {
//         // Add time to available times
//         if (!availableTimes.contains(timeString)) {
//           availableTimes.add(timeString);
//         }
//       } else {
//         // Remove time from available times
//         availableTimes.remove(timeString);
//       }
//
//       await docRef.set({'times': availableTimes});
//     } catch (e) {
//       logger.err('Error updating time slot: {}', [e]);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating time slot: $e')),
//       );
//     }
//   }
//
//   void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
//     setState(() {
//       _selectedDate = selectedDay;
//       _fetchTimeSlotsForDate(_selectedDate);
//     });
//   }
//
//   Widget _buildTimeSlotsGrid() {
//     return GridView.builder(
//       shrinkWrap: true,
//       itemCount: _timeSlots.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4, // Adjust according to your UI preference
//         childAspectRatio: 2,
//       ),
//       itemBuilder: (context, index) {
//         String timeString = _timeSlots.keys.elementAt(index);
//         bool isAvailable = _timeSlots[timeString]!;
//         return GestureDetector(
//           onTap: () {
//             bool newAvailability = !isAvailable;
//             _updateTimeSlot(timeString, newAvailability);
//           },
//           child: Card(
//             color: isAvailable ? Colors.green[200] : Colors.red[200],
//             child: Center(
//               child: Text(
//                 timeString,
//                 style: TextStyle(
//                   color: isAvailable ? Colors.black : Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Time Slots'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           // Calendar Widget
//           TableCalendar(
//             firstDay: DateTime.now().subtract(const Duration(days: 365)),
//             lastDay: DateTime.now().add(const Duration(days: 365)),
//             focusedDay: _selectedDate,
//             selectedDayPredicate: (day) {
//               return isSameDay(_selectedDate, day);
//             },
//             onDaySelected: _onDaySelected,
//           ),
//           const SizedBox(height: 16),
//           // Date Display
//           Text(
//             'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           // Time Slots Grid
//           Expanded(
//             child: _buildTimeSlotsGrid(),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/logger.dart';
// import '../models/meal_model.dart';
// import '../models/user_model.dart';
// final Logger logger = Logger.forClass(UserImagesPage);
//
// class UserImagesPage extends StatefulWidget {
//   final String userId;
//
//   const UserImagesPage({super.key, required this.userId});
//
//   @override
//    createState() => _UserImagesPageState();
// }
//
// class _UserImagesPageState extends State<UserImagesPage> {
//   List<MealModel> meals = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUserMeals();
//   }
//
//   Future<void> fetchUserMeals() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('meals')
//           .orderBy('timestamp', descending: true)
//           .get();
//
//       setState(() {
//         meals = snapshot.docs.map((doc) => MealModel.fromDocument(doc)).toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       logger.err('Error fetching user meals:{}',[e]);
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<UserModel?> fetchUserDetails() async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .get();
//
//       if (doc.exists) {
//         return UserModel.fromDocument(doc);
//       }
//     } catch (e) {
//       logger.err('Error fetching user details:{}',[e]);
//     }
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<UserModel?>(
//       future: fetchUserDetails(),
//       builder: (context, userSnapshot) {
//         String title = 'User Images';
//         if (userSnapshot.hasData) {
//           title = '${userSnapshot.data!.name}\'s Images';
//         }
//
//         return Scaffold(
//           appBar: AppBar(
//             title: Text(title),
//           ),
//           body: isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : meals.isEmpty
//               ? const Center(child: Text('No images found.'))
//               : GridView.builder(
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 4.0,
//               mainAxisSpacing: 4.0,
//             ),
//             itemCount: meals.length,
//             itemBuilder: (context, index) {
//               MealModel meal = meals[index];
//               return InkWell(
//                 onTap: () {
//                   showFullImage(context, meal.imageUrl, meal);
//                 },
//                 child: Image.network(
//                   meal.imageUrl,
//                   fit: BoxFit.cover,
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   void showFullImage(BuildContext context, String imageUrl, MealModel meal) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.network(imageUrl),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   'Meal Type: ${meal.mealType.label}\n'
//                       'Timestamp: ${meal.timestamp}\n'
//                       'Description: ${meal.description ?? 'N/A'}',
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../models/appointment_model.dart';
// import '../models/logger.dart';
// import '../providers/appointment_manager.dart';
// import 'meal_upload_page.dart';
//
// final Logger logger = Logger.forClass(AppointmentsPage);
//
// class AppointmentsPage extends StatefulWidget {
//   final String userId;
//   final String subscriptionId;
//
//   const AppointmentsPage({
//     Key? key,
//     required this.userId,
//     required this.subscriptionId,
//   }) : super(key: key);
//
//   @override
//   createState() => _AppointmentsPageState();
// }
//
// class _AppointmentsPageState extends State<AppointmentsPage> {
//   DateTime _selectedDate = DateTime.now();
//   MeetingType _selectedMeetingType = MeetingType.f2f;
//   TimeOfDay? _selectedTime;
//   late Future<List<TimeOfDay>> _availableTimesFuture;
//   late Future<List<AppointmentModel>> _userAppointmentsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     logger.info('Initializing AppointmentsPage state.');
//     _fetchAvailableTimes();
//     _fetchUserAppointments();
//   }
//
//   void _fetchAvailableTimes() {
//     final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
//     _availableTimesFuture = appointmentManager.getAvailableTimesForDate(_selectedDate);
//   }
//
//   void _fetchUserAppointments() {
//     final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
//     _userAppointmentsFuture =
//         appointmentManager.fetchAppointments(showAllAppointments: true, userId: widget.userId);
//   }
//
//   Future<void> _bookAppointment() async {
//     if (_selectedTime == null) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Lütfen bir zaman dilimi seçin.')),
//       );
//       return;
//     }
//
//     try {
//       final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
//
//       DateTime appointmentDateTime = DateTime(
//         _selectedDate.year,
//         _selectedDate.month,
//         _selectedDate.day,
//         _selectedTime!.hour,
//         _selectedTime!.minute,
//       );
//
//       // Check if the selected time slot is still available
//       List<TimeOfDay> availableTimes =
//       await appointmentManager.getAvailableTimesForDate(_selectedDate);
//       bool isAvailable = availableTimes.contains(_selectedTime);
//
//       if (!mounted) return;
//       if (!isAvailable) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Seçtiğiniz saat/tarih uygun değildir.')),
//         );
//         return;
//       }
//
//       String appointmentId = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('appointments')
//           .doc()
//           .id;
//
//       AppointmentModel appointment = AppointmentModel(
//         appointmentId: appointmentId,
//         userId: widget.userId,
//         subscriptionId: widget.subscriptionId,
//         meetingType: _selectedMeetingType,
//         appointmentDateTime: appointmentDateTime,
//         status: AppointmentStatus.scheduled,
//         createdAt: DateTime.now(),
//         createdBy: 'user',
//       );
//
//       await appointmentManager.addAppointment(appointment);
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Randevu başarıyla oluşturuldu.')),
//       );
//
//       // Refresh available times and user's appointments
//       setState(() {
//         _fetchAvailableTimes();
//         _fetchUserAppointments();
//         _selectedTime = null;
//       });
//     } catch (e, stackTrace) {
//       logger.err('Error booking appointment: {}', [e]);
//       logger.err('Stack trace: {}', [stackTrace]);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Randevu oluşturulurken bir hata oluştu.')),
//       );
//     }
//   }
//
//   Future<void> _cancelAppointment(AppointmentModel appointment) async {
//     try {
//       final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
//
//       if (await appointmentManager.cancelAppointment(
//           appointment.appointmentId, appointment.userId,
//           canceledBy: 'user')) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Randevu iptal edildi.')),
//         );
//       }
//       setState(() {
//         _fetchAvailableTimes();
//         _fetchUserAppointments();
//       });
//     } catch (e, stackTrace) {
//       logger.err('Error canceling appointment: {}', [e]);
//       logger.err('Stack trace: {}', [stackTrace]);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Randevu iptal edilirken bir hata oluştu: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     logger.info('Building AppointmentsPage');
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Randevularım'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Meeting Type Selector
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     Icon(Icons.event_available, color: Colors.deepPurple, size: 30),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Görüşme Türü:',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.deepPurple,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     DropdownButton<MeetingType>(
//                       value: _selectedMeetingType,
//                       onChanged: (MeetingType? newValue) {
//                         setState(() {
//                           _selectedMeetingType = newValue!;
//                         });
//                       },
//                       items: MeetingType.values
//                           .map<DropdownMenuItem<MeetingType>>((MeetingType type) {
//                         return DropdownMenuItem<MeetingType>(
//                           value: type,
//                           child: Text(type.label),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Date Picker
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: ListTile(
//                 leading: Icon(Icons.calendar_today, color: Colors.blueAccent),
//                 title: Text(
//                   DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 trailing: const Icon(Icons.edit_calendar, color: Colors.blueAccent),
//                 onTap: () async {
//                   final DateTime? picked = await showDatePicker(
//                     context: context,
//                     initialDate: _selectedDate,
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime.now().add(const Duration(days: 45)),
//                     locale: const Locale('tr', 'TR'),
//                   );
//                   if (picked != null && picked != _selectedDate) {
//                     setState(() {
//                       _selectedDate = picked;
//                       _selectedTime = null;
//                     });
//                     _fetchAvailableTimes();
//                   }
//                 },
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Available Time Slots
//             Text(
//               'Uygun Saatler',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
//             ),
//             const SizedBox(height: 8),
//             FutureBuilder<List<TimeOfDay>>(
//               future: _availableTimesFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   logger.err('Error fetching available times: {}', [snapshot.error!]);
//                   return Text('Zaman dilimleri alınırken bir hata oluştu: ${snapshot.error}');
//                 } else {
//                   List<TimeOfDay> availableTimes = snapshot.data ?? [];
//                   // Sort the times
//                   availableTimes.sort((a, b) {
//                     if (a.hour != b.hour) {
//                       return a.hour.compareTo(b.hour);
//                     } else {
//                       return a.minute.compareTo(b.minute);
//                     }
//                   });
//                   if (availableTimes.isEmpty) {
//                     return const Text('Seçilen tarih için uygun zaman dilimi yok.');
//                   } else {
//                     return Wrap(
//                       spacing: 8.0,
//                       runSpacing: 8.0,
//                       children: availableTimes.map((time) {
//                         return ChoiceChip(
//                           label: Text(
//                             MealUploadPage.formatTimeOfDay24(time),
//                             style: TextStyle(
//                               color: _selectedTime == time ? Colors.white : Colors.black,
//                             ),
//                           ),
//                           selected: _selectedTime == time,
//                           selectedColor: Colors.deepPurple,
//                           backgroundColor: Colors.grey[200],
//                           onSelected: (bool selected) {
//                             setState(() {
//                               _selectedTime = selected ? time : null;
//                             });
//                           },
//                         );
//                       }).toList(),
//                     );
//                   }
//                 }
//               },
//             ),
//             const SizedBox(height: 16),
//             // Book Appointment Button
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: _bookAppointment,
//                 icon: const Icon(Icons.check_circle_outline),
//                 label: const Text('Randevu Al'),
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white, backgroundColor: Colors.green,
//                   textStyle: const TextStyle(fontSize: 18),
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             // User's Appointments
//             Text(
//               'Randevularım',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
//             ),
//             const SizedBox(height: 8),
//             FutureBuilder<List<AppointmentModel>>(
//               future: _userAppointmentsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   logger.err('Error fetching appointments: {}', [snapshot.error!]);
//                   return Text('Randevular alınırken bir hata oluştu: ${snapshot.error}');
//                 } else {
//                   List<AppointmentModel> appointments = snapshot.data ?? [];
//                   return _buildAppointmentsList(appointments);
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAppointmentsList(List<AppointmentModel> appointments) {
//     final upcomingAppointments = appointments.where((appointment) {
//       return appointment.appointmentDateTime.isAfter(DateTime.now()) &&
//           appointment.status != AppointmentStatus.canceled &&
//           !(appointment.isDeleted ?? false);
//     }).toList();
//
//     if (upcomingAppointments.isEmpty) {
//       return const Text('Gelecek randevunuz bulunmamaktadır.');
//     }
//     logger.info('Upcoming Appointments: {}', [upcomingAppointments]);
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: upcomingAppointments.length,
//       itemBuilder: (context, index) {
//         AppointmentModel appointment = upcomingAppointments[index];
//         return Card(
//           elevation: 4,
//           margin: const EdgeInsets.symmetric(vertical: 8),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: ListTile(
//             leading: Icon(Icons.event_note, color: Colors.deepPurple),
//             title: Text(
//               DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR')
//                   .format(appointment.appointmentDateTime),
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text('Görüşme Türü: ${appointment.meetingType.label}'),
//             trailing: IconButton(
//               icon: const Icon(Icons.cancel, color: Colors.red),
//               onPressed: () async {
//                 bool? confirmCancel = await showDialog<bool>(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return AlertDialog(
//                       title: const Text("Randevuyu İptal Et"),
//                       content: const Text("Bu randevuyu iptal etmek istediğinize emin misiniz?"),
//                       actions: [
//                         TextButton(
//                           onPressed: () {
//                             Navigator.of(context).pop(false);
//                           },
//                           child: const Text("Hayır"),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.of(context).pop(true);
//                           },
//                           child: const Text("Evet"),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//
//                 if (confirmCancel == true) {
//                   await _cancelAppointment(appointment);
//                 }
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../models/logger.dart';
// final Logger log = Logger.forClass(ChangePasswordPage);
//
// class ChangePasswordPage extends StatefulWidget {
//   const ChangePasswordPage({super.key});
//
//   @override
//   createState() => _ChangePasswordPageState();
// }
//
// class _ChangePasswordPageState extends State<ChangePasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _currentPasswordController = TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   String _statusMessage = '';
//
//   Future<void> reauthenticateAndChangePassword(String email, String currentPassword, String newPassword) async {
//     User? user = FirebaseAuth.instance.currentUser;
//
//     if (user == null) {
//       setState(() {
//         _statusMessage = 'Giriş yapmış bir kullanıcı bulunmuyor.';
//       });
//       return;
//     }
//
//     try {
//       // Re-authenticate the user
//       AuthCredential credential = EmailAuthProvider.credential(
//         email: email,
//         password: currentPassword,
//       );
//       await user.reauthenticateWithCredential(credential);
//       log.info('User re-authenticated successfully.');
//
//       // Update the password
//       await user.updatePassword(newPassword);
//       log.info('Password updated successfully.');
//
//       // Optionally, sign the user out and redirect to login page
//       await FirebaseAuth.instance.signOut();
//       log.info('User signed out. Redirect to login page.');
//
//       setState(() {
//         _statusMessage = 'Şifre başarıyla değiştirildi. Lütfen tekrar giriş yapınız..';
//       });
//
//       // Here you would typically navigate to the login page.
//       // Navigator.of(context).pushReplacementNamed('/login');
//
//     } catch (e) {
//       setState(() {
//         _statusMessage = 'Şifre değiştirilemedi. Lütfen destek isteyiniz.';
//       });
//       log.info('Failed to update password: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Change Password'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter Email',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _currentPasswordController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter Current Password',
//                 border: OutlineInputBorder(),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _newPasswordController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter New Password',
//                 border: OutlineInputBorder(),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _confirmPasswordController,
//               decoration: const InputDecoration(
//                 labelText: 'Confirm New Password',
//                 border: OutlineInputBorder(),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () async {
//                 final email = _emailController.text.trim();
//                 final currentPassword = _currentPasswordController.text.trim();
//                 final newPassword = _newPasswordController.text.trim();
//                 final confirmPassword = _confirmPasswordController.text.trim();
//
//                 if (email.isEmpty || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
//                   setState(() {
//                     _statusMessage = 'Please fill in all fields.';
//                   });
//                   return;
//                 }
//
//                 if (newPassword != confirmPassword) {
//                   setState(() {
//                     _statusMessage = 'New passwords do not match.';
//                   });
//                   return;
//                 }
//
//                 await reauthenticateAndChangePassword(email, currentPassword, newPassword);
//               },
//               child: const Text('Change Password'),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _statusMessage,
//               style: TextStyle(
//                 color: _statusMessage.contains('successfully') ? Colors.green : Colors.red,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _currentPasswordController.dispose();
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../models/logger.dart';
// import '../models/subs_model.dart';
// import '../models/user_model.dart';
// import '../providers/appointment_manager.dart';
// import '../providers/meal_state_and_upload_manager.dart';
// import '../providers/payment_provider.dart';
// import '../providers/user_provider.dart';
// import '../tabs/appointments_tab.dart';
// import '../tabs/details_tab.dart';
// import '../tabs/images_tab.dart';
// import '../tabs/payment_tab.dart';
// import '../tabs/sub_tab.dart';
// import '../dialogs/add_appointment_dialog.dart';
// import '../dialogs/add_image_dialog.dart';
// import '../dialogs/add_payment_dialog.dart';
// import '../dialogs/add_sub_dialog.dart';
// import '../dialogs/add_test_dialog.dart';
//
// final Logger logger = Logger.forClass(CustomerSummaryPage);
//
// class CustomerSummaryPage extends StatefulWidget {
//   final String userId;
//
//   const CustomerSummaryPage({super.key, required this.userId});
//
//   @override
//   createState() => _CustomerSummaryPageState();
// }
//
// class _CustomerSummaryPageState extends State<CustomerSummaryPage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int _previousTabIndex = 0;
//
//   UserModel? _user;
//   List<SubscriptionModel> _subscriptions = [];
//   SubscriptionModel? _selectedSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _tabController = TabController(length: 6, vsync: this);
//     _tabController.addListener(() {
//       if (_tabController.index != _previousTabIndex) {
//         logger.info('Tab changed: index={}', [_tabController.index]);
//         _previousTabIndex = _tabController.index;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context, listen: false);
//     logger.info('Initializing CustomerSummaryPage with userId={}', [widget.userId]);
//     userProvider.setUserId(widget.userId);
//
//     Provider.of<MealStateManager>(context, listen: false).setUserId(widget.userId);
//     Provider.of<PaymentProvider>(context, listen: false).setUserId(widget.userId);
//
//     return FutureBuilder<UserModel?>(
//       future: userProvider.fetchUserDetails(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         } else if (snapshot.hasError) {
//           logger.err('Error fetching user details: {}', [snapshot.error!]);
//           return Scaffold(
//             body: Center(
//               child: Text('Kullanıcı detayları alınırken bir hata oluştu: ${snapshot.error}'),
//             ),
//           );
//         } else if (!snapshot.hasData || snapshot.data == null) {
//           logger.warn('User data not found for userId={}', [widget.userId]);
//           return Scaffold(
//             body: const Center(child: Text('Kullanıcı bilgisi bulunamadı.')),
//           );
//         } else {
//           _user = snapshot.data;
//           return _buildScaffold(_user!);
//         }
//       },
//     );
//   }
//
//   Widget _buildScaffold(UserModel user) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${user.name} - Özet'),
//         actions: [
//           _buildSubscriptionDropdown(context),
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: _onAddButtonPressed,
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Detaylar'),
//             Tab(text: 'Randevular'),
//             Tab(text: 'Ödemeler'),
//             Tab(text: 'Resimler'),
//             Tab(text: 'Testler'),
//             Tab(text: 'Abonelikler'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           DetailsTab(userId: user.userId),
//           AppointmentsTab(userId: user.userId),
//           PaymentsTab(userId: user.userId),
//           ImagesTab(userId: user.userId),
//           const Center(child: Text('Testler Sekmesi')), // Placeholder
//           SubscriptionsTab(userId: user.userId),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _onAddButtonPressed,
//         label: const Text('Ekle'),
//         icon: const Icon(Icons.add),
//       ),
//     );
//   }
//
//   Widget _buildSubscriptionDropdown(BuildContext context) {
//     return FutureBuilder<List<SubscriptionModel>>(
//       future: Provider.of<UserProvider>(context, listen: false)
//           .fetchSubscriptions(showAllSubscriptions: false),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const CircularProgressIndicator();
//         } else if (snapshot.hasError) {
//           logger.err('Error fetching subscriptions: {}', [snapshot.error!]);
//           return const SizedBox();
//         } else {
//           _subscriptions = snapshot.data ?? [];
//           if (_subscriptions.isEmpty) {
//             logger.warn('No subscriptions found for userId={}', [widget.userId]);
//             return Container();
//           }
//
//           if (_selectedSubscription == null) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) {
//                 setState(() {
//                   _selectedSubscription = _subscriptions.first;
//                   final newValue = _selectedSubscription!.subscriptionId;
//                   Provider.of<AppointmentManager>(context, listen: false)
//                       .setSelectedSubscriptionId(newValue);
//                   Provider.of<MealStateManager>(context, listen: false)
//                       .setSelectedSubscriptionId(newValue);
//                   Provider.of<PaymentProvider>(context, listen: false)
//                       .setSelectedSubscriptionId(newValue);
//                   logger.info('Default subscription selected: subscriptionId={}', [newValue]);
//                 });
//               }
//             });
//           }
//
//           return DropdownButton<String>(
//             value: _selectedSubscription?.subscriptionId,
//             onChanged: (String? newValue) {
//               if (newValue == null) return;
//               setState(() {
//                 _selectedSubscription = _subscriptions.firstWhere(
//                       (sub) => sub.subscriptionId == newValue,
//                 );
//                 logger.info('Subscription selected: subscriptionId={}', [newValue]);
//                 Provider.of<AppointmentManager>(context, listen: false)
//                     .setSelectedSubscriptionId(newValue);
//                 Provider.of<MealStateManager>(context, listen: false)
//                     .setSelectedSubscriptionId(newValue);
//                 Provider.of<PaymentProvider>(context, listen: false)
//                     .setSelectedSubscriptionId(newValue);
//               });
//             },
//             items: _subscriptions.map<DropdownMenuItem<String>>((SubscriptionModel sub) {
//               return DropdownMenuItem<String>(
//                 value: sub.subscriptionId,
//                 child: Text(
//                   '${sub.packageName} (${sub.startDate.toLocal().toString().split(' ')[0]})',
//                 ),
//               );
//             }).toList(),
//           );
//         }
//       },
//     );
//   }
//
//   void _onAddButtonPressed() {
//     final currentIndex = _tabController.index;
//     logger.info('Add button pressed: tabIndex={}', [currentIndex]);
//
//     try {
//       switch (currentIndex) {
//         case 1:
//           _showAddAppointmentDialog();
//           break;
//         case 2:
//           _showAddPaymentDialog();
//           break;
//         case 3:
//           _showAddImageDialog();
//           break;
//         case 5:
//           _showAddSubscriptionDialog();
//           break;
//         default:
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Bu sekme için ekleme yapılamaz.')),
//           );
//       }
//     } catch (e) {
//       logger.err('Error while handling add button: {}', [e]);
//     }
//   }
//
//   void _showAddSubscriptionDialog() {
//     final userId = _user?.userId ?? widget.userId;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AddSubscriptionDialog(
//           userId: userId,
//           onSubscriptionAdded: () {
//             setState(() {
//               _selectedSubscription = null; // Reset selection
//             });
//             logger.info('Subscription added and refreshed for userId={}', [userId]);
//           },
//         );
//       },
//     );
//   }
//
//   void _showAddAppointmentDialog() {
//     final subscriptionId = _selectedSubscription?.subscriptionId;
//     if (subscriptionId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Lütfen bir abonelik seçin.')),
//       );
//       return;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AddAppointmentDialog(
//           userId: widget.userId,
//           subscriptionId: subscriptionId,
//           onAppointmentAdded: () {
//             logger.info('Appointment added for userId={}, subscriptionId={}', [widget.userId, subscriptionId]);
//           },
//         );
//       },
//     );
//   }
//
//   void _showAddPaymentDialog() {
//     final subscription = _selectedSubscription;
//     if (subscription == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Lütfen bir abonelik seçin.')),
//       );
//       return;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AddPaymentDialog(
//           userId: widget.userId,
//           subscription: subscription,
//           onPaymentAdded: () {
//             logger.info('Payment added for userId={}, subscriptionId={}', [widget.userId, subscription.subscriptionId]);
//           },
//         );
//       },
//     );
//   }
//
//   void _showAddImageDialog() {
//     final subscriptionId = _selectedSubscription?.subscriptionId;
//     if (subscriptionId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Lütfen bir abonelik seçin.')),
//       );
//       return;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AddImageDialog(
//           userId: widget.userId,
//           subscriptionId: subscriptionId,
//           onImageAdded: () {
//             logger.info('Image added for userId={}, subscriptionId={}', [widget.userId, subscriptionId]);
//           },
//         );
//       },
//     );
//   }
// }
// // dekont_viewer_page.dart
//
// import 'package:flutter/material.dart';
//
// class DekontViewerPage extends StatelessWidget {
//   final String dekontUrl;
//
//   const DekontViewerPage({super.key, required this.dekontUrl});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dekont Viewer'),
//       ),
//       body: Center(
//         child: Image.network(
//           dekontUrl,
//           fit: BoxFit.contain,
//           loadingBuilder: (context, child, progress) {
//             if (progress == null) return child;
//             return const CircularProgressIndicator();
//           },
//           errorBuilder: (context, error, stackTrace) {
//             return const Text('Error loading image.');
//           },
//         ),
//       ),
//     );
//   }
// }
// // login_page.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:untitled/pages/reset_password_page.dart';
// import 'package:untitled/pages/user_past_appointments_page.dart';
// import 'package:untitled/pages/user_payments_page.dart';
// import 'admin_appointments_page.dart';
// import 'admin_timeslots_page.dart';
// import 'appointments_page.dart';
// import '../models/logger.dart';
// import '../providers/login_manager.dart';
// import 'admin_create_user_page.dart';
// import 'admin_images_page.dart';
// import '../diet_list_pages/file_handler_page.dart';
// import 'meal_upload_page.dart';
//
// final Logger logger = Logger.forClass(LoginPage);
//
// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});
//
//   Future<String?> getCurrentSubscriptionId(String userId) async {
//     logger.info('getting sub id for user with userId={}', [userId]);
//     final subscriptionsCollection = FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .collection('subscriptions');
//
//     final querySnapshot = await subscriptionsCollection
//         .where('status', isEqualTo: 'active')
//         .orderBy('startDate', descending: true)
//         .limit(1)
//         .get();
//
//     if (querySnapshot.docs.isNotEmpty) {
//       final doc = querySnapshot.docs.first;
//       return doc.id;
//     } else {
//       return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Kullanıcı Girişi'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Consumer<LoginProvider>(
//           builder: (context, loginProvider, child) {
//             String errorMessage = loginProvider.errorMessage;
//             bool isLoading = loginProvider.isLoading;
//
//             if (errorMessage.isNotEmpty) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _showErrorDialog(context, errorMessage);
//                 loginProvider.clearError();
//               });
//             }
//
//             return loginProvider.isLoggedIn
//                 ? _buildHomePageContent(context)
//                 : _buildLoginForm(context, loginProvider, screenWidth, isLoading);
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoginForm(BuildContext context, LoginProvider loginProvider,
//       double screenWidth, bool isLoading) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: <Widget>[
//         SizedBox(
//           width: screenWidth * 0.7,
//           child: TextField(
//             controller: loginProvider.emailController,
//             keyboardType: TextInputType.emailAddress,
//             decoration: const InputDecoration(
//               hintText: 'Emailinizi giriniz',
//               labelText: 'Email',
//               border: OutlineInputBorder(),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         SizedBox(
//           width: screenWidth * 0.7,
//           child: TextField(
//             controller: loginProvider.passwordController,
//             obscureText: true,
//             decoration: const InputDecoration(
//               hintText: 'Şifrenizi giriniz',
//               labelText: 'Şifre',
//               border: OutlineInputBorder(),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: isLoading ? null : () => loginProvider.login(context),
//           child: isLoading
//               ? const CircularProgressIndicator()
//               : const Text('Giriş Yap'),
//         ),
//         const SizedBox(height: 10),
//         TextButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => const ResetPasswordPage(email: '')),
//             );
//           },
//           child: const Text('Şifremi Unuttum'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildHomePageContent(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ana Sayfa'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: GridView.count(
//           crossAxisCount: 2,
//           mainAxisSpacing: 8,
//           crossAxisSpacing: 8,
//           children: [
//             _buildGridItem(context, Icons.food_bank, 'Planım', () => _navigateToMeal(context)),
//             _buildGridItem(context, Icons.calendar_today, 'Geçmiş Randevularım',
//                     () => _navigateToPastAppointments(context)),
//             _buildGridItem(context, Icons.payments, 'Ödemelerim',
//                     () => _navigateToPayments(context)),
//             _buildGridItem(context, Icons.timeline, 'Admin Timeslots',
//                     () => _navigateToAdminTimeSlots(context)),
//             _buildGridItem(context, Icons.event, 'Randevu',
//                     () => _navigateToAppointments(context)),
//             _buildGridItem(context, Icons.lock, 'Şifre Sıfırla',
//                     () => _navigateToResetPassword(context)),
//             _buildGridItem(context, Icons.assignment, 'Admin Appointments',
//                     () => _navigateToAdminAppointments(context)),
//             _buildGridItem(context, Icons.image, 'Admin Images',
//                     () => _navigateToAdminImages(context)),
//             _buildGridItem(context, Icons.list, 'Admin Liste',
//                     () => _navigateToFileHandler(context)),
//             _buildGridItem(context, Icons.person_add, 'Admin Kullanıcı Oluştur',
//                     () => _navigateToCreateUser(context)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGridItem(
//       BuildContext context, IconData icon, String label, VoidCallback onTap) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 40),
//             const SizedBox(height: 8),
//             Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _navigateToMeal(BuildContext context) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     final subscriptionId = await getCurrentSubscriptionId(userId);
//     if (subscriptionId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MealUploadPage(
//           userId: userId,
//           subscriptionId: subscriptionId,
//         ),
//       ),
//     );
//   }
//
//   void _navigateToPastAppointments(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PastAppointmentsPage(userId: userId),
//       ),
//     );
//   }
//
//   void _navigateToPayments(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => UserPaymentsPage(userId: userId),
//       ),
//     );
//   }
//
//   void _navigateToAdminTimeSlots(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminTimeSlotsPage(),
//       ),
//     );
//   }
//
//   Future<void> _navigateToAppointments(BuildContext context) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     final subscriptionId = await getCurrentSubscriptionId(userId);
//     if (subscriptionId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AppointmentsPage(
//           userId: userId,
//           subscriptionId: subscriptionId,
//         ),
//       ),
//     );
//   }
//
//   void _navigateToResetPassword(BuildContext context) {
//     final email = FirebaseAuth.instance.currentUser?.email ?? '';
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ResetPasswordPage(email: email),
//       ),
//     );
//   }
//
//   void _navigateToAdminAppointments(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminAppointmentsPage(),
//       ),
//     );
//   }
//
//   void _navigateToAdminImages(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminImages(),
//       ),
//     );
//   }
//
//   void _navigateToFileHandler(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const FileHandlerPage(),
//       ),
//     );
//   }
//
//   void _navigateToCreateUser(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const CreateUserPage(),
//       ),
//     );
//   }
//
//   void _showErrorDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Hata'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Tamam'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
//
// import '../models/logger.dart';
// import '../models/meal_model.dart';
// import '../providers/image_manager.dart';
//
// final Logger logger = Logger.forClass(MealUploadPage);
//
// class MealUploadPage extends StatefulWidget {
//   final String userId;
//   final String subscriptionId;
//
//   const MealUploadPage({
//     super.key,
//     required this.userId,
//     required this.subscriptionId,
//   });
//
//   static String formatTimeOfDay24(TimeOfDay time) {
//     final now = DateTime.now();
//     final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
//     return DateFormat('HH:mm').format(dateTime);
//   }
//   @override
//   State<MealUploadPage> createState() => _MealUploadPageState();
// }
//
// class _MealUploadPageState extends State<MealUploadPage> {
//   Map<Meals, bool> checkedStates = {
//     for (var meal in Meals.values) meal: false,
//   };
//
//   Map<Meals, List<String>> mealContents = {};
//   Map<Meals, TimeOfDay> mealTimes = {
//     for (var meal in Meals.values) meal: const TimeOfDay(hour: 0, minute: 0),
//   };
//   bool _isUploading = false;
//
//   late Future<void> _mealContentsFuture;
//   final String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
//   double _waterIntakeLiters = 0.0; // Water intake in liters
//   final TextEditingController _stepsController = TextEditingController();
//   bool _isSavingWater = false;
//   bool _isSavingSteps = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _mealContentsFuture = _fetchMealStatesAndContents();
//   }
//
//
//   Future<void> _fetchMealStatesAndContents() async {
//     try {
//       // Fetch meal contents (subtitles)
//       final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('dietlists')
//           .orderBy('uploadTime', descending: true)
//           .limit(1)
//           .get();
//       Map<Meals, List<String>> mealContentsTemp = {};
//       Map<Meals, TimeOfDay> mealTimesTemp = {};
//       if (querySnapshot.docs.isNotEmpty) {
//         final latestDoc = querySnapshot.docs.first;
//         final data = latestDoc.data() as Map<String, dynamic>;
//         if (data['subtitles'] != null) {
//           for (var subtitle in (data['subtitles'] as List<dynamic>)) {
//             final meal = Meals.fromName(subtitle['name']);
//             if (meal != null) {
//               final contentList = List<String>.from(
//                 subtitle['content'].map((item) => item['content'].toString()),
//               );
//               mealContentsTemp[meal] = contentList;
//
//               // Extract 'time', parse it into TimeOfDay
//               String? timeString = subtitle['time'];
//               TimeOfDay timeOfDay = const TimeOfDay(hour: 0, minute: 0);
//               if (timeString != null && timeString.isNotEmpty) {
//                 try {
//                   final parsedTime = DateFormat('HH:mm').parse(timeString);
//                   timeOfDay = TimeOfDay.fromDateTime(parsedTime);
//                 } catch (e) {
//                   logger.err('Error when parsing the time of dietlist:{}',
//                       [e.toString()]);
//                 }
//               }
//               mealTimesTemp[meal] = timeOfDay;
//             } else {
//               logger.warn('Skipping unmatched meal: {}', [subtitle['name']]);
//             }
//           }
//         }
//       } else {
//         logger.warn('No diet lists found for the user.');
//       }
//       setState(() {
//         mealContents = mealContentsTemp;
//         mealTimes = mealTimesTemp;
//       });
//       final mealStateDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('meals')
//           .doc(_currentDate)
//           .get();
//       if (mealStateDoc.exists) {
//         final data = mealStateDoc.data();
//         if (data != null && data['meals'] != null) {
//           final fetchedStates = (data['meals'] as Map<String, dynamic>).map(
//             (key, value) => MapEntry(Meals.fromName(key)!, value as bool),
//           );
//           setState(() {
//
//             for (var meal in fetchedStates.keys) {
//               checkedStates[meal] = fetchedStates[meal]!;
//             }
//           });
//         }
//       }
//       else {
//         logger.warn(
//             'No mealStateDoc found for date $_currentDate, initializing defaults.');
//       }
//
//       final dailyDataDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('dailyData')
//           .doc(_currentDate)
//           .get();
//
//       if (dailyDataDoc.exists) {
//         final data = dailyDataDoc.data();
//         if (data != null) {
//           setState(() {
//             if (data['steps'] != null) {
//               _stepsController.text = data['steps'].toString();
//             }
//             if (data['waterIntake'] != null) {
//               _waterIntakeLiters = (data['waterIntake'] as num).toDouble();
//             }
//           });
//         }
//       } else {
//         logger.info(
//             'No daily data found for date $_currentDate, initializing defaults.');
//       }
//     } catch (e) {
//       logger.err('Error fetching meal states or contents: {}', [e.toString()]);
//     }
//   }
//
//   Future<void> _updateMealState(Meals meal, bool state) async {
//     try {
//       final docRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('meals')
//           .doc(_currentDate);
//
//       await docRef.set({
//         'meals': {
//           meal.label: state,
//         },
//       }, SetOptions(merge: true));
//
//       logger.info('Updated state for {} to {}', [meal.label, state]);
//     } catch (e) {
//       logger.err('Error updating meal state: {}', [e.toString()]);
//     }
//   }
//
//   Future<void> _uploadMealImage(Meals mealCategory) async {
//     final ImagePicker picker = ImagePicker();
//     final imageManager = ImageManager();
//
//     final XFile? image = await picker.pickImage(
//       source: ImageSource.gallery,
//     );
//     if (image != null) {
//       setState(() {
//         _isUploading = true;
//       });
//
//       // Delete previous image if exists
//       await _deletePreviousImage(mealCategory);
//
//       final result = await imageManager.uploadFile(
//         image,
//         meal: mealCategory,
//         userId: widget.userId,
//       );
//
//       if (!mounted) return;
//
//       setState(() {
//         _isUploading = false;
//       });
//
//       if (result.isUploadOk && result.downloadUrl != null) {
//         // Save the meal image information to Firestore
//         final mealDocRef = FirebaseFirestore.instance
//             .collection('users')
//             .doc(widget.userId)
//             .collection('meals')
//             .doc(_currentDate)
//             .collection('mealEntries')
//             .doc(mealCategory.name); // Use mealCategory.name as document ID
//
//         MealModel mealModel = MealModel(
//           mealId: mealDocRef.id,
//           mealType: mealCategory,
//           imageUrl: result.downloadUrl!,
//           subscriptionId: widget.subscriptionId,
//           timestamp: DateTime.now(),
//           description: null,
//           calories: null,
//           notes: null,
//           isChecked: true, // Meal is considered checked upon upload
//         );
//
//         await mealDocRef.set(mealModel.toMap());
//
//         // Update meal checked state
//         setState(() {
//           checkedStates[mealCategory] = true;
//         });
//
//         // Update meal state in the main document
//         await _updateMealState(mealCategory, true);
//
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Photo uploaded successfully.')),
//         );
//       } else if (result.errorMessage != null) {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(result.errorMessage!)),
//         );
//       }
//     }
//   }
//
//   Future<void> _deletePreviousImage(Meals mealCategory) async {
//     try {
//       // Get the meal document
//       final mealDocRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('meals')
//           .doc(_currentDate)
//           .collection('mealEntries')
//           .doc(mealCategory.name); // Use mealCategory.name as document ID
//
//       final mealDoc = await mealDocRef.get();
//
//       if (mealDoc.exists) {
//         final mealModel = MealModel.fromDocument(mealDoc);
//
//         // Delete the image from Firebase Storage
//         final imageManager = ImageManager();
//         await imageManager.deleteFile(
//           mealModel.imageUrl,
//         );
//
//         // Delete the meal document from Firestore
//         await mealDocRef.delete();
//       }
//     } catch (e) {
//       logger.err('Error deleting previous image: {}', [e.toString()]);
//     }
//   }
//   Future<void> _saveWaterIntake() async {
//     setState(() {
//       _isSavingWater = true;
//     });
//
//     try {
//       final docRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('dailyData')
//           .doc(_currentDate);
//
//       await docRef.set({
//         'waterIntake': _waterIntakeLiters,
//       }, SetOptions(merge: true));
//
//       logger.info('Water intake updated to {} liters', [_waterIntakeLiters]);
//     } catch (e) {
//       logger.err('Error saving water intake: {}', [e.toString()]);
//     } finally {
//       setState(() {
//         _isSavingWater = false;
//       });
//     }
//   }
//
//   Future<void> _saveSteps() async {
//     try {
//       int? steps = int.tryParse(_stepsController.text) ;
//       if (steps == null) {
//         if (!context.mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text(
//                   'Girilen sayı geçerli değildir. Lütfen sayıyı kontrol edip tekrar giriniz.')),
//         );
//         return;
//       }
//
//       setState(() {
//         _isSavingSteps = true;
//       });
//       final docRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('dailyData')
//           .doc(_currentDate);
//
//       await docRef.set({
//         'steps': steps,
//       }, SetOptions(merge: true));
//
//       logger.info('Steps updated to {}', [steps]);
//     } catch (e) {
//       logger.err('Error saving steps: {}', [e.toString()]);
//     } finally {
//       setState(() {
//         _isSavingSteps = false;
//       });
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     logger.info('Building MealUploadPage');
//     const defaultMealTime = TimeOfDay(hour: 0, minute: 0);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Günlüğüm'),
//         backgroundColor: Colors.lightBlue,
//       ),
//       body: Stack(
//         children: [
//           FutureBuilder<void>(
//             future: _mealContentsFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               } else if (snapshot.hasError) {
//                 logger.err('Error in FutureBuilder: {}', [snapshot.error ?? 'snapshot error']);
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               } else {
//                 return SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       children: [
//                         // Water Intake and Steps Sections in a Row
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Card(
//                                 elevation: 4,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child: Column(
//                                     children: [
//                                       const Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           Icon(Icons.local_drink, color: Colors.blue, size: 30),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'Su Tüketimi',
//                                             style: TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.blue,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 16),
//                                       // Display today's water intake
//                                       Text(
//                                         'Bugün: ${_waterIntakeLiters.toStringAsFixed(2)} Litre',
//                                         style: const TextStyle(fontSize: 20),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Slider(
//                                         value: _waterIntakeLiters,
//                                         min: 0,
//                                         max: 5,
//                                         divisions: 20,
//                                         label: '${_waterIntakeLiters.toStringAsFixed(2)} L',
//                                         onChanged: (value) {
//                                           setState(() {
//                                             _waterIntakeLiters = value;
//                                           });
//                                         },
//                                         activeColor: Colors.blue,
//                                         inactiveColor: Colors.blue[100],
//                                       ),
//                                       const SizedBox(height: 8),
//                                       ElevatedButton(
//                                         onPressed: _isSavingWater ? null : _saveWaterIntake,
//                                         style: ElevatedButton.styleFrom(
//                                           foregroundColor: Colors.white,
//                                           backgroundColor: Colors.blue,
//                                         ),
//                                         child: _isSavingWater
//                                             ? const CircularProgressIndicator(
//                                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                         )
//                                             : const Text('Kaydet'),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Card(
//                                 elevation: 4,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child: Column(
//                                     children: [
//                                       const Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           Icon(Icons.directions_walk, color: Colors.green, size: 30),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'Adım Sayısı',
//                                             style: TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.green,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 16),
//                                       // Display today's steps
//                                       Text(
//                                         'Bugün: ${_stepsController.text.isNotEmpty ? _stepsController.text : '0'}',
//                                         style: const TextStyle(fontSize: 20),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       TextField(
//                                         controller: _stepsController,
//                                         keyboardType: TextInputType.number,
//                                         decoration: const InputDecoration(
//                                           labelText: 'Adım sayısını giriniz',
//                                           border: OutlineInputBorder(),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       ElevatedButton(
//                                         onPressed: _isSavingSteps ? null : _saveSteps,
//                                         style: ElevatedButton.styleFrom(
//                                           foregroundColor: Colors.white,
//                                           backgroundColor: Colors.green,
//                                         ),
//                                         child: _isSavingSteps
//                                             ? const CircularProgressIndicator(
//                                           valueColor:
//                                           AlwaysStoppedAnimation<Color>(Colors.white),
//                                         )
//                                             : const Text('Kaydet'),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         // Meals Section
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: Meals.values.length,
//                           itemBuilder: (context, index) {
//                             final mealCategory = Meals.values[index];
//                             final contents = mealContents[mealCategory] ?? [];
//
//                             return Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ListTile(
//                                   title: Text(
//                                     mealCategory.label,
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.deepOrange,
//                                     ),
//                                   ),
//                                   subtitle: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: contents
//                                         .map((content) => Text('- $content'))
//                                         .toList(),
//                                   ),
//                                   trailing: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Text(
//                                         MealUploadPage.formatTimeOfDay24(mealTimes[mealCategory] ?? defaultMealTime),
//                                         textAlign: TextAlign.left,
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(Icons.camera_alt),
//                                         color: Colors.blue,
//                                         onPressed: () async {
//                                           await _uploadMealImage(mealCategory);
//                                         },
//                                       ),
//                                       Checkbox(
//                                         value: checkedStates[mealCategory],
//                                         onChanged: (bool? newValue) async {
//                                           setState(() {
//                                             checkedStates[mealCategory] =
//                                                 newValue ?? false;
//                                           });
//
//                                           // Update the meal state in Firestore
//                                           await _updateMealState(
//                                               mealCategory, newValue ?? false);
//                                         },
//                                         activeColor: Colors.deepOrange,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 const Divider(),
//                               ],
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }
//             },
//           ),
//           if (_isUploading)
//             const Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
// }import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../models/logger.dart';
// import '../pages/login_page.dart';
//
// final Logger logger = Logger.forClass(ResetPasswordPage);
//
// class ResetPasswordPage extends StatefulWidget {
//   final String email;
//
//   const ResetPasswordPage({super.key, required this.email});
//
//   @override
//   createState() => _ResetPasswordPageState();
// }
//
// class _ResetPasswordPageState extends State<ResetPasswordPage> {
//   late TextEditingController _emailController;
//   bool _isLoading = false;
//   String _errorMessage = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _emailController = TextEditingController(text: widget.email);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Şifre Sıfırlama'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             TextField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: const InputDecoration(
//                 hintText: 'Emailinizi giriniz',
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _sendPasswordResetEmail,
//               child: _isLoading
//                   ? const CircularProgressIndicator()
//                   : const Text('Şifre Sıfırlama Linki Gönder'),
//             ),
//             if (_errorMessage.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 20),
//                 child: Text(
//                   _errorMessage,
//                   style: const TextStyle(color: Colors.red, fontSize: 16),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _sendPasswordResetEmail() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
//
//     String email = _emailController.text;
//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       logger.info('Sent password reset email to: {}', [email]);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Şifre sıfırlama linki gönderildi!')),
//         );
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginPage()),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       logger.err('Error sending password reset email to {}: {}', [email, e.message!]);
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Bir hata oluştu. Lütfen girdiğiniz email adresini kontrol ediniz.';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../models/appointment_model.dart';
// import '../models/logger.dart';
//
// final Logger logger = Logger.forClass(PastAppointmentsPage);
//
// class PastAppointmentsPage extends StatefulWidget {
//   final String userId;
//
//   const PastAppointmentsPage({Key? key, required this.userId}) : super(key: key);
//
//   @override
//   createState() => _PastAppointmentsPageState();
// }
//
// class _PastAppointmentsPageState extends State<PastAppointmentsPage> {
//   static const int _pageSize = 5; // Number of items per page
//   int _currentPage = 1; // Current page index
//   int _totalPages = 1; // Total number of pages
//   List<AppointmentModel> _allAppointments = []; // All fetched appointments
//   List<AppointmentModel> _filteredAppointments = []; // Filtered appointments
//   List<AppointmentModel> _currentAppointments = []; // Appointments for the current page
//   bool _isLoading = false;
//
//   // Filters
//   AppointmentStatus? _selectedStatus;
//   DateTimeRange? _selectedDateRange;
//   bool _isDateAscending = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAllAppointments();
//   }
//
//   /// Fetch all past appointments and initialize pagination.
//   Future<void> _fetchAllAppointments() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       logger.info('Fetching all past appointments for user ${widget.userId}...');
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('appointments')
//           .where('appointmentDateTime', isLessThan: Timestamp.now()) // Past appointments only
//           .orderBy('appointmentDateTime', descending: true)
//           .get();
//
//       _allAppointments = snapshot.docs
//           .map((doc) => AppointmentModel.fromDocument(doc))
//           .toList();
//
//       _applyFilters();
//
//     } catch (e) {
//       logger.err('Error fetching all past appointments: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Randevular alınırken hata oluştu: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   /// Apply filters and sorting to the appointments list.
//   void _applyFilters() {
//     List<AppointmentModel> filtered = List.from(_allAppointments);
//
//     // Apply status filter
//     if (_selectedStatus != null) {
//       filtered = filtered.where((appointment) => appointment.status == _selectedStatus).toList();
//     }
//
//     // Apply date filter
//     if (_selectedDateRange != null) {
//       filtered = filtered.where((appointment) {
//         DateTime date = appointment.appointmentDateTime;
//         return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
//             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
//       }).toList();
//     }
//
//     // Apply sorting
//     filtered.sort((a, b) {
//       if (_isDateAscending) {
//         return a.appointmentDateTime.compareTo(b.appointmentDateTime);
//       } else {
//         return b.appointmentDateTime.compareTo(a.appointmentDateTime);
//       }
//     });
//
//     setState(() {
//       _filteredAppointments = filtered;
//       _totalPages = (_filteredAppointments.length / _pageSize).ceil();
//       if (_totalPages == 0) _totalPages = 1;
//       _currentPage = 1; // Reset to first page
//       _setCurrentPageAppointments();
//     });
//   }
//
//   /// Set the appointments for the current page by slicing the _filteredAppointments list.
//   void _setCurrentPageAppointments() {
//     setState(() {
//       int startIndex = (_currentPage - 1) * _pageSize;
//       int endIndex = startIndex + _pageSize;
//       if (endIndex > _filteredAppointments.length) {
//         endIndex = _filteredAppointments.length;
//       }
//       _currentAppointments = _filteredAppointments.sublist(startIndex, endIndex);
//       logger.info('Displaying appointments for page $_currentPage: $_currentAppointments');
//     });
//   }
//
//   /// Handle page changes by updating _currentPage and setting the current appointments.
//   void _changePage(int page) {
//     if (page != _currentPage && page >= 1 && page <= _totalPages) {
//       logger.info('Switching to page $page...');
//       setState(() {
//         _currentPage = page;
//       });
//       _setCurrentPageAppointments();
//     }
//   }
//
//   Future<void> _selectDateRange() async {
//     DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       initialDateRange: _selectedDateRange ??
//           DateTimeRange(
//             start: DateTime.now().subtract(const Duration(days: 30)),
//             end: DateTime.now(),
//           ),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//       locale: const Locale('tr', 'TR'),
//     );
//
//     if (picked != null && picked != _selectedDateRange) {
//       setState(() {
//         _selectedDateRange = picked;
//       });
//       _applyFilters();
//     }
//   }
//
//   void _clearFilters() {
//     setState(() {
//       _selectedStatus = null;
//       _selectedDateRange = null;
//       _isDateAscending = true;
//     });
//     _applyFilters();
//   }
//
//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         AppointmentStatus? tempStatus = _selectedStatus;
//         DateTimeRange? tempDateRange = _selectedDateRange;
//
//         return AlertDialog(
//           title: const Text('Filtrele'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DropdownButtonFormField<AppointmentStatus>(
//                   value: tempStatus,
//                   decoration: const InputDecoration(
//                     labelText: 'Durum',
//                   ),
//                   items: AppointmentStatus.values.map((AppointmentStatus status) {
//                     return DropdownMenuItem<AppointmentStatus>(
//                       value: status,
//                       child: Text(status.label),
//                     );
//                   }).toList(),
//                   onChanged: (AppointmentStatus? newValue) {
//                     tempStatus = newValue;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextButton(
//                   onPressed: () async {
//                     DateTimeRange? picked = await showDateRangePicker(
//                       context: context,
//                       initialDateRange: tempDateRange ??
//                           DateTimeRange(
//                             start: DateTime.now().subtract(const Duration(days: 30)),
//                             end: DateTime.now(),
//                           ),
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime.now(),
//                       locale: const Locale('tr', 'TR'),
//                     );
//                     if (picked != null) {
//                       setState(() {
//                         tempDateRange = picked;
//                       });
//                     }
//                   },
//                   child: Text(
//                     tempDateRange == null
//                         ? 'Tarih Seçiniz'
//                         : 'Seçilen Tarih: ${DateFormat('dd.MM.yyyy').format(tempDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(tempDateRange!.end)}',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('İptal'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Uygula'),
//               onPressed: () {
//                 setState(() {
//                   _selectedStatus = tempStatus;
//                   _selectedDateRange = tempDateRange;
//                 });
//                 _applyFilters();
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _toggleDateSorting() {
//     setState(() {
//       _isDateAscending = !_isDateAscending;
//       _applyFilters();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Geçmiş Randevularım'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_alt),
//             onPressed: _showFilterDialog,
//           ),
//           IconButton(
//             icon: Icon(_isDateAscending ? Icons.arrow_downward : Icons.arrow_upward),
//             onPressed: _toggleDateSorting,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_selectedStatus != null || _selectedDateRange != null)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   if (_selectedStatus != null)
//                     Chip(
//                       label: Text('Durum: ${_selectedStatus!.label}'),
//                       onDeleted: () {
//                         setState(() {
//                           _selectedStatus = null;
//                         });
//                         _applyFilters();
//                       },
//                     ),
//                   if (_selectedDateRange != null)
//                     Chip(
//                       label: Text(
//                           'Tarih: ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}'),
//                       onDeleted: () {
//                         setState(() {
//                           _selectedDateRange = null;
//                         });
//                         _applyFilters();
//                       },
//                     ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: _clearFilters,
//                     child: const Text('Filtreleri Temizle'),
//                   ),
//                 ],
//               ),
//             ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _filteredAppointments.isEmpty
//                 ? const Center(child: Text('Geçmiş randevunuz bulunmamaktadır.'))
//                 : ListView.builder(
//               itemCount: _currentAppointments.length,
//               itemBuilder: (context, index) {
//                 final appointment = _currentAppointments[index];
//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: Icon(
//                         Icons.calendar_today,
//                         color: theme.primaryColor,
//                         size: 40,
//                       ),
//                       title: Text(
//                         DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR')
//                             .format(appointment.appointmentDateTime),
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 5),
//                           Text(
//                             'Durum: ${appointment.status.label}',
//                             style: const TextStyle(
//                               fontSize: 14,
//                             ),
//                           ),
//                           Text(
//                             'Görüşme Türü: ${appointment.meetingType.label}',
//                             style: const TextStyle(
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                       trailing: Icon(
//                         Icons.arrow_forward_ios,
//                         color: theme.primaryColor,
//                       ),
//                       onTap: () {
//                         // Handle tap if needed
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (_totalPages > 1)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: PaginationControls(
//                 currentPage: _currentPage,
//                 totalPages: _totalPages,
//                 onPageChanged: _changePage,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// class PaginationControls extends StatelessWidget {
//   final int currentPage;
//   final int totalPages;
//   final Function(int) onPageChanged;
//
//   const PaginationControls({
//     Key? key,
//     required this.currentPage,
//     required this.totalPages,
//     required this.onPageChanged,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         IconButton(
//           onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
//           icon: const Icon(Icons.arrow_back_ios),
//           color: theme.primaryColor,
//         ),
//         Text(
//           '$currentPage / $totalPages',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         IconButton(
//           onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
//           icon: const Icon(Icons.arrow_forward_ios),
//           color: theme.primaryColor,
//         ),
//       ],
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../providers/payment_provider.dart';
// import '../models/payment_model.dart';
// import '../models/logger.dart';
//
// final Logger logger = Logger.forClass(UserPaymentsPage);
//
// class UserPaymentsPage extends StatefulWidget {
//   final String userId;
//
//   const UserPaymentsPage({Key? key, required this.userId}) : super(key: key);
//
//   @override
//   createState() => _UserPaymentsPageState();
// }
//
// class _UserPaymentsPageState extends State<UserPaymentsPage> {
//   late Future<List<PaymentModel>> _paymentsFuture;
//   List<PaymentModel> _allPayments = [];
//   List<PaymentModel> _filteredPayments = [];
//   bool _isLoading = false;
//
//   // Filters
//   PaymentStatus? _selectedStatus;
//   DateTimeRange? _selectedDateRange;
//   bool _isDateAscending = true;
//
//   @override
//   void initState() {
//     super.initState();
//     logger.info('Initializing UserPaymentsPage state.');
//     _fetchUserPayments();
//   }
//
//   void _fetchUserPayments() {
//     setState(() {
//       _isLoading = true;
//     });
//     final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
//     paymentProvider.setUserId(widget.userId);
//     paymentProvider.fetchPayments(showAllPayments: true).then((payments) {
//       setState(() {
//         _allPayments = payments;
//         _applyFilters();
//         _isLoading = false;
//       });
//       logger.info('Fetched ${payments.length} payments for user ${widget.userId}.');
//     }).catchError((error, stackTrace) {
//       logger.err('Error fetching payments: {}', [error]);
//       logger.err('Stack trace: {}', [stackTrace]);
//       setState(() {
//         _isLoading = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Ödemeler alınırken bir hata oluştu.')),
//         );
//       }
//     });
//   }
//
//   void _applyFilters() {
//     List<PaymentModel> filtered = List.from(_allPayments);
//
//     // Apply status filter
//     if (_selectedStatus != null) {
//       filtered = filtered.where((payment) => payment.status == _selectedStatus).toList();
//     }
//
//     // Apply date filter
//     if (_selectedDateRange != null) {
//       filtered = filtered.where((payment) {
//         DateTime? date = payment.dueDate;
//         if (date == null) return false;
//         return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
//             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
//       }).toList();
//     }
//
//     // Apply sorting
//     filtered.sort((a, b) {
//       DateTime dateA = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
//       DateTime dateB = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
//       if (_isDateAscending) {
//         return dateA.compareTo(dateB);
//       } else {
//         return dateB.compareTo(dateA);
//       }
//     });
//
//     setState(() {
//       _filteredPayments = filtered;
//     });
//     logger.info('Applied filters. Total payments after filtering: ${_filteredPayments.length}.');
//   }
//
//   void _clearFilters() {
//     setState(() {
//       _selectedStatus = null;
//       _selectedDateRange = null;
//       _isDateAscending = true;
//     });
//     _applyFilters();
//     logger.info('Cleared all filters.');
//   }
//
//   void _showFilterDialog() {
//     PaymentStatus? tempStatus = _selectedStatus;
//     DateTimeRange? tempDateRange = _selectedDateRange;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Filtrele'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DropdownButtonFormField<PaymentStatus>(
//                   value: tempStatus,
//                   decoration: const InputDecoration(
//                     labelText: 'Durum',
//                   ),
//                   items: PaymentStatus.values.map((PaymentStatus status) {
//                     return DropdownMenuItem<PaymentStatus>(
//                       value: status,
//                       child: Text(status.label),
//                     );
//                   }).toList(),
//                   onChanged: (PaymentStatus? newValue) {
//                     tempStatus = newValue;
//                   },
//                 ),
//                 const SizedBox(height: 20),
//                 TextButton(
//                   onPressed: () async {
//                     DateTimeRange? picked = await showDateRangePicker(
//                       context: context,
//                       initialDateRange: tempDateRange ??
//                           DateTimeRange(
//                             start: DateTime.now().subtract(const Duration(days: 30)),
//                             end: DateTime.now(),
//                           ),
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime.now(),
//                       locale: const Locale('tr', 'TR'),
//                     );
//                     if (picked != null) {
//                       setState(() {
//                         tempDateRange = picked;
//                       });
//                     }
//                   },
//                   child: Text(
//                     tempDateRange == null
//                         ? 'Tarih Seçiniz'
//                         : 'Seçilen Tarih: ${DateFormat('dd.MM.yyyy').format(tempDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(tempDateRange!.end)}',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('İptal'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Uygula'),
//               onPressed: () {
//                 setState(() {
//                   _selectedStatus = tempStatus;
//                   _selectedDateRange = tempDateRange;
//                 });
//                 _applyFilters();
//                 Navigator.of(context).pop();
//                 logger.info('Applied new filters.');
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _toggleDateSorting() {
//     setState(() {
//       _isDateAscending = !_isDateAscending;
//     });
//     _applyFilters();
//     logger.info('Toggled date sorting. Now ascending: $_isDateAscending.');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     logger.info('Building UserPaymentsPage UI.');
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ödemelerim'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_alt),
//             onPressed: _showFilterDialog,
//           ),
//           IconButton(
//             icon: Icon(_isDateAscending ? Icons.arrow_downward : Icons.arrow_upward),
//             onPressed: _toggleDateSorting,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_selectedStatus != null || _selectedDateRange != null)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   if (_selectedStatus != null)
//                     Chip(
//                       label: Text('Durum: ${_selectedStatus!.label}'),
//                       onDeleted: () {
//                         setState(() {
//                           _selectedStatus = null;
//                         });
//                         _applyFilters();
//                         logger.info('Removed status filter.');
//                       },
//                     ),
//                   if (_selectedDateRange != null)
//                     Chip(
//                       label: Text(
//                           'Tarih: ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}'),
//                       onDeleted: () {
//                         setState(() {
//                           _selectedDateRange = null;
//                         });
//                         _applyFilters();
//                         logger.info('Removed date range filter.');
//                       },
//                     ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: _clearFilters,
//                     child: const Text('Filtreleri Temizle'),
//                   ),
//                 ],
//               ),
//             ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _filteredPayments.isEmpty
//                 ? const Center(
//               child: Text(
//                 'Henüz bir ödemeniz bulunmuyor.',
//                 style: TextStyle(fontSize: 18),
//               ),
//             )
//                 : ListView.builder(
//               itemCount: _filteredPayments.length,
//               itemBuilder: (context, index) {
//                 PaymentModel payment = _filteredPayments[index];
//                 Color statusColor;
//                 if (payment.status == PaymentStatus.completed) {
//                   statusColor = Colors.green;
//                 } else if (payment.status == PaymentStatus.planned) {
//                   statusColor = Colors.orange;
//                 } else {
//                   statusColor = Colors.red;
//                 }
//
//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: Icon(
//                         Icons.payment,
//                         color: theme.primaryColor,
//                         size: 40,
//                       ),
//                       title: Text(
//                         'Miktar: ${payment.amount.toStringAsFixed(2)} ₺',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 5),
//                           Text(
//                             'Planlanan Ödeme Tarihi: ${_formatDate(payment.dueDate)}',
//                           ),
//                           Text(
//                             'Ödendiği Tarih: ${_formatDate(payment.paymentDate)}',
//                           ),
//                         ],
//                       ),
//                       trailing: Text(
//                         payment.status.label,
//                         style: TextStyle(
//                           color: statusColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       onTap: () {
//                         // Handle tap if needed
//                        // logger.info('Payment item tapped: ${payment.paymentId}');
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDate(DateTime? date) {
//     if (date == null) return '-';
//     return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
//   }
// }
