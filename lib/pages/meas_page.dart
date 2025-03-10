import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/meas_model.dart';
import '../providers/meas_provider.dart';

class MeasurementPage extends StatefulWidget {
  final String userId;
  const MeasurementPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  List<MeasurementModel> _measurements = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final provider = Provider.of<MeasProvider>(context, listen: false);
    final data = await provider.fetchMeasurements(widget.userId);
    setState(() {
      _measurements = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mevcut Ölçümler')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _measurements.isEmpty
          ? const Center(child: Text('Henüz ölçüm bulunmuyor.'))
          : SingleChildScrollView(
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
            ],
            rows: _measurements.map((m) {
              return DataRow(cells: [
                DataCell(Text(_dateFormat.format(m.date))),
                DataCell(Text(m.chest?.toString() ?? '')),
                DataCell(Text(m.back?.toString() ?? '')),
                DataCell(Text(m.waist?.toString() ?? '')),
                DataCell(Text(m.hips?.toString() ?? '')),
                DataCell(Text(m.leg?.toString() ?? '')),
                DataCell(Text(m.arm?.toString() ?? '')),
                DataCell(Text(m.weight?.toString() ?? '')),
                DataCell(Text(m.fatKg?.toString() ?? '')),
                DataCell(Text(m.hungerStatus ?? '')),
                DataCell(Text(m.constipation ?? '')),
                DataCell(Text(m.other ?? '')),
                DataCell(Text(m.calorie?.toString() ?? '')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
