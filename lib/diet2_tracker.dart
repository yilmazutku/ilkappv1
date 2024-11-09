import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DailyPage(),
    );
  }
}

class DailyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GÜNLÜK"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "03.02.2020",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Pazartesi",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            MealSection(
              title: "AKŞAM YEMEĞİ",
              items: [
                "200 gr ızgara/fırında kırmızı et / beyaz et",
                "4 yemek kaşığı bulgur pilavı YA DA 1 dilim tam buğday ekmeği",
                "Renkli mevsim salata (bol limonlu)",
                "1 dilim ekmek",
              ],
            ),
            SizedBox(height: 16),
            MealSection(
              title: "ARA ÖĞÜN 3",
              items: [
                "1 bardak altın süt",
              ],
            ),
            SizedBox(height: 16),
            Text(
              "SU TÜKETİMİ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: 1000,
              min: 1000,
              max: 2200,
              divisions: 12,
              label: "1000 mL",
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}

class MealSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const MealSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...items.map((item) {
              return ListTile(
                leading: Icon(Icons.check_circle, color: Colors.orange),
                title: Text(item),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
