import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../commons/common.dart';
// Manages the state of the current folder path.
// Handles fetching of folder names and images.
// Provides methods for navigation (navigateToFolder and navigateBack).
class AdminImagesProvider extends ChangeNotifier {
  List<String> folders = [];
  List<String> newImageUrls = [];
  ViewType currentView = ViewType.list;
  String currentFolder = 'users';
  List<String> folderStack = ['users'];

  Future<void> fetchUserFolderNames() async {
    final ref = FirebaseStorage.instance.ref(currentFolder);
    final ListResult result = await ref.listAll();
    folders = result.prefixes.map((folderRef) => folderRef.name).toList();
    newImageUrls = await _fetchImages(result.items);
    notifyListeners();
  }

  Future<List<String>> _fetchImages(List<Reference> items) async {
    List<String> imageUrls = [];
    for (var fileRef in items) {
      final url = await fileRef.getDownloadURL();
      imageUrls.add(url);
    }
    return imageUrls;
  }

  void navigateToFolder(String folderName) {
    currentFolder = '$currentFolder/$folderName';
    folderStack.add(folderName);
    fetchUserFolderNames();
  }

  void navigateBack() {
    if (folderStack.length > 1) {
      folderStack.removeLast();
      currentFolder = folderStack.join('/');
      fetchUserFolderNames();
    }
  }

  void toggleView() {
    currentView = currentView == ViewType.list ? ViewType.grid : ViewType.list;
    notifyListeners();
  }
}
