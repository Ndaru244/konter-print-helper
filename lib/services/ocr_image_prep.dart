import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// File yang dibaca ML Kit. [temporary] artinya salinan yang harus dihapus
/// setelah `processImage` selesai.
class OcrPreparedImage {
  const OcrPreparedImage({required this.path, required this.temporary});

  final String path;
  final bool temporary;
}

class OcrImagePrep {
  static const maxWidth = 1280;

  /// Downscale jika lebar piksel lebih dari [maxWidth]. Lebih kecil dipakai
  /// apa adanya supaya screenshot HP biasa tidak di-encode ulang.
  static Future<OcrPreparedImage> prepare(
    String sourcePath, {
    int maxWidth = OcrImagePrep.maxWidth,
  }) async {
    File? temp;
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
      } catch (_) {
        buffer.dispose();
        rethrow;
      }
      try {
        final width = descriptor.width;
        if (width <= 0 || width <= maxWidth) {
          return OcrPreparedImage(path: sourcePath, temporary: false);
        }
        final codec = await descriptor.instantiateCodec(targetWidth: maxWidth);
        try {
          final frame = await codec.getNextFrame();
          final image = frame.image;
          try {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            if (png == null) {
              return OcrPreparedImage(path: sourcePath, temporary: false);
            }
            temp = File(
              '${Directory.systemTemp.path}/konter_ocr_${DateTime.now().microsecondsSinceEpoch}.png',
            );
            await temp.writeAsBytes(
              png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
              flush: true,
            );
            return OcrPreparedImage(path: temp.path, temporary: true);
          } finally {
            image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
        buffer.dispose();
      }
    } catch (e) {
      final leftover = temp;
      if (leftover != null) {
        try {
          await leftover.delete();
        } catch (_) {}
      }
      debugPrint('OCR resize dilewati: $e');
      return OcrPreparedImage(path: sourcePath, temporary: false);
    }
  }
}
