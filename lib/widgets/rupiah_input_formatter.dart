import "package:flutter/services.dart";
import "package:cetak_struk/services/money_format.dart";

/// Hanya angka. Titik ribuan ditambahkan otomatis: `105000` → `105.000`.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r"\D"), "");
    if (digits.isEmpty) {
      return const TextEditingValue(text: "");
    }
    final trimmed = digits.replaceFirst(RegExp(r"^0+(?=\d)"), "");
    final value = int.tryParse(trimmed);
    if (value == null) return oldValue;

    final formatted = MoneyFormat.group(value);
    final cursorDigits = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r"\D"), "")
        .length;
    var seen = 0;
    var offset = formatted.length;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != ".") seen++;
      if (seen >= cursorDigits) {
        offset = i + 1;
        break;
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, formatted.length),
      ),
    );
  }
}
