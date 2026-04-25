import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Uploads images to Cloudinary using an unsigned upload preset.
class CloudinaryUploadService {
  static const int _maxFileSizeInBytes = 5 * 1024 * 1024;
  static const Duration _uploadTimeout = Duration(seconds: 30);

  final ImagePicker _picker;
  final http.Client _httpClient;

  CloudinaryUploadService({ImagePicker? picker, http.Client? httpClient})
    : _picker = picker ?? ImagePicker(),
      _httpClient = httpClient ?? http.Client();

  String get _cloudName =>
      const String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  String get _uploadPreset =>
      const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  String get _folder => const String.fromEnvironment(
    'CLOUDINARY_UPLOAD_FOLDER',
    defaultValue: 'church_store',
  );

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  String get _baseFolder => _folder.trim();

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<XFile?> pickImageFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
  }

  /// Pick a profile image: smaller dimensions, higher compression than product images.
  Future<XFile?> pickProfileImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
  }

  // ── Upload helpers ────────────────────────────────────────────────────────

  Future<String> uploadProductImage(XFile image) async {
    return _uploadImageBytes(
      bytes: await image.readAsBytes(),
      filename: image.name.isEmpty ? 'product_image.jpg' : image.name,
      folder: _baseFolder,
    );
  }

  Future<String> uploadCompetitionImage(File imageFile) {
    final imageName = imageFile.path.split(Platform.pathSeparator).last;
    return uploadImageFile(
      imageFile,
      folder: '$_baseFolder/competitions',
      fileName: imageName.isEmpty ? 'competition_image.jpg' : imageName,
    );
  }

  /// Upload a user profile photo.
  ///
  /// [userId] is used as the public ID so repeated uploads overwrite the
  /// previous image instead of creating orphaned files.
  Future<String> uploadProfileImage(File imageFile, String userId) {
    return _uploadImageBytes(
      bytes: imageFile.readAsBytesSync(),
      filename: 'profile_$userId.jpg',
      folder: '$_baseFolder/profiles',
      publicId: 'profiles/profile_$userId',
    );
  }

  Future<String> uploadImageFile(
    File imageFile, {
    String? folder,
    String? fileName,
  }) async {
    return _uploadImageBytes(
      bytes: await imageFile.readAsBytes(),
      filename: fileName ?? imageFile.path.split(Platform.pathSeparator).last,
      folder: folder ?? _baseFolder,
    );
  }

  // ── Core upload ───────────────────────────────────────────────────────────

  Future<String> _uploadImageBytes({
    required List<int> bytes,
    required String filename,
    required String folder,
    String? publicId,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary is not configured. '
        'Pass CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET via --dart-define.',
      );
    }

    if (bytes.length > _maxFileSizeInBytes) {
      throw Exception('Image must be 5 MB or smaller.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename.isEmpty ? 'image.jpg' : filename,
        ),
      );

    // Setting public_id lets Cloudinary overwrite the previous file on
    // re-upload (e.g. when a user updates their profile photo).
    if (publicId != null && publicId.isNotEmpty) {
      request.fields['public_id'] = publicId;
    }

    final response = await _httpClient.send(request).timeout(_uploadTimeout);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(responseBody);
      throw Exception('Cloudinary upload failed: $errorMessage');
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return a secure_url.');
    }

    return secureUrl;
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Keep a generic fallback for non-JSON responses.
    }

    return 'unexpected response from Cloudinary';
  }
}
