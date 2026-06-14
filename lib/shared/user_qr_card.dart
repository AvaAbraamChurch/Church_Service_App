import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserQrCard extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final GlobalKey qrKey;
  final VoidCallback onToggle;

  const UserQrCard({
    super.key,
    required this.user,
    required this.isSelected,
    required this.qrKey,
    required this.onToggle,
  });

  static Future<Uint8List> capture(GlobalKey key, String uid, String shortId) async {
    const double qrSize = 300;
    const double fontSize = 36;
    const double padding = 16;
    const double totalHeight = qrSize + fontSize + padding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw QR code
    final painter = QrPainter(
      data: shortId,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: ui.Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: ui.Color(0xFF000000),
      ),
    );
    painter.paint(canvas, const ui.Size(qrSize, qrSize));

    // Draw shortId label below QR
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: fontSize,
        fontWeight: ui.FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: const ui.Color(0xFF000000),
        fontSize: fontSize,
        fontWeight: ui.FontWeight.bold,
      ))
      ..addText(shortId);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: qrSize));

    canvas.drawParagraph(
      paragraph,
      ui.Offset(0, qrSize + padding),
    );

    // Encode to PNG
    final picture = recorder.endRecording();
    final img = await picture.toImage(qrSize.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) throw Exception('Failed to encode QR to PNG');
    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              RepaintBoundary(
                key: qrKey,
                child: QrImageView(
                  data: user.id,
                  version: QrVersions.auto,
                  size: 100,
                  // No backgroundColor → transparent PNG
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,

                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.shortId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}