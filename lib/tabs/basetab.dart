// tabs/base_tab.dart
// managers/loadable.dart
import 'package:flutter/material.dart';
mixin Loadable {
  bool get isLoading;
}



abstract class BaseTab<T extends Loadable> extends StatelessWidget {
  final String userId;
  final String allDataLabel;
  final String subscriptionDataLabel;

  const BaseTab({
    super.key,
    required this.userId,
    required this.allDataLabel,
    required this.subscriptionDataLabel,
  });

  T getProvider(BuildContext context);

  List<dynamic> getDataList(T provider);

  Widget buildList(BuildContext context, List<dynamic> dataList);

  bool getShowAllData(T provider);

  void setShowAllData(T provider, bool value);

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dataList = getDataList(provider);

    return Column(
      children: [
        // Toggle Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(getShowAllData(provider) ? allDataLabel : subscriptionDataLabel),
            Switch(
              value: getShowAllData(provider),
              onChanged: (value) {
                setShowAllData(provider, value);
              },
            ),
          ],
        ),
        Expanded(
          child: dataList.isEmpty
              ? const Center(child: Text('No data found.'))
              : buildList(context, dataList),
        ),
      ],
    );
  }
}
