//ortak şeyler burada toplansın
import 'package:cloud_firestore/cloud_firestore.dart';

enum DateFilter { today, last3Days, last7Days, last30Days }

enum ViewType { list, grid }

enum MeetingType { online, f2f }

enum Meals {
  br('kahvalti', 'sabah/'),
  firstmid('sabah ara öğün', 'ilkara/'),
  lunch('öğle yemeği', 'oglen/'),
  secondmid('ikindi ara öğün', 'ikinciara/'),
  dinner('akşam yemeği', 'aksam/'),
  thirdmid('akşam ara öğün', 'ucuncuara/'),
  ;

  const Meals(this.label, this.url);

  final String label;
  final String url;
}

class Constants {
  static const String saveTime = 'saveTime';
  //database
  static const String appointments = 'appointments';
  static const String urlChats = 'chats/'; // + <user>/<date>/x
  //storage
  static const String urlUsers = 'users/';
  static const String urlPhotos = '${urlUsers}photos/'; // +<user>/
//user bilgisi olmadan bu2lı kullanılamaz buna da bı fıx ıı olur
  static const String urlMealPhotos =
      'mealPhotos/'; // + <date>/<mealType>/x
  static const String urlChatPhotos = 'chatPhotos/'; // + <date>/x
}

class Appointment {
  String id;
  String name;
  String serviceType; // 'online' or 'face-to-face'
  DateTime dateTime;

  // String date;
  // String time;
  // TimeOfDay time;

  Appointment({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.dateTime,
    // required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serviceType': serviceType,
        'dateTime': Timestamp.fromDate(dateTime),
        // Convert DateTime to Timestamp
      };

// A method that retrieves all the data from Firestore and converts it to an Appointment object.
  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Parse the date and time into a single DateTime object
    DateTime date = (json['dateTime'] as Timestamp).toDate();
    DateTime dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );

    return Appointment(
      id: json['id'],
      name: json['name'],
      serviceType: json['serviceType'],
      dateTime: dateTime,
    );
  }
}
