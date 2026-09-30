import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:cetak_struk/widgets/rupiah_input_formatter.dart";

/// Field outline dari InputDecorationTheme: tinggi minimum 48, teks 16.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
    this.helperText,
    this.keyboardType,
    this.prefixText,
    this.suffixIcon,
    this.inputFormatters,
    this.selectAllOnTap = false,
    this.readOnly = false,
    this.onTap,
  });

  /// Papan angka. Awalan Rp, titik ribuan otomatis. Ketuk sekali menyorot semua.
  const AppTextField.rupiah({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
  }) : minLines = 1,
       maxLines = 1,
       keyboardType = const TextInputType.numberWithOptions(decimal: false),
       prefixText = "Rp",
       inputFormatters = const [RupiahInputFormatter()],
       selectAllOnTap = true,
       suffixIcon = null,
       readOnly = false,
       onTap = null;

  final TextEditingController controller;
  final String label;
  final int minLines;
  final int? maxLines;
  final String? helperText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool selectAllOnTap;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: readOnly ? TextInputType.none : keyboardType,
      readOnly: readOnly,
      showCursor: !readOnly,
      enableInteractiveSelection: !readOnly,
      inputFormatters: inputFormatters,
      style: textStyle,
      onTap: () {
        onTap?.call();
        if (!selectAllOnTap) return;
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 3,
        alignLabelWithHint: minLines > 1,
        prefixText: prefixText == null ? null : "$prefixText ",
        prefixStyle: textStyle,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
