//ortak şeyler burada toplansın
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
enum DateFilter { today, last3Days, last7Days, last30Days }

enum ViewType { list, grid }

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
static const String urlUsers = 'users/';
static const String urlChats = '${urlUsers}chats/'; // + <user>/<date>/x
static const String urlPhotos = '${urlUsers}photos/'; // +<user>/
//user bilgisi olmöadan bu2lı kullanılamaz buna da bı fıx ıı olur
  static const String urlMealPhotos = '${urlPhotos}mealPhotos/'; // + <date>/<mealType>/x
  static const String urlChatPhotos = '${urlPhotos}chatPhotos/'; // + <date>/x
}

class Appointment {
  String id;
  String name;
  String serviceType; // 'online' or 'face-to-face'
  DateTime date;

  // String date;
  // String time;
  TimeOfDay time;

  Appointment({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.date,
    required this.time,
  });

  // Convert a Appointment into a Map. The keys must correspond to the names of the fields in Firestore.
  // Map<String, dynamic> toJson(BuildContext context) => {
  //   'id': id,
  //   'name': name,
  //   'serviceType': serviceType,
  //   'date': date.toString(),
  //   // 'time': time.format(context).toString(), // context is needed to format the time
  //   'time': time.format(context).toString(), // context is needed to format the time
  //
  // };
  Map<String, dynamic> toJson(BuildContext context) => {
    'id': id,
    'name': name,
    'serviceType': serviceType,
    'date': date,
    //.toIso8601String(), // Convert DateTime to ISO 8601 string
    'time': '${time.hour}:${time.minute}',
    // Convert TimeOfDay to a string in HH:mm format
  };

  // A method that retrieves all the data from Firestore and converts it to an Appointment object.
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    name: json['name'],
    serviceType: json['serviceType'],
    date: (json['date'] as Timestamp).toDate(),
    time: TimeOfDay(
        hour: int.parse(json['time'].split(':')[0]),
        minute: int.parse(json['time'].split(':')[1])),
  );

  TimeOfDay getTime() {
    return time;
  }
}