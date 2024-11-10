import 'package:flutter/material.dart';

abstract class BaseTab<T> extends StatefulWidget {
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

  Future<List<dynamic>> getDataList(T provider, bool showAllData);

  @override
  BaseTabState<T, BaseTab<T>> createState();
}

abstract class BaseTabState<T, W extends BaseTab<T>> extends State<W> {
  bool showAllData = false;
  Future<List<dynamic>>? dataFuture;

  @override
  void initState() {
    super.initState();
   // fetchData();
    //   // Avoid calling fetchData or similar logic here if it depends on Provider
  }

  bool _dataFetched = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataFetched) {
      fetchData();
      _dataFetched = true;
    }
  }

  void fetchData() {
    final provider = widget.getProvider(context);
    dataFuture = widget.getDataList(provider, showAllData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(showAllData ? widget.allDataLabel : widget.subscriptionDataLabel),
            Switch(
              value: showAllData,
              onChanged: (value) {
                setState(() {
                  showAllData = value;
                  fetchData();
                });
              },
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error fetching data: ${snapshot.error}'));
              } else {
                final dataList = snapshot.data ?? [];
                if (dataList.isEmpty) {
                  return const Center(child: Text('No data found.'));
                }
                return buildList(context, dataList);
              }
            },
          ),
        ),
      ],
    );
  }

  // Abstract method
  Widget buildList(BuildContext context, List<dynamic> dataList);
}
