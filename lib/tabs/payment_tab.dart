import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/edit_payment_dialog.dart';
import '../providers/payment_provider.dart';
import '../models/payment_model.dart';
import 'basetab.dart';

class PaymentsTab extends BaseTab<PaymentProvider> {
  const PaymentsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'Tüm ödemeler',
    subscriptionDataLabel: 'Paket Ödemeleri',
  );

  @override
  PaymentProvider getProvider(BuildContext context) {
    final provider = Provider.of<PaymentProvider>(context, listen:false);
    return provider;
  }

  @override
  Future<List<dynamic>> getDataList(PaymentProvider provider, bool showAllData) {
    return provider.fetchPayments(null,userId:userId,showAllPayments: showAllData);
  }

  @override
  BaseTabState<PaymentProvider, BaseTab<PaymentProvider>> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends BaseTabState<PaymentProvider, PaymentsTab> {
  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<PaymentModel> payments = dataList.cast<PaymentModel>();
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        PaymentModel payment = payments[index];

        // Build the subtitle based on whether paymentDate is null
        String subtitleText = '';
        if (payment.paymentDate != null) {
          subtitleText +=
          'Ödendiği Tarih: ${payment.paymentDate!.toLocal().toString().split(' ')[0]}\n';
        }
        if (payment.dueDate != null) {
          subtitleText +=
          'Planlanan Ödeme Tarihi: ${payment.dueDate!.toLocal().toString().split(' ')[0]}';
        }

        return ListTile(
          title: Text('Miktar: ${payment.amount}'),
          subtitle: Text(subtitleText),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Durum: ${payment.status.label}'),
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
    showDialog(
      context: context,
      builder: (context) {
        return EditPaymentDialog(
          payment: payment,
          onPaymentUpdated: () {
            setState(() {
              fetchData(); // Re-fetch data when payment is updated
            });
          },
        );
      },
    );
  }
}

