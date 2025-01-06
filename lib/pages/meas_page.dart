import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore


class Measurement {
  DateTime date;
  double? chest;
  double? back;
  double? waist;
  double? hips;
  double? leg;
  double? arm;
  double? weight;
  double? fatKg;
  String? hungerStatus;
  String? constipation;
  String? other;
  int? calorie;

  Measurement({
    required this.date,
    this.chest,
    this.back,
    this.waist,
    this.hips,
    this.leg,
    this.arm,
    this.weight,
    this.fatKg,
    this.hungerStatus,
    this.constipation,
    this.other,
    this.calorie,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'chest': chest,
      'back': back,
      'waist': waist,
      'hips': hips,
      'leg': leg,
      'arm': arm,
      'weight': weight,
      'fatKg': fatKg,
      'hungerStatus': hungerStatus,
      'constipation': constipation,
      'other': other,
      'calorie': calorie,
    };
  }

  static Measurement fromJson(Map<String, dynamic> json) {
    return Measurement(
      date: DateTime.parse(json['date']),
      chest: json['chest']?.toDouble(),
      back: json['back']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      leg: json['leg']?.toDouble(),
      arm: json['arm']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fatKg: json['fatKg'].toDouble(),
      hungerStatus: json['hungerStatus'],
      constipation: json['constipation'],
      other: json['other'],
      calorie: json['calorie']?.toInt(),
    );
  }
}

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  List<Measurement> measurements = [];

  void pickAndParseExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;

        if (fileBytes == null && result.files.first.path != null) {
          // Fallback to reading file from path
          final filePath = result.files.first.path!;
          final file = File(filePath);
          fileBytes = await file.readAsBytes();
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          final excel = Excel.decodeBytes(fileBytes);
          List<Measurement> parsedMeasurements = [];

          for (var table in excel.tables.keys) {
            final sheet = excel.tables[table];
            if (sheet == null) continue;

            for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
              final row = sheet.rows[rowIndex];
              try {
                // Debug log
                print('Parsing row $rowIndex: ${row.map((cell) => cell?.value.runtimeType)}');
                print('Row $rowIndex Values: ${row.map((cell) => cell?.value)}');

                final measurement = Measurement(
                  date: _parseDate(row[0]?.value),
                  chest: _parseDouble(row[1]?.value),
                  back: _parseDouble(row[2]?.value),
                  waist: _parseDouble(row[3]?.value),
                  hips: _parseDouble(row[4]?.value),
                  leg: _parseDouble(row[5]?.value),
                  arm: _parseDouble(row[6]?.value),
                  weight: _parseDouble(row[7]?.value),
                  fatKg: _parseDouble(row[8]?.value),
                  hungerStatus: _parseString(row[9]?.value),
                  constipation: _parseString(row[10]?.value),
                  other: _parseString(row[11]?.value),
                  calorie: _parseInt(row[12]?.value),
                );
                parsedMeasurements.add(measurement);
              } catch (e) {
                print('Error parsing row $rowIndex: $e');
              }
            }
          }

          setState(() {
            measurements = parsedMeasurements;
          });
        } else {
          print('File is empty or unreadable.');
        }
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('Error parsing file: $e');
    }
  }



  DateTime _parseDate(dynamic value) {
    if (value == null) throw Exception('Date value is null');
    if (value is DateTime) return value; // Already a DateTime
    if (value is int) {
      // Try interpreting as Excel numeric date
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is SharedString || value is String) {
      // Try ISO and fallback to common formats
      return DateTime.tryParse(value.toString()) ?? DateTime.now(); // Fallback to now
    }
    throw Exception('Invalid date value: $value');
  }


  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble(); // Convert int to double
    if (value is SharedString ||value is String) {
      return double.tryParse(value.toString());
    }
    throw Exception('Invalid double value: $value');
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '.'));
    }
    throw Exception('Invalid int value: $value');
  }


  String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }


  void addRow() {
    setState(() {
      measurements.add(
        Measurement(date: DateTime.now()),
      );
    });
  }

  void deleteRow(int index) {
    setState(() {
      measurements.removeAt(index);
    });
  }

  void editRow(Measurement measurement, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMeasurementPage(measurement: measurement),
      ),
    );

    if (result != null) {
      setState(() {
        measurements[index] = result;
      });
    }
  }

  void uploadToFirebase() async {
    try {
      final collection = FirebaseFirestore.instance.collection('measurements');

      for (var measurement in measurements) {
        await collection.add(measurement.toJson());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data uploaded successfully to Firebase!')),
      );
    } catch (e) {
      print('Error uploading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: uploadToFirebase,
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickAndParseExcel,
            child: const Text('Import Excel'),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Chest')),
                  DataColumn(label: Text('Back')),
                  DataColumn(label: Text('Waist')),
                  DataColumn(label: Text('Hips')),
                  DataColumn(label: Text('Leg')),
                  DataColumn(label: Text('Arm')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Fat (kg)')),
                  DataColumn(label: Text('Meal Status')),
                  DataColumn(label: Text('Constipation')),
                  DataColumn(label: Text('Other')),
                  DataColumn(label: Text('Calorie')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: measurements
                    .asMap()
                    .map((index, measurement) {
                  return MapEntry(
                    index,
                    DataRow(cells: [
                      DataCell(Text(measurement.date.toIso8601String())),
                      DataCell(Text(measurement.chest?.toString() ?? '')),
                      DataCell(Text(measurement.back?.toString() ?? '')),
                      DataCell(Text(measurement.waist?.toString() ?? '')),
                      DataCell(Text(measurement.hips?.toString() ?? '')),
                      DataCell(Text(measurement.leg?.toString() ?? '')),
                      DataCell(Text(measurement.arm?.toString() ?? '')),
                      DataCell(Text(measurement.weight?.toString() ?? '')),
                      DataCell(Text(measurement.fatKg.toString() ?? '')),
                      DataCell(Text(measurement.hungerStatus ?? '')),
                      DataCell(Text(measurement.constipation ?? '')),
                      DataCell(Text(measurement.other ?? '')),
                      DataCell(Text(measurement.calorie?.toString() ?? '')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => editRow(measurements[index], index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteRow(index),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  );
                })
                    .values
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addRow,
        child: const Icon(Icons.add),
      ),
    );
  }

}

class EditMeasurementPage extends StatelessWidget {
  final Measurement measurement;

  const EditMeasurementPage({Key? key, required this.measurement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Similar to earlier EditMeasurementPage implementation.
    return Scaffold();
  }
}