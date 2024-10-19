// tabs/payments_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import 'basetab.dart';

class PaymentsTab extends BaseTab<PaymentProvider> {
  const PaymentsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Payments',
    subscriptionDataLabel: 'Subscription Payments',
  );

  @override
  PaymentProvider getProvider(BuildContext context) {
    return Provider.of<PaymentProvider>(context);
  }

  @override
  List<PaymentModel> getDataList(PaymentProvider provider) {
    return provider.payments;
  }

  @override
  bool getShowAllData(PaymentProvider provider) {
    return provider.showAllPayments;
  }

  @override
  void setShowAllData(PaymentProvider provider, bool value) {
    provider.setShowAllPayments(value);
  }

  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<PaymentModel> payments = dataList.cast<PaymentModel>();
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        PaymentModel payment = payments[index];
        return ListTile(
          title: Text('Amount: ${payment.amount}'),
          subtitle: Text(
              'Payment Date: ${payment.paymentDate.toLocal().toString().split(' ')[0]}\nDue Date: ${payment.dueDate?.toLocal().toString().split(' ')[0] ?? '-'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${payment.status}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditPaymentDialog(context, payment);
                },
              ),
            ],
          ),
          onTap: () {
            // Handle onTap if necessary
          },
        );
      },
    );
  }

  void _showEditPaymentDialog(BuildContext context, PaymentModel payment) {
    // Implement your edit payment dialog
  }
}
