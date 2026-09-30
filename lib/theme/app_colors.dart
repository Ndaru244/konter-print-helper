import "package:flutter/material.dart";

/// Token warna dari Docs/design-system.md. Hex hanya di file ini.
abstract final class AppColors {
  static const Color primary50 = Color(0xFFF6EBFA);
  static const Color primary100 = Color(0xFFEDD6F5);
  static const Color primary200 = Color(0xFFE0B8ED);
  static const Color primary300 = Color(0xFFCD8CE2);
  static const Color primary400 = Color(0xFFB352D3);
  static const Color primary500 = Color(0xFF8F00BF);
  static const Color primaryBiru = Color(0xFF1565C0);
  static const Color primaryHijau = Color(0xFF2E7D32);

  /// Kertas thermal. Tidak mengikuti primary atau mode gelap.
  static const Color receiptPaper = Color(0xFFFFFBF5);
  static const Color receiptInk = Color(0xFF1A1A1A);
  static const Color primary600 = Color(0xFF7E00A8);
  static const Color primary700 = Color(0xFF67008A);
  static const Color primary800 = Color(0xFF4F0069);
  static const Color primary900 = Color(0xFF3C0050);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color successBackground = Color(0xFFF0FDF4);
  static const Color successIcon = Color(0xFF22C55E);
  static const Color successText = Color(0xFF15803D);
  static const Color successBorder = Color(0xFFBBF7D0);

  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color warningIcon = Color(0xFFF59E0B);
  static const Color warningText = Color(0xFF92400E);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color dangerBackground = Color(0xFFFEF2F2);
  static const Color dangerIcon = Color(0xFFEF4444);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color infoBackground = Color(0xFFEFF6FF);
  static const Color infoIcon = Color(0xFF3B82F6);
  static const Color infoText = Color(0xFF1E40AF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  /// Palet banner di brightness gelap. Teks dan ikon ≥ 4.5:1 di atas background.
  static const Color successBackgroundDark = Color(0xFF14532D);
  static const Color successIconDark = Color(0xFF4ADE80);
  static const Color successTextDark = Color(0xFFDCFCE7);
  static const Color successBorderDark = Color(0xFF15803D);

  static const Color warningBackgroundDark = Color(0xFF78350F);
  static const Color warningIconDark = Color(0xFFFBBF24);
  static const Color warningTextDark = Color(0xFFFEF3C7);
  static const Color warningBorderDark = Color(0xFFB45309);

  static const Color dangerBackgroundDark = Color(0xFF7F1D1D);
  static const Color dangerIconDark = Color(0xFFFCA5A5);
  static const Color dangerTextDark = Color(0xFFFEE2E2);
  static const Color dangerBorderDark = Color(0xFFB91C1C);

  static const Color infoBackgroundDark = Color(0xFF1E3A8A);
  static const Color infoIconDark = Color(0xFF93C5FD);
  static const Color infoTextDark = Color(0xFFDBEAFE);
  static const Color infoBorderDark = Color(0xFF1D4ED8);

  /// Isi tombol destruktif. Putih di atas warna ini, bukan di #EF4444.
  static const Color dangerFill = Color(0xFFB91C1C);

  /// Warna aksen di atas surface gelap. Preset ungu memakai primary-300.
  /// Seed lain dinaikkan ke lightness yang setara supaya kontras di atas slate-800.
  static Color accentOnDark(Color seed) {
    if (seed.toARGB32() == primary500.toARGB32()) return primary300;
    final hsl = HSLColor.fromColor(seed);
    if (hsl.lightness >= 0.65) return seed;
    return hsl.withLightness(0.72).toColor();
  }
}
