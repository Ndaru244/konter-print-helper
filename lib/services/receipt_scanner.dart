import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanResult {
  final String source;
  final String processedText;

  ScanResult({required this.source, required this.processedText});
}

class ReceiptScanner {
  // Blacklist lebih longgar: hanya membuang elemen UI aplikasi yang tidak penting
  static const List<String> _blacklist = [
    "unduh", "bagikan", "chat dengan cs", "download on the", "app store",
    "get it on", "google play", "aplikasi ringan", "diamankan oleh",
    "protection", "dapetin", "finansialmu", "share", "resi ini merupakan bukti",
    "transaksi yang sah", "butuh bantuan?", "promo", "hemat"
  ];

  static ScanResult process(RecognizedText recognizedText) {
    String source = "UMUM";
    
    // Urutkan teks berdasarkan posisi Y (baris) dan X (kolom)
    String sortedText = _reconstructLines(recognizedText);
    final lowerText = sortedText.toLowerCase();

    // Deteksi Sumber
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

    // Ekstraksi data penting (Nominal & Penerima) dengan regex yang lebih cerdas
    _extractKeyData(sortedText, finalLines);

    // Tambahkan baris lain yang bukan noise/blacklist
    final lines = sortedText.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !_isNoise(trimmed)) {
        // Cek apakah data ini sudah ada di finalLines (biar tidak double)
        bool alreadyAdded = finalLines.any((e) => e.toLowerCase().contains(trimmed.toLowerCase()));
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

    // Urutkan berdasarkan posisi atas (Top)
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<List<TextLine>> groupedLines = [];
    if (allLines.isEmpty) return "";

    List<TextLine> currentGroup = [allLines[0]];
    double currentY = allLines[0].boundingBox.top;
    double threshold = 15.0; // Toleransi jarak antar kata dalam satu baris

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
      // Urutkan kata dari kiri ke kanan (Left to Right)
      group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      String rowText = group.map((e) => e.text).join(" ");
      buffer.writeln(rowText);
    }

    return buffer.toString();
  }

  static void _extractKeyData(String text, List<String> list) {
    // 1. Cari Nominal (Rp ...)
    final regexNominal = RegExp(r'Rp\s?(\d{1,3}(?:\.\d{3})*)');
    final matchNominal = regexNominal.firstMatch(text);
    if (matchNominal != null) {
      list.add("TOTAL: ${matchNominal.group(0)}");
    }

    // 2. Cari Nama Penerima (biasanya setelah kata 'ke', 'penerima', atau 'transfer ke')
    final regexPenerima = RegExp(r'(?:ke|penerima|transfer ke|tujuan)\s*[:]?\s*([A-Z\s]{3,30})', caseSensitive: false);
    final matchPenerima = regexPenerima.firstMatch(text);
    if (matchPenerima != null && matchPenerima.group(1) != null) {
      String nama = matchPenerima.group(1)!.trim();
      if (nama.isNotEmpty && !nama.toLowerCase().contains("bank")) {
        list.add("PENERIMA: $nama");
      }
    }
    
    // 3. ID Transaksi (Sering dibutuhkan)
    final regexID = RegExp(r'(?:ID Transaksi|No\. transaksi|ID Order)\s*[:]?\s*([A-Z0-9\s-]{10,})', caseSensitive: false);
    final matchID = regexID.firstMatch(text);
    if (matchID != null && matchID.group(1) != null) {
      list.add("ID TX: ${matchID.group(1)!.trim()}");
    }
  }

  static bool _isNoise(String text) {
    final t = text.toLowerCase();
    
    // Jika terlalu pendek, kemungkinan besar noise
    if (t.length <= 2) return true;

    // Cek blacklist
    for (var keyword in _blacklist) {
      if (t.contains(keyword)) return true;
    }

    return false;
  }
}
