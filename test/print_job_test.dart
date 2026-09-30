import 'dart:io';
import 'dart:ui' as ui;

import 'package:cetak_struk/services/ocr_image_prep.dart';
import 'package:cetak_struk/services/printer_service.dart';
import 'package:cetak_struk/services/receipt_print.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('baris size dan align sama digabung jadi satu payload', () {
    final batches = batchPrintLines(const [
      ReceiptPrintLine('TOKO', 2, 1),
      ReceiptPrintLine('a', 1, 0),
      ReceiptPrintLine('b', 1, 0),
      ReceiptPrintLine('kanan', 1, 2),
    ]);

    expect(batches, hasLength(3));
    expect(batches[0].text, 'TOKO');
    expect(batches[0].sourceLines, 1);
    expect(batches[1].text, 'a\nb');
    expect(batches[1].size, 1);
    expect(batches[1].align, 0);
    expect(batches[1].sourceLines, 2);
    expect(batches[2].text, 'kanan');
    expect(batches[2].align, 2);
  });

  test('pesan gagal cetak menyebut baris yang sudah terkirim', () {
    final error = PrintJobException(
      sentLines: 2,
      totalLines: 5,
      cause: 'write_error',
    );
    expect(error.message, contains('mulai baris 3 dari 5'));
    expect(error.message, contains('write_error'));
  });

  test(
    'gambar lebih lebar dari 1280 di-resize, yang lebih kecil tidak',
    () async {
      final wide = await _png(width: 2000, height: 40);
      final narrow = await _png(width: 800, height: 40);
      addTearDown(() async {
        if (wide.existsSync()) await wide.delete();
        if (narrow.existsSync()) await narrow.delete();
      });

      final scaled = await OcrImagePrep.prepare(wide.path);
      addTearDown(() async {
        if (scaled.temporary) {
          final copy = File(scaled.path);
          if (copy.existsSync()) await copy.delete();
        }
      });
      expect(scaled.temporary, isTrue);
      expect(scaled.path, isNot(wide.path));
      expect(await _widthOf(scaled.path), 1280);

      final kept = await OcrImagePrep.prepare(narrow.path);
      expect(kept.temporary, isFalse);
      expect(kept.path, narrow.path);
    },
  );
}

Future<File> _png({required int width, required int height}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF111111),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(
    '${Directory.systemTemp.path}/konter_src_${width}x$height.png',
  );
  await file.writeAsBytes(
    data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  return file;
}

Future<int> _widthOf(String path) async {
  final bytes = await File(path).readAsBytes();
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  try {
    return descriptor.width;
  } finally {
    descriptor.dispose();
    buffer.dispose();
  }
}
