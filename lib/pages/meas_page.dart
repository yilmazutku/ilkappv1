import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/meas_model.dart';



class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  List<MeasurementModel> measurements = [];
  final dateFormat = DateFormat('dd.MM.yyyy');
  void pickAndParseExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        print('No file selected.');
        return;
      }

      Uint8List? fileBytes = result.files.first.bytes;

      // If bytes are null, try reading from file path
      if (fileBytes == null && result.files.first.path != null) {
        final filePath = result.files.first.path!;
        final file = File(filePath);
        fileBytes = await file.readAsBytes();
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        print('File is empty or unreadable.');
        return;
      }

      // Decode excel
      final excel = Excel.decodeBytes(fileBytes);
      List<MeasurementModel> parsedMeasurements = [];

      // Parse each table/sheet
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        // Start from row 1 if row 0 is header
        for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
          final row = sheet.rows[rowIndex];

          // Skip rows with no actual data
          if (row.every((cell) => cell == null || cell.value == null)) {
            continue;
          }

          // Ensure the row has enough columns
          // (Adjust this number to match however many columns you expect)
          if (row.length < 13) {
            print('Skipping row $rowIndex because it does not have 13 columns.');
            continue;
          }

          try {
            print('Parsing row $rowIndex: '
                '${row.map((c) => c?.value.runtimeType)}');

            // Build the measurement
            final measurement = MeasurementModel(
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
    } catch (e) {
      print('Error parsing file: $e');
    }
  }

  /// Tries to handle Excel numeric dates and strings
  DateTime _parseDate(dynamic value) {
    if (value == null) throw Exception('Date value is null');

    // Already DateTime
    if (value is DateTime) return value;

    // If Excel stored as a numeric value (e.g., 44643)
    // You can try external libraries or your own offset logic. For simplicity:
    if (value is num) {
      // Approximate approach: Excel typically uses an epoch of 1899-12-30
      // This is a naive approach and may need adjustments.
      final excelEpoch = DateTime(1899, 12, 30);
      return excelEpoch.add(Duration(days: value.toInt()));
    }

    // If string, attempt standard parse
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }

  String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  void addRow() {
    setState(() {
      measurements.add(MeasurementModel(date: DateTime.now()));
    });
  }

  void deleteRow(int index) {
    setState(() {
      measurements.removeAt(index);
    });
  }

  void editRow(MeasurementModel measurement, int index) async {
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
        await collection.add(measurement.toMap());
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
              scrollDirection: Axis.vertical, // Enable vertical scrolling
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Tarih')),
                    DataColumn(label: Text('Göğüs')),
                    DataColumn(label: Text('Sırt')),
                    DataColumn(label: Text('Bel')),
                    DataColumn(label: Text('Kalça')),
                    DataColumn(label: Text('Bacak')),
                    DataColumn(label: Text('Kol')),
                    DataColumn(label: Text('Ağırlık')),
                    DataColumn(label: Text('Yağ (kg)')),
                    DataColumn(label: Text('Açlık')),
                    DataColumn(label: Text('Kabızlık')),
                    DataColumn(label: Text('Diğer')),
                    DataColumn(label: Text('Kalori')),
                    DataColumn(label: Text('Aksiyonlar')),
                  ],
                  rows: measurements.asMap().map((index, measurement) {
                    return MapEntry(
                      index,
                      DataRow(cells: [
                        DataCell(Text(dateFormat.format(measurement.date))),
                        DataCell(Text(measurement.chest?.toString() ?? '')),
                        DataCell(Text(measurement.back?.toString() ?? '')),
                        DataCell(Text(measurement.waist?.toString() ?? '')),
                        DataCell(Text(measurement.hips?.toString() ?? '')),
                        DataCell(Text(measurement.leg?.toString() ?? '')),
                        DataCell(Text(measurement.arm?.toString() ?? '')),
                        DataCell(Text(measurement.weight?.toString() ?? '')),
                        DataCell(Text(measurement.fatKg?.toString() ?? '')),
                        DataCell(Text(measurement.hungerStatus ?? '')),
                        DataCell(Text(measurement.constipation ?? '')),
                        DataCell(Text(measurement.other ?? '')),
                        DataCell(Text(measurement.calorie?.toString() ?? '')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    editRow(measurements[index], index),
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
                  }).values.toList(),
                ),
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

class EditMeasurementPage extends StatefulWidget {
  final MeasurementModel measurement;

  const EditMeasurementPage({super.key, required this.measurement});

  @override
  State<EditMeasurementPage> createState() => _EditMeasurementPageState();
}

class _EditMeasurementPageState extends State<EditMeasurementPage> {
  late TextEditingController chestController;
  late TextEditingController backController;
  late TextEditingController waistController;
  late TextEditingController hipsController;
  late TextEditingController legController;
  late TextEditingController armController;
  late TextEditingController weightController;
  late TextEditingController fatKgController;
  late TextEditingController hungerStatusController;
  late TextEditingController constipationController;
  late TextEditingController otherController;
  late TextEditingController calorieController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with the current measurement values
    chestController = TextEditingController(text: widget.measurement.chest?.toString() ?? '');
    backController = TextEditingController(text: widget.measurement.back?.toString() ?? '');
    waistController = TextEditingController(text: widget.measurement.waist?.toString() ?? '');
    hipsController = TextEditingController(text: widget.measurement.hips?.toString() ?? '');
    legController = TextEditingController(text: widget.measurement.leg?.toString() ?? '');
    armController = TextEditingController(text: widget.measurement.arm?.toString() ?? '');
    weightController = TextEditingController(text: widget.measurement.weight?.toString() ?? '');
    fatKgController = TextEditingController(text: widget.measurement.fatKg?.toString() ?? '');
    hungerStatusController = TextEditingController(text: widget.measurement.hungerStatus ?? '');
    constipationController = TextEditingController(text: widget.measurement.constipation ?? '');
    otherController = TextEditingController(text: widget.measurement.other ?? '');
    calorieController = TextEditingController(text: widget.measurement.calorie?.toString() ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    chestController.dispose();
    backController.dispose();
    waistController.dispose();
    hipsController.dispose();
    legController.dispose();
    armController.dispose();
    weightController.dispose();
    fatKgController.dispose();
    hungerStatusController.dispose();
    constipationController.dispose();
    otherController.dispose();
    calorieController.dispose();
    super.dispose();
  }

  void saveChanges() {
    Navigator.pop(
      context,
      MeasurementModel(
        date: widget.measurement.date, // Date remains unchanged
        chest: double.tryParse(chestController.text),
        back: double.tryParse(backController.text),
        waist: double.tryParse(waistController.text),
        hips: double.tryParse(hipsController.text),
        leg: double.tryParse(legController.text),
        arm: double.tryParse(armController.text),
        weight: double.tryParse(weightController.text),
        fatKg: double.tryParse(fatKgController.text),
        hungerStatus: hungerStatusController.text.isNotEmpty ? hungerStatusController.text : null,
        constipation: constipationController.text.isNotEmpty ? constipationController.text : null,
        other: otherController.text.isNotEmpty ? otherController.text : null,
        calorie: int.tryParse(calorieController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Measurement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTextField('Göğüs', chestController),
              _buildTextField('Sırt', backController),
              _buildTextField('Bel', waistController),
              _buildTextField('Kalça', hipsController),
              _buildTextField('Bacak', legController),
              _buildTextField('Kol', armController),
              _buildTextField('Ağırlık', weightController),
              _buildTextField('Yağ (kg)', fatKgController),
              _buildTextField('Açlık', hungerStatusController),
              _buildTextField('Kabızlık', constipationController),
              _buildTextField('Diğer', otherController),
              _buildTextField('Kalori', calorieController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveChanges,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}