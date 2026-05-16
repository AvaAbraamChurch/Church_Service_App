import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/widgets.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/shared/user_qr_card.dart';
import 'package:path_provider/path_provider.dart';

class QrExportService {
  static String _safeName(String name) =>
      name.trim().replaceAll(RegExp(r'[^\w]+'), '_').toLowerCase();

  static String filenameFor(UserModel user) {
    final name = _safeName(user.fullName);
    return '${name}_${user.id}';  // no extension — FileSaver adds it
  }

  static Future<void> exportSingle(GlobalKey qrKey, UserModel user) async {
    final bytes = await UserQrCard.capture(qrKey, user.id, user.shortId);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${filenameFor(user)}');
    await file.writeAsBytes(bytes);

    await FileSaver.instance.saveFile(
      name: filenameFor(user),
      bytes: bytes,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );
  }

  static Future<void> exportZip(Map<UserModel, GlobalKey> selectedKeys) async {
    final archive = Archive();

    for (final entry in selectedKeys.entries) {
      final user = entry.key;
      final bytes = await UserQrCard.capture(
        entry.value,
        user.id,
        user.shortId,  // fallback if shortId not yet migrated
      );
      final filename = '${filenameFor(user)}.png';
      archive.addFile(ArchiveFile(filename, bytes.length, bytes));
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    await FileSaver.instance.saveFile(
      name: 'qr_codes',
      bytes: zipBytes,
      fileExtension: 'zip',
      mimeType: MimeType.zip,
    );
  }
}