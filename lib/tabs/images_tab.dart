// tabs/images_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/meal_state_and_upload_manager.dart';
import 'basetab.dart';

class ImagesTab extends BaseTab<MealStateManager> {
  const ImagesTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Images',
    subscriptionDataLabel: 'Subscription Images',
  );

  @override
  MealStateManager getProvider(BuildContext context) {
    final provider = Provider.of<MealStateManager>(context,listen: false);
    return provider;
  }

  @override
  Future<List<dynamic>> getDataList(MealStateManager provider, bool showAllData) {
    return provider.fetchMeals(null,userId:userId,showAllImages: showAllData);
  }

  @override
   createState() => _ImagesTabState();
}

class _ImagesTabState extends BaseTabState<MealStateManager, ImagesTab> {
  @override
  Widget buildList(BuildContext context, List<dynamic> dataList) {
    List<MealModel> meals = dataList.cast<MealModel>();
    return GridView.builder(
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
            _showFullImage(context, meal.imageUrl, meal);
          },
          child: Image.network(
            meal.imageUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl, MealModel meal) { //TODO
    // Implement your image viewer dialog
    // You can call setState here if needed
  }
}
