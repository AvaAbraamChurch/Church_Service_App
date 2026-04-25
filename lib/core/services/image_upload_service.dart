import 'dart:io';
import 'package:church/core/services/cloudinary_upload_service.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final CloudinaryUploadService _cloudinary = CloudinaryUploadService();
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

  /// Upload profile image to Cloudinary
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final downloadUrl = await _cloudinary.uploadProfileImage(imageFile, userId);
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: \$e');
    }
  }

  /// Delete profile image — handled server-side via Cloudinary.
  /// No-op on the client; pass the public_id to your backend if needed.
  Future<void> deleteProfileImage(String userId) async {
    // Cloudinary deletion should be handled server-side.
    // Nothing to do here on the client.
  }
}

