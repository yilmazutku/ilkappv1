// dialogs/add_image_dialog.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/logger.dart';
import '../models/meal_model.dart';
import '../providers/image_manager.dart';
import '../providers/meal_state_and_upload_manager.dart';

class AddImageDialog extends StatefulWidget {
  final String userId;
  final String subscriptionId;
  final VoidCallback onImageAdded;

  const AddImageDialog({
    super.key,
    required this.userId,
    required this.subscriptionId,
    required this.onImageAdded,
  });

  @override
   createState() => _AddImageDialogState();
}

class _AddImageDialogState extends State<AddImageDialog> {
  final Logger logger = Logger.forClass(AddImageDialog);
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Meals? _selectedMeal;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    const mealOptions = Meals.values;

    return AlertDialog(
      title: const Text('Add Meal Image'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<Meals>(
              value: _selectedMeal,
              hint: const Text('Select Meal Type'),
              onChanged: (Meals? newValue) {
                setState(() {
                  _selectedMeal = newValue;
                });
              },
              items: mealOptions.map((Meals meal) {
                return DropdownMenuItem<Meals>(
                  value: meal,
                  child: Text(meal.label),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            _selectedImage != null
                ? Image.file(
              File(_selectedImage!.path),
              height: 100,
            )
                : const Text('No image selected'),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadImage,
          child: _isUploading
              ? const CircularProgressIndicator()
              : const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
      await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      logger.err('Error picking image: $e');
      setState(() {
        _errorMessage = 'Error picking image.';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedMeal == null) {
      setState(() {
        _errorMessage = 'Please select a meal type.';
      });
      return;
    }

    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final imageManager = Provider.of<ImageManager>(context, listen: false);

      final result = await imageManager.uploadFile(
        File(_selectedImage!.path),
        meal: _selectedMeal!,
        userId: widget.userId,
      );

      if (result.isUploadOk && result.downloadUrl != null) {
        // Save the meal image information to Firestore
        final mealDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('meals')
            .doc(); // Generate a new meal ID

        MealModel mealModel = MealModel(
          mealId: mealDocRef.id,
          mealType: _selectedMeal!,
          imageUrl: result.downloadUrl!,
          subscriptionId: widget.subscriptionId,
          timestamp: DateTime.now(),
          description: null,
          calories: null,
          notes: null,
        );

        await mealDocRef.set(mealModel.toMap());

        // Update meal checked state
        Provider.of<MealStateManager>(context, listen: false)
            .setMealCheckedState(_selectedMeal!, true);

        // Notify parent widget to refresh data
        widget.onImageAdded();

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully.')),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Error uploading image.';
        });
      }
    } catch (e) {
      logger.err('Error uploading image: $e');
      setState(() {
        _errorMessage = 'Error uploading image.';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
