import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Maximum file size: 2 MB
  static const int maxFileSizeInBytes = 2 * 1024 * 1024;

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Validate image file size
  bool validateImageSize(File imageFile) {
    final fileSize = imageFile.lengthSync();
    return fileSize <= maxFileSizeInBytes;
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Upload image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Create a reference to the location where we want to upload the file
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');

      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete profile image from Firebase Storage
  Future<void> deleteProfileImage(String userId) async {
    try {
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');
      await storageRef.delete();
    } catch (e) {
      // Image might not exist, which is fine
      throw Exception('Failed to delete image: $e');
    }
  }
}

