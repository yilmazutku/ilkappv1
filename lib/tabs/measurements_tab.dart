import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meas_model.dart';
import '../pages/tanita_explorer_page.dart';
import '../providers/meas_provider.dart';
import 'basetab.dart'; // Your BaseTab definitions
import '../models/logger.dart'; // For logging

class MeasTab extends BaseTab<MeasProvider> {
  const MeasTab({
    super.key,
    required super.userId,
  }) : super(
    allDataLabel: 'Tüm Ölçümler',
    subscriptionDataLabel: 'Tüm Ölçümler',
  );

  @override
  MeasProvider getProvider(BuildContext context) {
    return Provider.of<MeasProvider>(context, listen: false);
  }

  @override
  Future<List<dynamic>> getDataList(MeasProvider provider, bool showAllData) {
    // We can ignore showAllData here, or adapt it if needed
    return provider.fetchMeasurements(userId);
  }

  @override
   createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends BaseTabState<MeasProvider, MeasTab> {
  final Logger logger = Logger.forClass(_MeasurementsTabState);

  // Holds the measurements in memory
  List<MeasurementModel> _measurements = [];

  final DateFormat dateFormat = DateFormat('dd.MM.yyyy');
  bool _isSaving = false; // Track if saving is in progress

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    // Cast dynamic list from fetchMeasurements
    _measurements = dataList.cast<MeasurementModel>();
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickAndParseExcel,
              child: const Text('Excel İçe Aktar'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges, // Disable when saving
              child: _isSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white, // Matches button text color
                ),
              )
                  : const Text('Kaydet'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addRow,
              child: const Text('Yeni Satır'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to a "TanitaExplorerPage"
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TanitaExplorerPage(userId: widget.userId),
                  ),
                );
              },
              child: const Text('Tanita'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                rows: _measurements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meas = entry.value;
                  return DataRow(cells: [
                    DataCell(Text(dateFormat.format(meas.date))),
                    DataCell(Text(meas.chest?.toString() ?? '')),
                    DataCell(Text(meas.back?.toString() ?? '')),
                    DataCell(Text(meas.waist?.toString() ?? '')),
                    DataCell(Text(meas.hips?.toString() ?? '')),
                    DataCell(Text(meas.leg?.toString() ?? '')),
                    DataCell(Text(meas.arm?.toString() ?? '')),
                    DataCell(Text(meas.weight?.toString() ?? '')),
                    DataCell(Text(meas.fatKg?.toString() ?? '')),
                    DataCell(Text(meas.hungerStatus ?? '')),
                    DataCell(Text(meas.constipation ?? '')),
                    DataCell(Text(meas.other ?? '')),
                    DataCell(Text(meas.calorie?.toString() ?? '')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRow(meas, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRow(index),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndParseExcel() async {
    logger.info('Excel import started for userId={}', [widget.userId]);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) {
        logger.info('No file selected.');
        return;
      }

      Uint8List? fileBytes = result.files.first.bytes;
      // If bytes are null, try reading from file path
      if (fileBytes == null && result.files.first.path != null) {
        final filePath = result.files.first.path!;
        fileBytes = await File(filePath).readAsBytes();
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        logger.info('File is empty or unreadable.');
        return;
      }

      final excel = Excel.decodeBytes(fileBytes);
      final List<MeasurementModel> parsed = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        // Row 0 might be headers, so we start from row 1
        for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
          final row = sheet.rows[rowIndex];
          // Skip empty rows
          if (row.every((cell) => cell == null || cell.value == null)) continue;
          if (row.length < 13) {
            logger.info('Skipping row $rowIndex (less than 13 columns).');
            continue;
          }
          try {
            final meas = MeasurementModel(
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
            parsed.add(meas);
          } catch (e) {
            logger.err('Error parsing row $rowIndex: {}', [e.toString()]);
          }
        }
      }

      setState(() {
        _measurements.addAll(parsed);
      });

      // Show success message in Turkish
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel başarıyla içe aktarıldı.')),
      );
      logger.info('Excel import finished successfully.');
    } catch (e) {
      logger.err('Excel import failed: {}', [e.toString()]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel içe aktarma hatası: $e')),
      );
    }
  }

  // Save changes by calling the provider
  Future<void> _saveChanges() async {
    logger.info('Saving measurement changes for userId={}', [widget.userId]);
    // Set _isSaving to true and rebuild the UI
    setState(() {
      _isSaving = true;
    });
    final provider =  Provider.of<MeasProvider>(context, listen: false);
    try {
      await provider.saveChanges(widget.userId, _measurements);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ölçümler kaydedildi.')),
      );
    } catch (e) {
      logger.err('Error saving changes: {}', [e.toString()]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydetme hatası: $e')),
      );
    } finally {
      // Reset _isSaving and refresh the UI
      setState(() {
        _isSaving = false;
      });
      fetchData(); // Optionally refresh data from Firestore
    }
  }

  void _addRow() {
    setState(() {
      _measurements.add(
        MeasurementModel(date: DateTime.now()),
      );
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _measurements.removeAt(index);
    });
  }

  void _editRow(MeasurementModel measurement, int index) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMeasurementPage(measurement: measurement),
      ),
    );
    if (updated != null && updated is MeasurementModel) {
      setState(() {
        _measurements[index] = updated;
      });
    }
  }

  // -----------------------------
  // Helpers for Excel parsing
  // -----------------------------
  DateTime _parseDate(dynamic value) {
    if (value == null) throw Exception('Date is null');
    if (value is DateTime) return value; // Already DateTime
    if (value is num) {
      // Approx. offset for Excel numeric dates (1899-12-30)
      final epoch = DateTime(1899, 12, 30);
      return epoch.add(Duration(days: value.toInt()));
    }
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
}

