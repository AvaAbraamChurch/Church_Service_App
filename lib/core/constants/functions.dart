
// Future<String> pickImage() async {
//   try {
//     // Use FilePicker to pick the image file
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image, // Only allow image files
//     );
//
//     if (result != null) {
//       // Get the file path
//       String? filePath = result.files.single.path;
//
//       if (filePath != null) {
//         // print("Selected image file: $filePath");
//         return filePath;
//       }
//     } else {
//       // User canceled the picker
//       print("Image selection canceled.");
//     }
//   } catch (e) {
//     print("Error picking image: $e");
//   }
//   return '';
// }
//
// Future<String> pickImages() async {
//   try {
//     // Use FilePicker to pick the images files
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image, // Only allow image files
//       allowMultiple: true, // Allow multiple selection
//     );
//     if (result != null) {
//       // Get the file paths
//       List<String> filePaths = result.paths.whereType<String>().toList();
//
//       if (filePaths.isNotEmpty) {
//         // Return comma-separated string instead of JSON
//         return filePaths.join(',');
//       }
//     } else {
//       // User canceled the picker
//       print("Image selection canceled.");
//     }
//   } catch (e) {
//     print("Error picking images: $e");
//   }
//   return '';
// }



String normalizeArabic(String input) {
  return input
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ئ', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '');
}
