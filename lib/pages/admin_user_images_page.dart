
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/managers/admin_images_manager.dart';

import '../commons/common.dart';

/// Admin Images Page kullanır, bir kullanıcının fotoğraflarını görmek için klasör halinde.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../commons/userclass.dart';

class UserImagesPage extends StatefulWidget {
  final String userId;

  const UserImagesPage({super.key, required this.userId});

  @override
  _UserImagesPageState createState() => _UserImagesPageState();
}

class _UserImagesPageState extends State<UserImagesPage> {
  List<MealModel> meals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserMeals();
  }

  Future<void> fetchUserMeals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('meals')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        meals = snapshot.docs.map((doc) => MealModel.fromDocument(doc)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user meals: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<UserModel?> fetchUserDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: fetchUserDetails(),
      builder: (context, userSnapshot) {
        String title = 'User Images';
        if (userSnapshot.hasData) {
          title = '${userSnapshot.data!.name}\'s Images';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : meals.isEmpty
              ? const Center(child: Text('No images found.'))
              : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              MealModel meal = meals[index];
              return InkWell(
                onTap: () {
                  showFullImage(context, meal.imageUrl, meal);
                },
                child: Image.network(
                  meal.imageUrl,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showFullImage(BuildContext context, String imageUrl, MealModel meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(imageUrl),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Meal Type: ${meal.mealType.label}\n'
                      'Timestamp: ${meal.timestamp}\n'
                      'Description: ${meal.description ?? 'N/A'}',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}