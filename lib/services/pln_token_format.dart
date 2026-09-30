/// Kolom Font A pada kertas 58mm yang dipakai template struk saat ini.
const int receiptColumns = 32;

/// `printCustom` size 3 = ESC `0x10` (tebal + tinggi ganda, lebar tetap).
/// Size 2 (`0x20`) melebar dua kali dan memotong token 20 digit di 58mm.
const int plnTokenPrintSize = 3;

/// Satu baris token: digit berkelompok `XXXX-XXXX-XXXX-XXXX-XXXX` bila muat,
/// atau digit saja. Tidak pernah menyisipkan baris baru.
String formatPlnTokenLine(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return raw.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  }

  final core = digits.length >= 20 ? digits.substring(0, 20) : digits;
  if (core.length == 20) {
    final dashed = _dashedGroups(core);
    if (dashed.length <= receiptColumns) return dashed;
  }
  if (core.length <= receiptColumns) return core;
  return core;
}

String _dashedGroups(String digits) {
  final parts = <String>[];
  for (var i = 0; i < digits.length; i += 4) {
    final end = i + 4 > digits.length ? digits.length : i + 4;
    parts.add(digits.substring(i, end));
  }
  return parts.join('-');
}
