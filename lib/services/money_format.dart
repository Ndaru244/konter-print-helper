class MoneyFormat {
  static final _rp = RegExp(r'rp', caseSensitive: false);
  static final _dotThousands = RegExp(r'^\d{1,3}(\.\d{3})+$');
  static final _commaThousands = RegExp(r'^\d{1,3}(,\d{3})+$');

  /// `Rp1.000`, `Rp 1.000`, `101.900` → int. Pemisah ribuan Indonesia (titik).
  static int? parse(String input) {
    var s = input.replaceAll(_rp, '').replaceAll(RegExp(r'\s'), '').trim();
    if (s.isEmpty) return null;
    if (_dotThousands.hasMatch(s)) {
      return int.tryParse(s.replaceAll('.', ''));
    }
    if (_commaThousands.hasMatch(s)) {
      return int.tryParse(s.replaceAll(',', ''));
    }
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  static String format(int value) {
    final grouped = group(value.abs());
    if (value < 0) return '-Rp $grouped';
    return 'Rp $grouped';
  }

  /// `100000` → `100.000`. Untuk isi field, tanpa awalan Rp.
  static String group(int value) {
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Nominal pertama yang diawali `Rp` pada satu baris.
  /// Pemisah OCR (titik, koma, spasi, simbol) di antara kelompok digit diabaikan:
  /// `Rp50.000`, `Rp50. 000`, dan `Rp50 .000` sama-sama 50000.
  static int? firstAmount(String line) {
    final start = line.toLowerCase().indexOf('rp');
    if (start < 0) return null;
    var i = start + 2;
    while (i < line.length && !_isDigit(line, i)) {
      if (_isLetter(line[i])) return null;
      i++;
    }
    if (i >= line.length) return null;

    final groups = <String>[];
    while (i < line.length && _isAmountDigit(line, i)) {
      final groupStart = i;
      while (i < line.length && _isAmountDigit(line, i)) {
        i++;
      }
      final group = line
          .substring(groupStart, i)
          .replaceAll('O', '0')
          .replaceAll('o', '0');
      final isTail =
          group.length == 3 || (group.length == 2 && groups.length == 1);
      if (groups.isNotEmpty && !isTail) break;
      groups.add(group);
      if (groups.length > 1 && group.length == 2) break;

      final sep = i;
      while (i < line.length &&
          !_isAmountDigit(line, i) &&
          !_isLetter(line[i])) {
        i++;
      }
      if (i == sep || i >= line.length || !_isAmountDigit(line, i)) break;
    }
    if (groups.isEmpty) return null;
    return int.tryParse(groups.join());
  }

  static bool _isDigit(String line, int index) {
    final code = line.codeUnitAt(index);
    return code >= 0x30 && code <= 0x39;
  }

  /// Huruf O pada nominal OCR sering adalah angka 0 (`Rp50.0O0`).
  static bool _isAmountDigit(String line, int index) {
    if (_isDigit(line, index)) return true;
    final char = line[index];
    return char == 'O' || char == 'o';
  }

  static bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
  }

  static String inputText(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = parse(raw);
    if (value == null) return '';
    return group(value);
  }

  /// Kosong → null. Angka valid → `Rp x.xxx`. Teks lain dibiarkan.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = parse(trimmed);
    if (value == null) return trimmed;
    return format(value);
  }
}
