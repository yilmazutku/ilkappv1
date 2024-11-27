// user_payments_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';

class UserPaymentsPage extends StatefulWidget {
  final String userId;

  const UserPaymentsPage({super.key, required this.userId});

  @override
   createState() => _UserPaymentsPageState();
}

class _UserPaymentsPageState extends State<UserPaymentsPage> {
  late Future<List<PaymentModel>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserPayments();
  }

  void _fetchUserPayments() {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.setUserId(widget.userId);
    _paymentsFuture = paymentProvider.fetchPayments(showAllPayments: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemelerim'),
      ),
      body: FutureBuilder<List<PaymentModel>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Ödemeler yüklenirken bir hata oluştu: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Henüz bir ödemeniz bulunmuyor.'),
            );
          } else {
            List<PaymentModel> payments = snapshot.data!;
            return ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                PaymentModel payment = payments[index];
                return ListTile(
                  title: Text('Miktar: ${payment.amount} ₺'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planlanan Ödeme Tarihi: ${_formatDate(payment.dueDate)}'),
                      Text('Ödendiği Tarih: ${_formatDate(payment.paymentDate)}'),
                    ],
                  ),
                  trailing: Text(
                    payment.status.label,
                    style: TextStyle(
                      color: payment.status==PaymentStatus.completed ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }
}
