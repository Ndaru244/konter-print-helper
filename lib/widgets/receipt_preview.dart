import "package:cetak_struk/theme/app_colors.dart";
import "package:flutter/material.dart";
import "package:cetak_struk/services/receipt_print.dart";

/// Kertas thermal. Warna tetap terang, tidak mengikuti tema aplikasi.
const _paper = AppColors.receiptPaper;
const _ink = AppColors.receiptInk;

class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({super.key, required this.lines});

  final List<ReceiptPrintLine> lines;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        color: _paper,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              line.text.isEmpty
                  ? const SizedBox(height: 12)
                  : Text(
                      line.text,
                      textAlign: switch (line.align) {
                        1 => TextAlign.center,
                        2 => TextAlign.right,
                        _ => TextAlign.left,
                      },
                      style: _styleFor(line.size),
                    ),
          ],
        ),
      ),
    );
  }

  TextStyle _styleFor(int size) {
    final (fontSize, weight, height) = switch (size) {
      0 => (12.0, FontWeight.w400, 1.2),
      2 => (16.0, FontWeight.w700, 1.2),
      3 => (16.0, FontWeight.w700, 1.6),
      _ => (14.0, FontWeight.w700, 1.2),
    };
    return TextStyle(
      fontFamily: "monospace",
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      color: _ink,
    );
  }
}
