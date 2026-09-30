import 'package:cetak_struk/models/parsed_receipt.dart';
import 'package:cetak_struk/services/money_format.dart';
import 'package:cetak_struk/services/pln_token_format.dart';

class ReceiptPrintLine {
  const ReceiptPrintLine(this.text, this.size, this.align);

  final String text;
  final int size;
  final int align;
}

class PrintBatch {
  const PrintBatch({
    required this.text,
    required this.size,
    required this.align,
    required this.sourceLines,
  });

  final String text;
  final int size;
  final int align;
  final int sourceLines;
}

/// Groups consecutive lines that share size and align.
///
/// `printCustom` writes the payload then one ESC/POS line feed (`0x0A`).
/// A newline inside the payload is the same byte, so grouped lines keep the
/// original spacing with one method-channel call per group.
List<PrintBatch> batchPrintLines(List<ReceiptPrintLine> lines) {
  if (lines.isEmpty) return const [];

  final batches = <PrintBatch>[];
  var text = StringBuffer(lines.first.text);
  var size = lines.first.size;
  var align = lines.first.align;
  var count = 1;

  void flush() {
    batches.add(
      PrintBatch(
        text: text.toString(),
        size: size,
        align: align,
        sourceLines: count,
      ),
    );
  }

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.size == size && line.align == align) {
      text
        ..write('\n')
        ..write(line.text);
      count++;
      continue;
    }
    flush();
    text = StringBuffer(line.text);
    size = line.size;
    align = line.align;
    count = 1;
  }
  flush();
  return batches;
}

class ReceiptDraft {
  const ReceiptDraft({
    required this.kind,
    required this.namaToko,
    required this.sourceApp,
    required this.totalBayar,
    this.nominal,
    this.penerima,
    this.rekeningOrPhone,
    this.noMeterOrIdpel,
    this.token,
    this.tanggal,
    this.catatan,
    this.otherLines = const [],
  });

  final TxKind kind;
  final String namaToko;
  final String sourceApp;
  final String totalBayar;
  final String? nominal;
  final String? penerima;
  final String? rekeningOrPhone;
  final String? noMeterOrIdpel;
  final String? token;
  final String? tanggal;
  final String? catatan;
  final List<String> otherLines;
}

List<ReceiptPrintLine> buildReceiptLines(ReceiptDraft draft) {
  final lines = <ReceiptPrintLine>[
    ReceiptPrintLine(draft.namaToko.toUpperCase(), 2, 1),
    _rule(),
    ReceiptPrintLine('SUMBER: ${draft.sourceApp}', 1, 0),
  ];

  switch (draft.kind) {
    case TxKind.transfer:
      lines.addAll(_pair('TRANSFER', _money(draft.nominal)));
      lines.addAll(_pair('Ke', draft.penerima));
      lines.addAll(_rekeningPair(draft.rekeningOrPhone));
      lines.addAll(_pair('Tanggal', draft.tanggal));
      lines.addAll(_pair('Dari', '${draft.namaToko} (${draft.sourceApp})'));
    case TxKind.plnToken:
      lines.add(const ReceiptPrintLine('PLN TOKEN', 1, 0));
      lines.addAll(_pair('IDPEL / Meter', draft.noMeterOrIdpel));
      final token = draft.token?.trim();
      if (token != null && token.isNotEmpty) {
        lines
          ..add(_blank())
          ..add(
            ReceiptPrintLine(formatPlnTokenLine(token), plnTokenPrintSize, 1),
          )
          ..add(_blank());
      }
      lines.addAll(_pair('Nominal', _money(draft.nominal)));
      lines.addAll(_pair('Tanggal', draft.tanggal));
    case TxKind.other:
      lines.addAll(_pair('Nominal', _money(draft.nominal)));
      for (final row in draft.otherLines) {
        final text = row.trim();
        if (text.isNotEmpty) lines.add(ReceiptPrintLine(text, 0, 0));
      }
      lines.addAll(_pair('Tanggal', draft.tanggal));
  }

  lines.add(_rule());
  lines.addAll(_pair('TOTAL BAYAR', _money(draft.totalBayar)));
  final catatan = draft.catatan?.trim() ?? '';
  if (catatan.isNotEmpty) {
    lines
      ..add(_rule())
      ..add(ReceiptPrintLine(catatan, 0, 1));
  }
  lines
    ..add(_rule())
    ..add(const ReceiptPrintLine('TERIMA KASIH', 1, 1));
  return lines;
}

ReceiptPrintLine _rule() => ReceiptPrintLine('-' * receiptColumns, 1, 1);

/// Satu baris kosong. Font A supaya jaraknya setara dengan baris nominal.
ReceiptPrintLine _blank() => const ReceiptPrintLine('', 1, 1);

String? _money(String? raw) => MoneyFormat.normalize(raw);

/// Nomor lengkap, nomor HP, atau topeng aplikasi lain. Label netral
/// karena isinya tidak selalu rekening atau nomor HP yang utuh.
List<ReceiptPrintLine> _rekeningPair(String? raw) {
  return _pair('Transfer ke', raw);
}

/// Size 1 = Font A (sama dengan TRANSFER / nominal). Size 0 adalah Font B:
/// 32 karakter tidak sampai tepi kanan, jadi nilai tidak rata kanan.
List<ReceiptPrintLine> _pair(String label, String? value, {int size = 1}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return const [];
  final gap = receiptColumns - label.length - text.length;
  if (gap >= 1) {
    return [ReceiptPrintLine('$label${' ' * gap}$text', size, 0)];
  }
  return [ReceiptPrintLine(label, size, 0), ReceiptPrintLine(text, size, 0)];
}

/// Contoh struk untuk pratinjau nama toko dan catatan, tanpa hasil scan.
ReceiptDraft previewReceiptDraft({
  required TxKind kind,
  required String namaToko,
  required String catatan,
}) {
  final toko = namaToko.trim().isEmpty ? ' ' : namaToko.trim();
  return switch (kind) {
    TxKind.plnToken => ReceiptDraft(
      kind: TxKind.plnToken,
      namaToko: toko,
      sourceApp: 'GOPAY',
      nominal: '100000',
      noMeterOrIdpel: '12345678901',
      token: '11112222333344445555',
      tanggal: '30 Sep 2026',
      totalBayar: '105000',
      catatan: catatan,
    ),
    _ => ReceiptDraft(
      kind: TxKind.transfer,
      namaToko: toko,
      sourceApp: 'GOPAY',
      nominal: '50000',
      penerima: 'Siti Aminah',
      rekeningOrPhone: '081234567890',
      tanggal: '30 Sep 2026',
      totalBayar: '52000',
      catatan: catatan,
    ),
  };
}
