// tabs/images_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../commons/userclass.dart';
import '../managers/meal_state_and_upload_manager.dart';
import 'basetab.dart';

class ImagesTab extends BaseTab<MealStateManager> {
  const ImagesTab({super.key, required super.userId})
      : super(
    allDataLabel: 'All Images',
    subscriptionDataLabel: 'Subscription Images',
  );

  @override
  MealStateManager getProvider(BuildContext context) {
    return Provider.of<MealStateManager>(context);
  }

  @override
  List<MealModel> getDataList(MealStateManager provider) {
    return provider.meals;
  }

  @override
  bool getShowAllData(MealStateManager provider) {
    return provider.showAllImages;
  }

  @override
  void setShowAllData(MealStateManager provider, bool value) {
    provider.setShowAllImages(value);
  }

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

  void _showFullImage(BuildContext context, String imageUrl, MealModel meal) {
    // Implement your image viewer dialog
  }
}
