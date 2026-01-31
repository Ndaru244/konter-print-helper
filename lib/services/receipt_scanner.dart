import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanResult {
  final String source;
  final String processedText;

  ScanResult({required this.source, required this.processedText});
}

class ReceiptScanner {
  static const List<String> _blacklist = [
    "gratis", "transfer", "selesai", "rincian transaksi", "detail transaksi",
    "no. transaksi", "id transaksi", "metode pembayaran", "waktu", "tanggal",
    "total", "jumlah", "unduh", "unduh dan bagikan", "chat dengan cs",
    "download on the", "app store", "get it on", "google play", "aplikasi ringan",
    "diamankan oleh", "protection", "id dana", "id order merchant",
    "external serial number", "harga tercantum", "sudah termasuk", "dikirim dari",
    "dapetin", "saldo", "detail", "akun", "nama", "biaya", "admin", "pembayaran",
    "kirim", "uang", "dari", "ke", "jumlah transfer", "no. referensi",
    "bukti transaksi", "metode transaksi", "waktu transaksi", "butuh bantuan?",
    "resi ini merupakan bukti transaksi yang sah", "realtime online", "odana",
    "transaksi berhasil!", "detail penerima", "akun dana", "dp", "smartpay",
    "da", "status", "gopay saldo", "finansialmu.", "share", "bagikan"
  ];

  static ScanResult process(RecognizedText recognizedText) {
    String source = "UMUM";

    String sortedText = _reconstructLines(recognizedText);

    final lowerText = sortedText.toLowerCase();

    if (lowerText.contains("dana")) {
      source = "DANA";
    } else if (lowerText.contains("gopay")) {
      source = "GOPAY";
    } else if (lowerText.contains("seabank")) {
      source = "SEABANK";
    } else if (lowerText.contains("brimo") || lowerText.contains("bri")) {
      source = "BRI MO";
    }

    final List<String> finalLines = [];

    _extractKeyData(sortedText, finalLines);

    final lines = sortedText.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !_isNoise(trimmed)) {
        bool alreadyAdded = finalLines.any((e) => e.contains(trimmed));
        if (!alreadyAdded) {
          finalLines.add(trimmed);
        }
      }
    }

    return ScanResult(
      source: source,
      processedText: finalLines.join('\n'),
    );
  }

  static String _reconstructLines(RecognizedText recognizedText) {
    List<TextLine> allLines = [];

    for (var block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<List<TextLine>> groupedLines = [];
    if (allLines.isEmpty) return "";

    List<TextLine> currentGroup = [allLines[0]];
    double currentY = allLines[0].boundingBox.top;

    double threshold = 20.0;

    for (int i = 1; i < allLines.length; i++) {
      var line = allLines[i];

      if ((line.boundingBox.top - currentY).abs() < threshold) {
        currentGroup.add(line);
      } else {
        groupedLines.add(currentGroup);
        currentGroup = [line];
        currentY = line.boundingBox.top;
      }
    }
    groupedLines.add(currentGroup);

    StringBuffer buffer = StringBuffer();
    for (var group in groupedLines) {
      group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      String rowText = group.map((e) => e.text).join(" ");
      buffer.writeln(rowText);
    }

    return buffer.toString();
  }

  static void _extractKeyData(String text, List<String> list) {
    final regexNominal = RegExp(r'Rp\s?(\d{1,3}(?:\.\d{3})*)');
    final matchNominal = regexNominal.firstMatch(text);
    if (matchNominal != null && matchNominal.group(0) != null) {
      list.add("Nominal: ${matchNominal.group(0)!.replaceAll(" ", "")}");
    }

    final regexKe = RegExp(r'(?:ke|penerima|tujuan)\s*[:]?\s*([a-zA-Z\s\.]+)');
    final matchesKe = regexKe.allMatches(text);

    for (var match in matchesKe) {
      if (match.group(1) != null) {
        String val = match.group(1)!.trim();
        if (val.length > 3 && val.length < 30 && !val.toLowerCase().contains("bank")) {
          // Cek duplikasi
          if (!list.any((e) => e.contains(val))) {
            list.add("Penerima: $val");
          }
        }
      }
    }
  }

  static bool _isNoise(String text) {
    final t = text.toLowerCase();

    if (t.length <= 2) return true;

    bool hasDigit = RegExp(r'\d').hasMatch(t);

    for (var keyword in _blacklist) {
      if (t.contains(keyword)) return true;
    }

    if (hasDigit && !t.contains("biaya") && !t.contains("admin")) {
      return false;
    }

    return false;
  }
}