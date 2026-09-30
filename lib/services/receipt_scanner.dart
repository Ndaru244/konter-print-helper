import 'package:cetak_struk/models/parsed_receipt.dart';
import 'package:cetak_struk/services/money_format.dart';
import 'package:cetak_struk/services/ocr_blocklist_store.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScanner {
  static const List<String> defaultBlacklist = [
    'unduh',
    'bagikan',
    'chat dengan cs',
    'download on the',
    'app store',
    'get it on',
    'google play',
    'aplikasi ringan',
    'diamankan oleh',
    'dana protection',
    'protection',
    'dapetin',
    'finansialmu',
    'share',
    'resi ini merupakan',
    'transaksi yang sah',
    'butuh bantuan',
    'promo',
    'hemat',
    'dikirim dari app',
    'klik untuk salin',
    'pembayaran diterima',
    'transaksi diproses',
    'transaksi selesai',
  ];

  static ParsedReceipt process(
    RecognizedText recognizedText, {
    Set<String> blockedPhrases = const {},
  }) {
    return parseText(
      _reconstructLines(recognizedText),
      blockedPhrases: blockedPhrases,
    );
  }

  /// Parser teks OCR yang sudah tersusun per baris. Dipakai tes tanpa ML Kit.
  static ParsedReceipt parseText(
    String rawText, {
    Set<String> blockedPhrases = const {},
  }) {
    final allLines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final visible = allLines.where((line) {
      return !_isNoise(line) && !_isBlocked(line, blockedPhrases);
    }).toList();

    final source = _detectSource(rawText);
    final kind = _detectKind(rawText);
    final tanggal = _extractTanggal(allLines);
    final amounts = _extractAmounts(allLines);
    final nominal = _pickNominal(kind, amounts);
    final appTotal = _pickAppTotal(amounts);

    String? penerima;
    String? rekening;
    String? idpel;
    String? token;
    if (kind == TxKind.plnToken) {
      idpel = _extractIdpel(rawText);
      token = _extractToken(rawText);
    } else {
      penerima = _extractPenerima(allLines, rawText);
      rekening = _extractRekening(allLines, rawText, penerima);
    }

    return ParsedReceipt(
      kind: kind,
      sourceApp: source,
      rawText: rawText.trim(),
      lines: visible,
      nominal: nominal,
      tanggal: tanggal,
      penerima: penerima,
      rekeningOrPhone: rekening,
      noMeterOrIdpel: idpel,
      token: token,
      appTotal: appTotal,
    );
  }

  static String _reconstructLines(RecognizedText recognizedText) {
    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    if (allLines.isEmpty) return '';

    final grouped = <List<TextLine>>[];
    var currentGroup = <TextLine>[allLines.first];
    var currentY = allLines.first.boundingBox.top;
    const threshold = 15.0;

    for (var i = 1; i < allLines.length; i++) {
      final line = allLines[i];
      if ((line.boundingBox.top - currentY).abs() < threshold) {
        currentGroup.add(line);
      } else {
        grouped.add(currentGroup);
        currentGroup = [line];
        currentY = line.boundingBox.top;
      }
    }
    grouped.add(currentGroup);

    final buffer = StringBuffer();
    for (final group in grouped) {
      group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      buffer.writeln(group.map((e) => e.text).join(' '));
    }
    return buffer.toString();
  }

  static String _detectSource(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('seabank')) return 'SEABANK';
    if (lower.contains('gopay')) return 'GOPAY';
    if (RegExp(r'\bdana\b').hasMatch(lower)) return 'DANA';
    if (lower.contains('brimo')) return 'BRI MO';
    if (RegExp(r'\bbri\b').hasMatch(lower)) return 'BRI MO';
    return 'UMUM';
  }

  static TxKind _detectKind(String text) {
    final lower = text.toLowerCase();
    final plnPhrase =
        RegExp(r'pln\s*token').hasMatch(lower) ||
        (lower.contains('pln') && lower.contains('token'));
    final meterHint =
        lower.contains('idpel') ||
        lower.contains('kwh') ||
        lower.contains('nomor meter') ||
        lower.contains('no. meter') ||
        lower.contains('token');
    if (plnPhrase || (meterHint && _extractToken(text) != null)) {
      return TxKind.plnToken;
    }
    final transfer =
        lower.contains('kirim uang') ||
        lower.contains('ditransfer ke') ||
        lower.contains('jumlah transfer') ||
        lower.contains('bukti transaksi');
    if (transfer) return TxKind.transfer;
    if (_extractToken(text) != null) return TxKind.plnToken;
    return TxKind.other;
  }

  static String? _extractToken(String text) {
    final dashed = RegExp(r'(?<!\d)(?:\d{4}[-\s]){4}\d{4}(?!\d)');
    for (final match in dashed.allMatches(text)) {
      final digits = match.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 20) return _groupToken(digits);
    }
    final continuous = RegExp(r'(?<!\d)\d{20}(?!\d)');
    final plain = continuous.firstMatch(text);
    if (plain != null) return _groupToken(plain.group(0)!);
    return null;
  }

  static String _groupToken(String digits) {
    return '${digits.substring(0, 4)}-${digits.substring(4, 8)}-'
        '${digits.substring(8, 12)}-${digits.substring(12, 16)}-'
        '${digits.substring(16, 20)}';
  }

  static String? _extractIdpel(String text) {
    final patterns = [
      RegExp(r'pln\s*token\s*[-–]\s*(\d{8,15})', caseSensitive: false),
      RegExp(
        r'(?:idpel|id\s*pelanggan|no\.?\s*meter|nomor\s*meter)\s*[:\-]?\s*(\d{8,15})',
        caseSensitive: false,
      ),
    ];
    for (final re in patterns) {
      final match = re.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _extractTanggal(List<String> lines) {
    final dateRe = RegExp(
      r'\d{1,2}\s+(?:Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember|Jan|Feb|Mar|Apr|Jun|Jul|Agu|Agt|Sep|Okt|Nov|Des)\w*\s+\d{4}(?:[,\s]+\d{1,2}[:.]\d{2})?',
      caseSensitive: false,
    );
    final clockRe = RegExp(r'\b(\d{1,2}:\d{2})\b');
    for (var i = 0; i < lines.length; i++) {
      final match = dateRe.firstMatch(lines[i]);
      if (match == null) continue;
      var value = match.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (!RegExp(r'\d{1,2}:\d{2}').hasMatch(value)) {
        final start = i - 3 < 0 ? 0 : i - 3;
        final end = i + 2 >= lines.length ? lines.length - 1 : i + 2;
        for (var j = start; j <= end; j++) {
          if (j == i) continue;
          final clock = clockRe.firstMatch(lines[j]);
          if (clock != null) {
            value = '$value ${clock.group(1)}';
            break;
          }
        }
      }
      return value;
    }
    return null;
  }

  static List<_AmountHit> _extractAmounts(List<String> lines) {
    final hits = <_AmountHit>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      var value = MoneyFormat.firstAmount(line);
      if (value == null) continue;
      if (i + 1 < lines.length && _isAmountTail(lines[i + 1])) {
        final combined = MoneyFormat.firstAmount('$line ${lines[i + 1]}');
        final head = RegExp(
          r'\d+',
        ).firstMatch(line.substring(line.toLowerCase().indexOf('rp')));
        if (combined != null &&
            head != null &&
            value.toString() == head.group(0)) {
          value = combined;
        }
      }
      final rpAt = line.toLowerCase().indexOf('rp');
      var label = rpAt > 0 ? line.substring(0, rpAt) : '';
      if (label.trim().isEmpty && i > 0) label = lines[i - 1];
      hits.add(_AmountHit(MoneyFormat.format(value), label.toLowerCase()));
    }
    return hits;
  }

  static bool _isAmountTail(String line) {
    return RegExp(r'^[^\dA-Za-z]*\d{2,3}$').hasMatch(line.trim());
  }

  static String? _pickNominal(TxKind kind, List<_AmountHit> hits) {
    if (hits.isEmpty) return null;
    bool isAdmin(_AmountHit h) =>
        h.label.contains('admin') || h.label.contains('biaya');
    bool isTotal(_AmountHit h) =>
        h.label.contains('total') && !h.label.contains('jumlah');
    if (kind == TxKind.plnToken) {
      for (final hit in hits) {
        if (hit.label.contains('jumlah') && !isAdmin(hit) && !isTotal(hit)) {
          return hit.display;
        }
      }
      for (final hit in hits) {
        if (!isAdmin(hit) && !isTotal(hit)) return hit.display;
      }
    }
    for (final hint in ['jumlah transfer', 'kirim uang', 'jumlah']) {
      for (final hit in hits) {
        if (hit.label.contains(hint) && !isAdmin(hit)) return hit.display;
      }
    }
    for (final hit in hits) {
      if (!isAdmin(hit) && !isTotal(hit)) return hit.display;
    }
    return hits.first.display;
  }

  static String? _pickAppTotal(List<_AmountHit> hits) {
    for (final hit in hits.reversed) {
      final label = hit.label;
      if ((label.contains('total') || label.contains('total bayar')) &&
          !label.contains('admin')) {
        return hit.display;
      }
    }
    return null;
  }

  static String? _extractPenerima(List<String> lines, String raw) {
    final gopay = RegExp(
      r'ditransfer ke\s+(.+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (gopay != null) return _cleanName(gopay.group(1)!);

    final danaInline = RegExp(
      r'kirim uang\s+rp\s?[\d.]+\s+ke\s+([A-Za-z][A-Za-z .]{1,40})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = danaInline.firstMatch(line);
      if (match != null) return _cleanName(match.group(1)!);
    }

    for (final line in lines) {
      final inlineKe = RegExp(
        r'^ke\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(line.trim());
      if (inlineKe != null) {
        final name = _cleanName(inlineKe.group(1)!);
        if (name.isNotEmpty && !_looksLikeBank(name)) return name;
      }
    }
    final ke = _valueAfter(lines, RegExp(r'^ke$', caseSensitive: false));
    if (ke != null && !_looksLikeBank(ke)) return _cleanName(ke);

    final nama = _valueAfter(lines, RegExp(r'^nama$', caseSensitive: false));
    if (nama != null) return _cleanName(nama);
    return null;
  }

  static String? _extractRekening(
    List<String> lines,
    String raw,
    String? penerima,
  ) {
    final phone = RegExp(r'\b08[\d*]{6,13}\b').firstMatch(raw);
    if (phone != null) return phone.group(0);

    final labeled = _valueAfter(
      lines,
      RegExp(
        r'^(?:nomor hp|no\.?\s*hp|rekening|no\.?\s*rekening)$',
        caseSensitive: false,
      ),
    );
    if (labeled != null) return labeled;

    if (penerima == null) return null;
    for (var i = 0; i < lines.length; i++) {
      if (!_sameName(lines[i], penerima)) continue;
      if (i + 1 >= lines.length) break;
      final next = lines[i + 1].trim();
      if (_looksLikeBank(next)) return next;
    }
    return null;
  }

  static String? _valueAfter(List<String> lines, RegExp label) {
    for (var i = 0; i < lines.length; i++) {
      if (!label.hasMatch(lines[i].trim())) continue;
      if (i + 1 >= lines.length) return null;
      final next = lines[i + 1].trim();
      if (next.isEmpty) continue;
      return next;
    }
    return null;
  }

  static String _cleanName(String raw) {
    var name = raw.split(RegExp(r'\s[-–]\s| / |,')).first.trim();
    name = name.replaceAll(RegExp(r'\b08[\d*]{6,13}\b'), '').trim();
    return name.replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _sameName(String line, String name) {
    return line.toLowerCase().contains(name.toLowerCase());
  }

  static bool _looksLikeBank(String value) {
    final t = value.trim().toLowerCase();
    const banks = {
      'bca',
      'bni',
      'bri',
      'mandiri',
      'ovo',
      'gopay',
      'dana',
      'seabank',
      'jago',
      'bsi',
      'permata',
      'cimb',
      'btn',
    };
    return banks.contains(t);
  }

  static bool _isBlocked(String line, Set<String> blocked) {
    final lower = line.toLowerCase();
    for (final phrase in blocked) {
      final norm = OcrBlocklistStore.normalize(phrase);
      if (norm.isNotEmpty && lower.contains(norm)) return true;
    }
    return false;
  }

  static bool _isNoise(String text) {
    final t = text.toLowerCase().trim();
    if (t.length <= 2) return true;
    for (final keyword in defaultBlacklist) {
      if (t.contains(keyword)) return true;
    }
    return false;
  }
}

class _AmountHit {
  const _AmountHit(this.display, this.label);
  final String display;
  final String label;
}
