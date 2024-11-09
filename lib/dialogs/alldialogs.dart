// // dialogs/add_appointment_dialog.dart
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/appointment_model.dart';
// import '../providers/appointment_manager.dart';
//
// class AddAppointmentDialog extends StatefulWidget {
//   final String userId;
//   final String subscriptionId;
//   final VoidCallback onAppointmentAdded;
//
//   const AddAppointmentDialog({
//     super.key,
//     required this.userId,
//     required this.subscriptionId,
//     required this.onAppointmentAdded,
//   });
//
//   @override
//   createState() => _AddAppointmentDialogState();
// }
//
// class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
//   DateTime _selectedDate = DateTime.now();
//   TimeOfDay? _selectedTime;
//   MeetingType _meetingType = MeetingType.f2f;
//
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Appointment'),
//       content: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Date Picker
//             ListTile(
//               title: const Text('Select Date'),
//               subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0]),
//               trailing: IconButton(
//                 icon: const Icon(Icons.calendar_today),
//                 onPressed: _pickDate,
//               ),
//             ),
//             // Time Picker
//             ListTile(
//               title: const Text('Select Time'),
//               subtitle: Text(_selectedTime != null
//                   ? _selectedTime!.format(context)
//                   : 'No time selected'),
//               trailing: IconButton(
//                 icon: const Icon(Icons.access_time),
//                 onPressed: _pickTime,
//               ),
//             ),
//             // Meeting Type
//             DropdownButton<MeetingType>(
//               value: _meetingType,
//               onChanged: (MeetingType? newValue) {
//                 if (newValue != null) {
//                   setState(() {
//                     _meetingType = newValue;
//                   });
//                 }
//               },
//               items: MeetingType.values.map((MeetingType type) {
//                 return DropdownMenuItem<MeetingType>(
//                   value: type,
//                   child: Text(type.label),
//                 );
//               }).toList(),
//             ),
//             if (_errorMessage != null)
//               Text(
//                 _errorMessage!,
//                 style: const TextStyle(color: Colors.red),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : _addAppointment, //TODO test setstate ve return err msglar
//           child: _isLoading
//               ? const SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           )
//               : const Text('Add'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime(DateTime.now().year + 1),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }
//
//   Future<void> _pickTime() async {
//     TimeOfDay? picked =
//     await showTimePicker(context: context, initialTime: TimeOfDay.now());
//     if (picked != null && picked != _selectedTime) {
//       setState(() {
//         _selectedTime = picked;
//       });
//     }
//   }
//
//   Future<void> _addAppointment() async {
//     if (_selectedTime == null) {
//       setState(() {
//         _errorMessage = 'Please select a time.';
//       });
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final appointmentManager =
//       Provider.of<AppointmentManager>(context, listen: false);
//
//       DateTime appointmentDateTime = DateTime(
//         _selectedDate.year,
//         _selectedDate.month,
//         _selectedDate.day,
//         _selectedTime!.hour,
//         _selectedTime!.minute,
//       );
//
//       bool isAvailable = appointmentManager.isTimeSlotAvailable(
//           _selectedDate, _selectedTime!);
//
//       if (!isAvailable) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Selected time slot is not available.')),
//         );
//         setState(() {
//           _errorMessage = 'Selected time slot is not available.';
//         });
//         return;
//       }
//
//       AppointmentModel newAppointment = AppointmentModel(
//         appointmentId: FirebaseFirestore.instance
//             .collection('users')
//             .doc(widget.userId)
//             .collection('appointments')
//             .doc()
//             .id,
//         userId: widget.userId,
//         subscriptionId: widget.subscriptionId,
//         meetingType: _meetingType,
//         appointmentDateTime: appointmentDateTime,
//         status: MeetingStatus.scheduled,
//         createdAt: DateTime.now(),
//         createdBy: 'admin',
//       );
//
//       await appointmentManager.addAppointment(newAppointment);
//       widget.onAppointmentAdded();
//
//       if (!mounted) return;
//       Navigator.of(context).pop();
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }
// // dialogs/add_image_dialog.dart
//
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import '../models/logger.dart';
// import '../models/meal_model.dart';
// import '../providers/image_manager.dart';
// import '../providers/meal_state_and_upload_manager.dart';
//
// class AddImageDialog extends StatefulWidget {
//   final String userId;
//   final String subscriptionId;
//   final VoidCallback onImageAdded;
//
//   const AddImageDialog({
//     super.key,
//     required this.userId,
//     required this.subscriptionId,
//     required this.onImageAdded,
//   });
//
//   @override
//   createState() => _AddImageDialogState();
// }
//
// class _AddImageDialogState extends State<AddImageDialog> {
//   final Logger logger = Logger.forClass(AddImageDialog);
//   final ImagePicker _picker = ImagePicker();
//   XFile? _selectedImage;
//   Meals? _selectedMeal;
//   bool _isUploading = false;
//   String? _errorMessage;
//
//   @override
//   Widget build(BuildContext context) {
//     const mealOptions = Meals.values;
//
//     return AlertDialog(
//       title: const Text('Add Meal Image'),
//       content: SingleChildScrollView(
//         child: Column(
//           children: [
//             DropdownButtonFormField<Meals>(
//               value: _selectedMeal,
//               hint: const Text('Select Meal Type'),
//               onChanged: (Meals? newValue) {
//                 setState(() {
//                   _selectedMeal = newValue;
//                 });
//               },
//               items: mealOptions.map((Meals meal) {
//                 return DropdownMenuItem<Meals>(
//                   value: meal,
//                   child: Text(meal.label),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _pickImage,
//               child: const Text('Select Image'),
//             ),
//             const SizedBox(height: 16),
//             _selectedImage != null
//                 ? Image.file(
//               File(_selectedImage!.path),
//               height: 100,
//             )
//                 : const Text('No image selected'),
//             if (_errorMessage != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 16),
//                 child: Text(
//                   _errorMessage!,
//                   style: const TextStyle(color: Colors.red),
//                 ),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isUploading ? null : _uploadImage,
//           child: _isUploading
//               ? const CircularProgressIndicator()
//               : const Text('Upload'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickImage() async {
//     try {
//       final pickedFile =
//       await _picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _selectedImage = pickedFile;
//         });
//       }
//     } catch (e) {
//       logger.err('Error picking image: $e');
//       setState(() {
//         _errorMessage = 'Error picking image.';
//       });
//     }
//   }
//
//   Future<void> _uploadImage() async {
//     if (_selectedMeal == null) {
//       setState(() {
//         _errorMessage = 'Please select a meal type.';
//       });
//       return;
//     }
//
//     if (_selectedImage == null) {
//       setState(() {
//         _errorMessage = 'Please select an image.';
//       });
//       return;
//     }
//
//     setState(() {
//       _isUploading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final imageManager = Provider.of<ImageManager>(context, listen: false);
//
//       final result = await imageManager.uploadFile(
//         File(_selectedImage!.path),
//         meal: _selectedMeal!,
//         userId: widget.userId,
//       );
//
//       if (result.isUploadOk && result.downloadUrl != null) {
//         // Save the meal image information to Firestore
//         final mealDocRef = FirebaseFirestore.instance
//             .collection('users')
//             .doc(widget.userId)
//             .collection('meals')
//             .doc(); // Generate a new meal ID
//
//         MealModel mealModel = MealModel(
//           mealId: mealDocRef.id,
//           mealType: _selectedMeal!,
//           imageUrl: result.downloadUrl!,
//           subscriptionId: widget.subscriptionId,
//           timestamp: DateTime.now(),
//           description: null,
//           calories: null,
//           notes: null,
//         );
//
//         await mealDocRef.set(mealModel.toMap());
//
//         // Update meal checked state
//         Provider.of<MealStateManager>(context, listen: false)
//             .setMealCheckedState(_selectedMeal!, true);
//
//         // Notify parent widget to refresh data
//         widget.onImageAdded();
//
//         if (!mounted) return;
//         Navigator.of(context).pop();
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Image uploaded successfully.')),
//         );
//       } else {
//         setState(() {
//           _errorMessage = result.errorMessage ?? 'Error uploading image.';
//         });
//       }
//     } catch (e) {
//       logger.err('Error uploading image: $e');
//       setState(() {
//         _errorMessage = 'Error uploading image.';
//       });
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }
// }
// // dialogs/add_payment_dialog.dart
//
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
//
// import '../models/logger.dart';
// import '../models/subs_model.dart';
// import '../providers/payment_provider.dart';
//
// class AddPaymentDialog extends StatefulWidget {
//   final String userId;
//   final Function onPaymentAdded;
//   final SubscriptionModel subscription;
//
//   const AddPaymentDialog({
//     Key? key,
//     required this.userId,
//     required this.onPaymentAdded,
//     required this.subscription,
//   }) : super(key: key);
//
//   @override
//   _AddPaymentDialogState createState() => _AddPaymentDialogState();
// }
//
// class _AddPaymentDialogState extends State<AddPaymentDialog> {
//   final Logger logger = Logger.forClass(AddPaymentDialog);
//
//   // Controllers and variables
//   final TextEditingController _amountController = TextEditingController();
//   DateTime? _selectedPaymentDate;
//   DateTime? _selectedDueDate;
//   String _paymentStatus = 'Pending';
//   File? _dekontImage;
//   final ImagePicker _picker = ImagePicker();
//   bool _isLoading = false;
//
//   // New variables for notifications
//   bool _enableNotifications = false;
//   final List<bool> _notificationOptions = [false, false, false, false];
//   final List<int> _notificationTimes = [72, 48, 24, 6]; // Hours before due date
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Payment'),
//       content: SingleChildScrollView(
//         child: ListBody(
//           children: [
//             TextField(
//               controller: _amountController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'Amount'),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               title: Text(_selectedDueDate == null
//                   ? 'Select Due Date (Optional)'
//                   : 'Due Date: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}'),
//               trailing: const Icon(Icons.calendar_today),
//               onTap: () async {
//                 DateTime? pickedDate = await showDatePicker(
//                   context: context,
//                   initialDate: _selectedDueDate ?? DateTime.now(),
//                   firstDate: DateTime.now(),
//                   lastDate: DateTime.now().add(const Duration(days: 365)),
//                 );
//                 if (pickedDate != null) {
//                   setState(() {
//                     _selectedDueDate = pickedDate;
//                     // If a due date is selected, clear the payment date
//                     _selectedPaymentDate = null;
//                   });
//                 }
//               },
//             ),
//             const SizedBox(height: 16),
//             if (_selectedDueDate == null) ...[
//               // Show payment date selection only if no due date is selected
//               ListTile(
//                 title: Text(_selectedPaymentDate == null
//                     ? 'Select Payment Date'
//                     : 'Payment Date: ${_selectedPaymentDate!.toLocal().toString().split(' ')[0]}'),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: () async {
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: _selectedPaymentDate ?? DateTime.now(),
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime.now(),
//                   );
//                   if (pickedDate != null) {
//                     setState(() {
//                       _selectedPaymentDate = pickedDate;
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => _pickDekontImage(),
//                 child: const Text('Upload Dekont Image'),
//               ),
//               const SizedBox(height: 16),
//               _dekontImage != null
//                   ? Image.file(
//                 _dekontImage!,
//                 height: 100,
//               )
//                   : const Text('No image selected'),
//             ],
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _paymentStatus,
//               items: ['Completed', 'Pending', 'Failed'].map((String status) {
//                 return DropdownMenuItem<String>(
//                   value: status,
//                   child: Text(status),
//                 );
//               }).toList(),
//               onChanged: (newValue) {
//                 setState(() {
//                   _paymentStatus = newValue!;
//                 });
//               },
//               decoration: const InputDecoration(labelText: 'Payment Status'),
//             ),
//             const SizedBox(height: 16),
//             if (_selectedDueDate != null) ...[
//               CheckboxListTile(
//                 title: const Text('Enable Notifications'),
//                 value: _enableNotifications,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     _enableNotifications = value ?? false;
//                   });
//                 },
//               ),
//               if (_enableNotifications)
//                 Column(
//                   children: [
//                     const Text('Remind me before:'),
//                     CheckboxListTile(
//                       title: const Text('3 days'),
//                       value: _notificationOptions[0],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[0] = value ?? false;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('2 days'),
//                       value: _notificationOptions[1],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[1] = value ?? false;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('1 day'),
//                       value: _notificationOptions[2],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[2] = value ?? false;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('6 hours'),
//                       value: _notificationOptions[3],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[3] = value ?? false;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//             ],
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(); // Close the dialog
//           },
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : () => _addPayment(context),
//           child: _isLoading ? const CircularProgressIndicator() : const Text('Add Payment'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickDekontImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     setState(() {
//       if (pickedFile != null) {
//         _dekontImage = File(pickedFile.path);
//         logger.info('Dekont image selected: ${pickedFile.path}');
//       } else {
//         logger.err('No dekont image selected.');
//       }
//     });
//   }
//
//   Future<void> _addPayment(BuildContext context) async {
//     if (_amountController.text.isEmpty) {
//       logger.err('Amount is required.');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enter the amount.')),
//         );
//       }
//       return;
//     }
//
//     if (_selectedDueDate == null && _selectedPaymentDate == null) {
//       logger.err('Either Payment Date or Due Date must be selected.');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select a payment date or a due date.')),
//         );
//       }
//       return;
//     }
//
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       // Prepare notification times if enabled
//       List<int>? notificationTimes;
//       if (_enableNotifications && _selectedDueDate != null) {
//         notificationTimes = [];
//         for (int i = 0; i < _notificationOptions.length; i++) {
//           if (_notificationOptions[i]) {
//             notificationTimes.add(_notificationTimes[i]);
//           }
//         }
//         if (notificationTimes.isEmpty) {
//           logger.err('At least one notification time must be selected.');
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Please select at least one notification time.')),
//             );
//           }
//           setState(() {
//             _isLoading = false;
//           });
//           return;
//         }
//       }
//
//       final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
//
//       await paymentProvider.addPayment(
//         userId: widget.userId,
//         subscription: widget.subscription,
//         amount: double.parse(_amountController.text),
//         paymentDate: _selectedPaymentDate,
//         status: _paymentStatus,
//         dekontImage: _dekontImage,
//         dueDate: _selectedDueDate,
//         notificationTimes: notificationTimes,
//       );
//
//       // Notify parent widget to refresh data
//       widget.onPaymentAdded();
//
//       if (!mounted) return;
//
//       setState(() {
//         _isLoading = false;
//       });
//       Navigator.of(context).pop(); // Close the dialog
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Payment added successfully.')),
//       );
//     } catch (e) {
//       logger.err('Error adding payment: $e');
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding payment: $e')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _amountController.dispose();
//     super.dispose();
//   }
// }
// // add_subscription_dialog.dart
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/subs_model.dart';
//
// class AddSubscriptionDialog extends StatefulWidget {
//   final String userId;
//   final Function onSubscriptionAdded;
//
//   const AddSubscriptionDialog({
//     super.key,
//     required this.userId,
//     required this.onSubscriptionAdded,
//   });
//
//   @override
//   createState() => _AddSubscriptionDialogState();
// }
//
// class _AddSubscriptionDialogState extends State<AddSubscriptionDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _packageNameController = TextEditingController();
//   final TextEditingController _totalMeetingsController = TextEditingController();
//   final TextEditingController _totalAmountController = TextEditingController();
//   DateTime? _startDate;
//   DateTime? _endDate;
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Subscription Package'),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: ListBody(
//             children: [
//               TextFormField(
//                 controller: _packageNameController,
//                 decoration: const InputDecoration(labelText: 'Package Name'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter package name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _totalMeetingsController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Total Meetings'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter total meetings';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _totalAmountController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Total Amount'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter total amount';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               ListTile(
//                 title: Text(_startDate == null
//                     ? 'Select Start Date'
//                     : 'Start Date: ${_startDate!.toLocal().toString().split(' ')[0]}'),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: () async {
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: _startDate ?? DateTime.now(),
//                     firstDate: DateTime.now().subtract(const Duration(days: 365)),
//                     lastDate: DateTime.now().add(const Duration(days: 365)),
//                   );
//                   if (pickedDate != null) {
//                     setState(() {
//                       _startDate = pickedDate;
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               ListTile(
//                 title: Text(_endDate == null
//                     ? 'Select End Date'
//                     : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}'),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: () async {
//                   DateTime initialDate = _startDate != null
//                       ? _startDate!.add(const Duration(days: 30))
//                       : DateTime.now().add(const Duration(days: 30));
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: _endDate ?? initialDate,
//                     firstDate: _startDate ?? DateTime.now(),
//                     lastDate: DateTime.now().add(const Duration(days: 730)),
//                   );
//                   if (pickedDate != null) {
//                     setState(() {
//                       _endDate = pickedDate;
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             if(!context.mounted)return;
//             Navigator.of(context).pop(); // Close the dialog
//           },
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : _addSubscription,
//           child: _isLoading
//               ? const CircularProgressIndicator()
//               : const Text('Add Subscription'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _addSubscription() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     if (_startDate == null || _endDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select start and end dates.')),
//       );
//       return;
//     }
//
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final subscriptionId = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('subscriptions')
//           .doc()
//           .id;
//
//       SubscriptionModel subscription = SubscriptionModel(
//         subscriptionId: subscriptionId,
//         userId: widget.userId,
//         packageName: _packageNameController.text,
//         startDate: _startDate!,
//         endDate: _endDate!,
//         totalMeetings: int.parse(_totalMeetingsController.text),
//         meetingsCompleted: 0,
//         meetingsRemaining: int.parse(_totalMeetingsController.text),
//         meetingsBurned: 0,
//         postponementsUsed: 0,
//         allowedPostponementsPerMonth: 1,
//         totalAmount: double.parse(_totalAmountController.text),
//         amountPaid: 0.0,
//         status: SubActiveStatus.active,
//       );
//
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('subscriptions')
//           .doc(subscriptionId)
//           .set(subscription.toMap());
//       //logger.info('Subscription added successfully {}',[subscription]);
//       // Notify parent widget to refresh data
//       widget.onSubscriptionAdded();
//
//       if (!mounted) return;
//
//       setState(() {
//         _isLoading = false;
//       });
//       if(!context.mounted)return;
//
//       Navigator.of(context).pop(); // Close the dialog
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Subscription added successfully.')),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding subscription: $e')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _packageNameController.dispose();
//     _totalMeetingsController.dispose();
//     _totalAmountController.dispose();
//     super.dispose();
//   }
// }
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../models/logger.dart';
// import '../models/test_model.dart';
//
// class AddTestDialog extends StatefulWidget {
//   final String userId;
//   final Function onTestAdded;
//
//   const AddTestDialog({
//     super.key,
//     required this.userId,
//     required this.onTestAdded,
//   });
//
//   @override
//   createState() => _AddTestDialogState();
// }
//
// class _AddTestDialogState extends State<AddTestDialog> {
//   final Logger logger = Logger.forClass(AddTestDialog);
//
//   // Controllers and variables
//   final TextEditingController _testNameController = TextEditingController();
//   final TextEditingController _testDescriptionController =
//   TextEditingController();
//   DateTime? _selectedTestDate;
//   File? _testFile;
//   final ImagePicker _picker = ImagePicker();
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Test'),
//       content: SingleChildScrollView(
//         child: ListBody(
//           children: [
//             TextField(
//               controller: _testNameController,
//               decoration: const InputDecoration(labelText: 'Test Name'),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _testDescriptionController,
//               decoration: const InputDecoration(labelText: 'Description'),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               title: Text(_selectedTestDate == null
//                   ? 'Select Test Date'
//                   : 'Test Date: ${_selectedTestDate!.toLocal().toString().split(' ')[0]}'),
//               trailing: const Icon(Icons.calendar_today),
//               onTap: () async {
//                 DateTime? pickedDate = await showDatePicker(
//                   context: context,
//                   initialDate: _selectedTestDate ?? DateTime.now(),
//                   firstDate: DateTime(2000),
//                   lastDate: DateTime.now(),
//                 );
//                 if (pickedDate != null) {
//                   setState(() {
//                     _selectedTestDate = pickedDate;
//                   });
//                 }
//               },
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => _pickTestFile(),
//               child: const Text('Upload Test File'),
//             ),
//             const SizedBox(height: 16),
//             _testFile != null
//                 ? Text('File selected: ${_testFile!.path.split('/').last}')
//                 : const Text('No file selected'),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(); // Close the dialog
//           },
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : () => _addTest(),
//           child: _isLoading
//               ? const CircularProgressIndicator()
//               : const Text('Add Test'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickTestFile() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     // Alternatively, use `pickImage` for images or `pickVideo` for videos
//     // For PDFs, you might need to use a different package like `file_picker`
//
//     if (pickedFile != null) {
//       setState(() {
//         _testFile = File(pickedFile.path);
//         logger.info('Test file selected: {}', [pickedFile.path]);
//       });
//     } else {
//       logger.err('No test file selected.');
//     }
//   }
//
//   Future<void> _addTest() async {
//     if (_testNameController.text.isEmpty ||
//         _selectedTestDate == null ||
//         _testFile == null) {
//       logger.err('Please fill all required fields.');
//       if(!context.mounted)return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields.')),
//       );
//       return;
//     }
//
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       // Upload the test file
//       String testFileUrl = await _uploadTestFile();
//
//       // Create a new test document
//       final testDocRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('tests')
//           .doc(); // Generate a new test ID
//
//       TestModel testModel = TestModel(
//         testId: testDocRef.id,
//         userId: widget.userId,
//         testName: _testNameController.text,
//         testDescription: _testDescriptionController.text,
//         testDate: _selectedTestDate!,
//         testFileUrl: testFileUrl,
//       );
//
//       await testDocRef.set(testModel.toMap());
//       logger.info('Test added successfully for user {}', [widget.userId]);
//
//       // Notify parent widget to refresh data
//       widget.onTestAdded();
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//       });
//
//       Navigator.of(context).pop(); // Close the dialog
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Test added successfully.')),
//       );
//     } catch (e) {
//       logger.err('Error adding test: {}', [e]);
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding test: $e')),
//       );
//     }
//   }
//
//   Future<String> _uploadTestFile() async {
//     try {
//       final fileName =
//           '${DateTime.now().millisecondsSinceEpoch}_${_testFile!.path.split('/').last}';
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('users/${widget.userId}/tests/$fileName');
//       final uploadTask = ref.putFile(_testFile!);
//
//       final snapshot = await uploadTask;
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//
//       logger.info('Test file uploaded: {}', [downloadUrl]);
//
//       return downloadUrl;
//     } catch (e) {
//       logger.err('Error uploading test file: {}', [e]);
//       throw Exception('Error uploading test file: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _testNameController.dispose();
//     _testDescriptionController.dispose();
//     super.dispose();
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../models/appointment_model.dart';
// import '../providers/appointment_manager.dart';
// import 'package:provider/provider.dart';
//
// class EditAppointmentDialog extends StatefulWidget {
//   final AppointmentModel appointment;
//   final Function onAppointmentUpdated;
//
//   const EditAppointmentDialog({
//     super.key,
//     required this.appointment,
//     required this.onAppointmentUpdated,
//   });
//
//   @override
//   createState() => _EditAppointmentDialogState();
// }
//
// class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
//   late MeetingType _meetingType;
//   late DateTime _appointmentDateTime;
//   final _notesController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _meetingType = widget.appointment.meetingType;
//     _appointmentDateTime = widget.appointment.appointmentDateTime;
//     _notesController.text = widget.appointment.notes ?? '';
//   }
//
//   Future<void> _updateAppointment() async {
//     try {
//       final appointmentManager = Provider.of<AppointmentManager>(context, listen: false);
//       appointmentManager.setUserId(widget.appointment.userId);
//
//       AppointmentModel updatedAppointment = AppointmentModel(
//         appointmentId: widget.appointment.appointmentId,
//         userId: widget.appointment.userId,
//         subscriptionId: widget.appointment.subscriptionId,
//         meetingType: _meetingType,
//         appointmentDateTime: _appointmentDateTime,
//         status: widget.appointment.status,
//         notes: _notesController.text,
//         createdAt: widget.appointment.createdAt,
//         updatedAt: DateTime.now(),
//         createdBy: widget.appointment.createdBy,
//         canceledBy: widget.appointment.canceledBy,
//         canceledAt: widget.appointment.canceledAt,
//       );
//
//       await appointmentManager.updateAppointment(updatedAppointment);
//
//       widget.onAppointmentUpdated();
//       if(!mounted)return;
//       Navigator.of(context).pop();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating appointment: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Edit Appointment'),
//       content: SingleChildScrollView(
//         child: Column(
//           children: [
//             ListTile(
//               title: const Text('Meeting Type'),
//               trailing: DropdownButton<MeetingType>(
//                 value: _meetingType,
//                 onChanged: (MeetingType? newValue) {
//                   setState(() {
//                     _meetingType = newValue!;
//                   });
//                 },
//                 items: MeetingType.values
//                     .map<DropdownMenuItem<MeetingType>>((MeetingType type) {
//                   return DropdownMenuItem<MeetingType>(
//                     value: type,
//                     child: Text(type.label),
//                   );
//                 }).toList(),
//               ),
//             ),
//             ListTile(
//               title: Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(_appointmentDateTime)}'),
//               trailing: const Icon(Icons.calendar_today),
//               onTap: () async {
//                 final DateTime? pickedDate = await showDatePicker(
//                   context: context,
//                   initialDate: _appointmentDateTime,
//                   firstDate: DateTime.now(),
//                   lastDate: DateTime.now().add(const Duration(days: 365)),
//                 );
//                 if (pickedDate != null) {
//                   final TimeOfDay? pickedTime = await showTimePicker(
//                     context: context,
//                     initialTime: TimeOfDay.fromDateTime(_appointmentDateTime),
//                   );
//                   if (pickedTime != null) {
//                     setState(() {
//                       _appointmentDateTime = DateTime(
//                         pickedDate.year,
//                         pickedDate.month,
//                         pickedDate.day,
//                         pickedTime.hour,
//                         pickedTime.minute,
//                       );
//                     });
//                   }
//                 }
//               },
//             ),
//             TextField(
//               controller: _notesController,
//               decoration: const InputDecoration(labelText: 'Notes'),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _updateAppointment,
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }
// }
// // edit_payment_dialog.dart
//
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
//
// import '../models/logger.dart';
// import '../models/payment_model.dart';
//
// class EditPaymentDialog extends StatefulWidget {
//   final PaymentModel payment;
//   final Function onPaymentUpdated;
//
//   const EditPaymentDialog({
//     super.key,
//     required this.payment,
//     required this.onPaymentUpdated,
//   });
//
//   @override
//   createState() => _EditPaymentDialogState();
// }
//
// class _EditPaymentDialogState extends State<EditPaymentDialog> {
//   final Logger logger = Logger.forClass(EditPaymentDialog);
//
//   final TextEditingController _amountController = TextEditingController();
//   DateTime? _selectedPaymentDate;
//   DateTime? _selectedDueDate;
//   String _paymentStatus = 'Pending';
//   File? _dekontImage;
//   final ImagePicker _picker = ImagePicker();
//   bool _isLoading = false;
//
//
//   // New variables for notifications
//   bool _enableNotifications = false;
//   final List<bool> _notificationOptions = [false, false, false, false];
//   final List<int> _notificationTimes = [72, 48, 24, 6]; // Hours before due date
//
//   @override
//   void initState() {
//     super.initState();
//     _amountController.text = widget.payment.amount.toString();
//     _selectedPaymentDate = widget.payment.paymentDate;
//     _selectedDueDate = widget.payment.dueDate;
//     _paymentStatus = widget.payment.status;
//     _enableNotifications = widget.payment.notificationTimes != null;
//     if (_enableNotifications && widget.payment.notificationTimes != null) {
//       for (int i = 0; i < _notificationTimes.length; i++) {
//         _notificationOptions[i] =
//             widget.payment.notificationTimes!.contains(_notificationTimes[i]);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Edit Payment'),
//       content: SingleChildScrollView(
//         child: ListBody(
//           children: [
//             TextField(
//               controller: _amountController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(labelText: 'Amount'),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               title: Text(_selectedDueDate == null
//                   ? 'Select Due Date (Optional)'
//                   : 'Due Date: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}'),
//               trailing: const Icon(Icons.calendar_today),
//               onTap: () async {
//                 DateTime? pickedDate = await showDatePicker(
//                   context: context,
//                   initialDate: _selectedDueDate ?? DateTime.now(),
//                   firstDate: DateTime.now(),
//                   lastDate: DateTime.now().add(const Duration(days: 365)),
//                 );
//                 if (pickedDate != null) {
//                   setState(() {
//                     _selectedDueDate = pickedDate;
//                     // If a due date is selected, clear the payment date
//                     _selectedPaymentDate = null;
//                   });
//                 }
//               },
//             ),
//             const SizedBox(height: 16),
//             if (_selectedDueDate == null) ...[
//               ListTile(
//                 title: Text(_selectedPaymentDate == null
//                     ? 'Select Payment Date'
//                     : 'Payment Date: ${_selectedPaymentDate!.toLocal().toString().split(' ')[0]}'),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: () async {
//                   DateTime? pickedDate = await showDatePicker(
//                     context: context,
//                     initialDate: _selectedPaymentDate ?? DateTime.now(),
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime.now(),
//                   );
//                   if (pickedDate != null) {
//                     setState(() {
//                       _selectedPaymentDate = pickedDate;
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => _pickDekontImage(),
//                 child: const Text('Upload Dekont Image'),
//               ),
//               const SizedBox(height: 16),
//               _dekontImage != null
//                   ? Image.file(
//                 _dekontImage!,
//                 height: 100,
//               )
//                   : widget.payment.dekontUrl != null
//                   ? Image.network(
//                 widget.payment.dekontUrl!,
//                 height: 100,
//               )
//                   : const Text('No image selected'),
//             ],
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               value: _paymentStatus,
//               items: ['Completed', 'Pending', 'Failed'].map((String status) {
//                 return DropdownMenuItem<String>(
//                   value: status,
//                   child: Text(status),
//                 );
//               }).toList(),
//               onChanged: (newValue) {
//                 setState(() {
//                   _paymentStatus = newValue!;
//                 });
//               },
//               decoration: const InputDecoration(labelText: 'Payment Status'),
//             ),
//             const SizedBox(height: 16),
//             if (_selectedDueDate != null) ...[
//               CheckboxListTile(
//                 title: const Text('Enable Notifications'),
//                 value: _enableNotifications,
//                 onChanged: (bool? value) {
//                   setState(() {
//                     _enableNotifications = value ?? false;
//                   });
//                 },
//               ),
//               if (_enableNotifications)
//                 Column(
//                   children: [
//                     const Text('Remind me before:'),
//                     CheckboxListTile(
//                       title: const Text('3 days'),
//                       value: _notificationOptions[0],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[0] = value ?? false;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('2 days'),
//                       value: _notificationOptions[1],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[1] = value ?? false;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('1 day'),
//                       value: _notificationOptions[2],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[2] = value ?? false;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: const Text('6 hours'),
//                       value: _notificationOptions[3],
//                       onChanged: (bool? value) {
//                         setState(() {
//                           _notificationOptions[3] = value ?? false;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//             ],
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(); // Close the dialog
//           },
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : () => _updatePayment(),
//           child: _isLoading
//               ? const CircularProgressIndicator()
//               : const Text('Update Payment'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickDekontImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     setState(() {
//       if (pickedFile != null) {
//         _dekontImage = File(pickedFile.path);
//         logger.info('Dekont image selected: ${pickedFile.path}');
//       } else {
//         logger.err('No dekont image selected.');
//       }
//     });
//   }
//
//   Future<void> _updatePayment() async {
//     if (_amountController.text.isEmpty) {
//       logger.err('Amount is required.');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enter the amount.')),
//         );
//       }
//       return;
//     }
//
//     if (_selectedDueDate == null && _selectedPaymentDate == null) {
//       logger.err('Either Payment Date or Due Date must be selected.');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select a payment date or a due date.')),
//         );
//       }
//       return;
//     }
//
//     // if (_selectedPaymentDate != null &&
//     //     _dekontImage == null &&
//     //     widget.payment.dekontUrl == null) {
//     //   logger.err('Dekont image is required when Payment Date is selected.');
//     //   if (mounted) {
//     //     ScaffoldMessenger.of(context).showSnackBar(
//     //       const SnackBar(content: Text('Please upload a dekont image.')),
//     //     );
//     //   }
//     //   return;
//     // }
//
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       String? dekontUrl = widget.payment.dekontUrl;
//
//       // Upload the new dekont image if it exists
//       if (_dekontImage != null) {
//         dekontUrl = await _uploadDekontImage();
//       }
//
//       // Prepare notification times if enabled
//       List<int>? notificationTimes;
//       if (_enableNotifications && _selectedDueDate != null) {
//         notificationTimes = [];
//         for (int i = 0; i < _notificationOptions.length; i++) {
//           if (_notificationOptions[i]) {
//             notificationTimes.add(_notificationTimes[i]);
//           }
//         }
//         if (notificationTimes.isEmpty) {
//           logger.err('At least one notification time must be selected.');
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Please select at least one notification time.')),
//             );
//           }
//           setState(() {
//             _isLoading = false;
//           });
//           return;
//         }
//       }
//
//       // Update the payment document
//       PaymentModel updatedPayment = PaymentModel(
//         paymentId: widget.payment.paymentId,
//         userId: widget.payment.userId,
//         subscriptionId: widget.payment.subscriptionId,
//         amount: double.parse(_amountController.text),
//         paymentDate: _selectedPaymentDate ?? widget.payment.paymentDate,
//         status: _paymentStatus,
//         dekontUrl: dekontUrl,
//         dueDate: _selectedDueDate,
//         notificationTimes: notificationTimes,
//       );
//
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.payment.userId)
//           .collection('payments')
//           .doc(widget.payment.paymentId)
//           .update(updatedPayment.toMap());
//
//       logger.info('Payment updated successfully for user ${widget.payment.userId}');
//
//       // Optionally, update the subscription's amountPaid if the amount has changed
//       // You can implement this logic based on your application's requirements
//
//       // Notify parent widget to refresh data
//       widget.onPaymentUpdated();
//
//       if (!mounted) return;
//
//       setState(() {
//         _isLoading = false;
//       });
//
//       Navigator.of(context).pop(); // Close the dialog
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Payment updated successfully.')),
//       );
//     } catch (e) {
//       logger.err('Error updating payment: $e');
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating payment: $e')),
//       );
//     }
//   }
//
//   Future<String> _uploadDekontImage() async {
//     try {
//       final fileName = DateTime.now().millisecondsSinceEpoch.toString();
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('users/${widget.payment.userId}/dekont/$fileName');
//       final uploadTask = ref.putFile(_dekontImage!);
//
//       final snapshot = await uploadTask;
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//
//       logger.info('Dekont image uploaded to $downloadUrl');
//
//       return downloadUrl;
//     } catch (e) {
//       logger.err('Error uploading dekont image: $e');
//       throw Exception('Error uploading dekont image: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _amountController.dispose();
//     super.dispose();
//   }
// }
