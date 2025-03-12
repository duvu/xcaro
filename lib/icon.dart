import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

void main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = 512.0; // Kích thước icon 512x512

  // Vẽ nền
  final bgPaint = Paint()..color = Colors.white;
  canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);

  // Vẽ X và O
  final xPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 40;

  final oPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 40;

  // Vẽ X
  canvas.drawLine(
    Offset(size * 0.3, size * 0.3),
    Offset(size * 0.7, size * 0.7),
    xPaint,
  );
  canvas.drawLine(
    Offset(size * 0.7, size * 0.3),
    Offset(size * 0.3, size * 0.7),
    xPaint,
  );

  // Vẽ O
  canvas.drawCircle(
    Offset(size * 0.5, size * 0.5),
    size * 0.25,
    oPaint,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

  // Lưu file
  if (bytes != null) {
    final buffer = bytes.buffer;
    final imgData =
        buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    final file = File('assets/icon/icon.png');
    await file.writeAsBytes(imgData);
    print('Icon saved successfully!');
  } else {
    print('Failed to generate icon bytes');
  }
}
