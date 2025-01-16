import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diet_model.dart';
import '../providers/diet_provider.dart';
import 'basetab.dart';

class DietTab extends BaseTab<DietProvider> {
  const DietTab({super.key, required super.userId})
      : super(
    allDataLabel: 'Tüm diyetler',
    subscriptionDataLabel: 'Paket Diyetleri',
  );

  @override
  DietProvider getProvider(BuildContext context) {
    final provider = Provider.of<DietProvider>(context, listen: false);
    provider.setUserId(userId);
    return provider;
  }

  @override
  Future<List<dynamic>> getDataList(DietProvider provider, bool showAllData) {
    return provider.fetchDiets(showAllData: showAllData);
  }

  @override
  BaseTabState<DietProvider, BaseTab<DietProvider>> createState() => _DietTabState();
}

class _DietTabState extends BaseTabState<DietProvider, DietTab> {
  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    final diets = dataList.cast<DietDocument>();

    return ListView.builder(
      itemCount: diets.length,
      itemBuilder: (context, index) {
        final dietDoc = diets[index];

        return ListTile(
          title: Text(dietDoc.displayName),
          subtitle: Text(dietDoc.uploadTime?.toString() ?? 'Zaman bilgisi yok'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DietDetailsPage(dietDoc: dietDoc),
              ),
            );
          },
          // DELETE ICON
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await _confirmDeletion(context, dietDoc.displayName);
              if (confirmed == true) {
                await Provider.of<DietProvider>(context, listen: false)
                    .deleteDiet(dietDoc.docId);
                setState(() {
                  fetchData(); // re-fetch list
                });
              }
            },
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, String dietName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diyet Sil'),
        content: Text('$dietName silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
        ],
      ),
    );
  }
}


class DietDetailsPage extends StatelessWidget {
  final DietDocument dietDoc;
  const DietDetailsPage({super.key, required this.dietDoc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dietDoc.displayName),
      ),
      body: ListView.builder(
        itemCount: dietDoc.subtitles.length,
        itemBuilder: (context, index) {
          final sub = dietDoc.subtitles[index] as Map<String, dynamic>;
          final name = sub['name'] ?? '';
          final time = sub['time'] ?? '';
          final contentList = (sub['content'] as List?) ?? [];

          return Card(
            child: ListTile(
              title: Text('$name  ($time)'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: contentList.map((c) {
                  final line = (c as Map)['content'] ?? '';
                  return Text('- $line');
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