// -------------------------------------------------------
//  EditMeasurementPage: Simple UI to edit a single entry
// -------------------------------------------------------
class EditMeasurementPage extends StatefulWidget {
  final MeasurementModel measurement;

  const EditMeasurementPage({Key? key, required this.measurement})
      : super(key: key);

  @override
  State<EditMeasurementPage> createState() => _EditMeasurementPageState();
}

class _EditMeasurementPageState extends State<EditMeasurementPage> {
  late final TextEditingController chestController;
  late final TextEditingController backController;
  late final TextEditingController waistController;
  late final TextEditingController hipsController;
  late final TextEditingController legController;
  late final TextEditingController armController;
  late final TextEditingController weightController;
  late final TextEditingController fatKgController;
  late final TextEditingController hungerStatusController;
  late final TextEditingController constipationController;
  late final TextEditingController otherController;
  late final TextEditingController calorieController;

  @override
  void initState() {
    super.initState();
    chestController =
        TextEditingController(text: widget.measurement.chest?.toString() ?? '');
    backController =
        TextEditingController(text: widget.measurement.back?.toString() ?? '');
    waistController =
        TextEditingController(text: widget.measurement.waist?.toString() ?? '');
    hipsController =
        TextEditingController(text: widget.measurement.hips?.toString() ?? '');
    legController =
        TextEditingController(text: widget.measurement.leg?.toString() ?? '');
    armController =
        TextEditingController(text: widget.measurement.arm?.toString() ?? '');
    weightController = TextEditingController(
        text: widget.measurement.weight?.toString() ?? '');
    fatKgController =
        TextEditingController(text: widget.measurement.fatKg?.toString() ?? '');
    hungerStatusController = TextEditingController(
        text: widget.measurement.hungerStatus ?? '');
    constipationController = TextEditingController(
        text: widget.measurement.constipation ?? '');
    otherController =
        TextEditingController(text: widget.measurement.other ?? '');
    calorieController = TextEditingController(
        text: widget.measurement.calorie?.toString() ?? '');
  }

  @override
  void dispose() {
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

  void _saveChanges() {
    Navigator.pop(
      context,
      MeasurementModel(
        date: widget.measurement.date,
        chest: double.tryParse(chestController.text),
        back: double.tryParse(backController.text),
        waist: double.tryParse(waistController.text),
        hips: double.tryParse(hipsController.text),
        leg: double.tryParse(legController.text),
        arm: double.tryParse(armController.text),
        weight: double.tryParse(weightController.text),
        fatKg: double.tryParse(fatKgController.text),
        hungerStatus:
        hungerStatusController.text.isNotEmpty ? hungerStatusController.text : null,
        constipation:
        constipationController.text.isNotEmpty ? constipationController.text : null,
        other: otherController.text.isNotEmpty ? otherController.text : null,
        calorie: int.tryParse(calorieController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ölçüm Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              onPressed: _saveChanges,
              child: const Text('Kaydet'),
            ),
          ],
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
