import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import '../models/logger.dart';

final Logger logger = Logger.forClass(UserPaymentsPage);

class UserPaymentsPage extends StatefulWidget {
  final String userId;

  const UserPaymentsPage({Key? key, required this.userId}) : super(key: key);

  @override
  createState() => _UserPaymentsPageState();
}

class _UserPaymentsPageState extends State<UserPaymentsPage> {
  late Future<List<PaymentModel>> _paymentsFuture;
  List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoading = false;

  // Filters
  PaymentStatus? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  bool _isDateAscending = true;

  @override
  void initState() {
    super.initState();
    logger.info('Initializing UserPaymentsPage state.');
    _fetchUserPayments();
  }

  void _fetchUserPayments() {
    setState(() {
      _isLoading = true;
    });
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.setUserId(widget.userId);
    paymentProvider.fetchPayments(showAllPayments: true).then((payments) {
      setState(() {
        _allPayments = payments;
        _applyFilters();
        _isLoading = false;
      });
      logger.info('Fetched ${payments.length} payments for user ${widget.userId}.');
    }).catchError((error, stackTrace) {
      logger.err('Error fetching payments: {}', [error]);
      logger.err('Stack trace: {}', [stackTrace]);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödemeler alınırken bir hata oluştu.')),
        );
      }
    });
  }

  void _applyFilters() {
    List<PaymentModel> filtered = List.from(_allPayments);

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((payment) => payment.status == _selectedStatus).toList();
    }

    // Apply date filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((payment) {
        DateTime? date = payment.dueDate;
        if (date == null) return false;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      DateTime dateA = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      DateTime dateB = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (_isDateAscending) {
        return dateA.compareTo(dateB);
      } else {
        return dateB.compareTo(dateA);
      }
    });

    setState(() {
      _filteredPayments = filtered;
    });
    logger.info('Applied filters. Total payments after filtering: ${_filteredPayments.length}.');
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDateRange = null;
      _isDateAscending = true;
    });
    _applyFilters();
    logger.info('Cleared all filters.');
  }

  void _showFilterDialog() {
    PaymentStatus? tempStatus = _selectedStatus;
    DateTimeRange? tempDateRange = _selectedDateRange;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrele'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PaymentStatus>(
                  value: tempStatus,
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                  ),
                  items: PaymentStatus.values.map((PaymentStatus status) {
                    return DropdownMenuItem<PaymentStatus>(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (PaymentStatus? newValue) {
                    tempStatus = newValue;
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: tempDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 30)),
                            end: DateTime.now(),
                          ),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('tr', 'TR'),
                    );
                    if (picked != null) {
                      setState(() {
                        tempDateRange = picked;
                      });
                    }
                  },
                  child: Text(
                    tempDateRange == null
                        ? 'Tarih Seçiniz'
                        : 'Seçilen Tarih: ${DateFormat('dd.MM.yyyy').format(tempDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(tempDateRange!.end)}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Uygula'),
              onPressed: () {
                setState(() {
                  _selectedStatus = tempStatus;
                  _selectedDateRange = tempDateRange;
                });
                _applyFilters();
                Navigator.of(context).pop();
                logger.info('Applied new filters.');
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleDateSorting() {
    setState(() {
      _isDateAscending = !_isDateAscending;
    });
    _applyFilters();
    logger.info('Toggled date sorting. Now ascending: $_isDateAscending.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    logger.info('Building UserPaymentsPage UI.');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(_isDateAscending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: _toggleDateSorting,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedStatus != null || _selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (_selectedStatus != null)
                    Chip(
                      label: Text('Durum: ${_selectedStatus!.label}'),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                        _applyFilters();
                        logger.info('Removed status filter.');
                      },
                    ),
                  if (_selectedDateRange != null)
                    Chip(
                      label: Text(
                          'Tarih: ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}'),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                        _applyFilters();
                        logger.info('Removed date range filter.');
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Filtreleri Temizle'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                ? const Center(
              child: Text(
                'Henüz bir ödemeniz bulunmuyor.',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              itemCount: _filteredPayments.length,
              itemBuilder: (context, index) {
                PaymentModel payment = _filteredPayments[index];
                Color statusColor;
                if (payment.status == PaymentStatus.completed) {
                  statusColor = Colors.green;
                } else if (payment.status == PaymentStatus.planned) {
                  statusColor = Colors.orange;
                } else {
                  statusColor = Colors.red;
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.payment,
                        color: theme.primaryColor,
                        size: 40,
                      ),
                      title: Text(
                        'Miktar: ${payment.amount.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            'Planlanan Ödeme Tarihi: ${_formatDate(payment.dueDate)}',
                          ),
                          Text(
                            'Ödendiği Tarih: ${_formatDate(payment.paymentDate)}',
                          ),
                        ],
                      ),
                      trailing: Text(
                        payment.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // Handle tap if needed
                       // logger.info('Payment item tapped: ${payment.paymentId}');
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
  }
}
