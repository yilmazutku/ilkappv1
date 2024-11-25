import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/edit_sub_dialog.dart';
import '../models/subs_model.dart';
import '../providers/user_provider.dart';
import 'basetab.dart';

class SubscriptionsTab extends BaseTab<UserProvider> {
  const SubscriptionsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Subscriptions',
    subscriptionDataLabel: 'Active Subscriptions',
  );

  @override
  UserProvider getProvider(BuildContext context) {
    final provider = Provider.of<UserProvider>(context,listen: false);
    provider.setUserId(userId);
    return provider;
  }

  @override
  Future<List<dynamic>> getDataList(UserProvider provider, bool showAllData) {
    return provider.fetchSubscriptions(showAllSubscriptions: showAllData);
  }

  @override
  BaseTabState<UserProvider, BaseTab<UserProvider>> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends BaseTabState<UserProvider, SubscriptionsTab> {
  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<SubscriptionModel> subscriptions = dataList.cast<SubscriptionModel>();
    return ListView.builder(
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        SubscriptionModel subscription = subscriptions[index];
        return ListTile(
          title: Text(subscription.packageName),
          subtitle: Text(
              'Start Date: ${subscription.startDate.toLocal().toString().split(' ')[0]}\n'
                  'End Date: ${subscription.endDate.toLocal().toString().split(' ')[0]}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${subscription.status.label}'),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditSubscriptionDialog(context, subscription);
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

  void _showEditSubscriptionDialog(
      BuildContext context, SubscriptionModel subscription) {
    showDialog(
      context: context,
      builder: (context) {
        return EditSubscriptionDialog(
          subscription: subscription,
          onSubscriptionUpdated: () {
            Provider.of<UserProvider>(context, listen: false).fetchSubscriptions(showAllSubscriptions: showAllData);
          },
        );
      },
    );
  }
}

