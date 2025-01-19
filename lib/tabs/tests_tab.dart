import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_model.dart';
import '../providers/test_provider.dart';
import 'basetab.dart';

class TestsTab extends BaseTab<TestProvider> {
  const TestsTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Tests',
    subscriptionDataLabel: 'Subscription Tests',
  );

  @override
  TestProvider getProvider(BuildContext context) {

    return Provider.of<TestProvider>(context);
  }

  @override
  Future<List<dynamic>> getDataList(TestProvider provider, bool showAllData) {
    return provider.fetchTests(); //hep tum testleri döner
  }

  @override
  BaseTabState<TestProvider, BaseTab<TestProvider>> createState() => _TestsTabState();
}

class _TestsTabState extends BaseTabState<TestProvider, TestsTab> {
  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<TestModel> tests = dataList.cast<TestModel>();
    return ListView.builder(
      itemCount: tests.length,
      itemBuilder: (context, index) {
        TestModel test = tests[index];
        return ListTile(
          title: Text('Test Name: ${test.testName}'),
          subtitle: Text('Date: ${test.testDate.toLocal().toString().split(' ')[0]}'),
        );
      },
    );
  }
}
