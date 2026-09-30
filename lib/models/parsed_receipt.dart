enum TxKind { transfer, plnToken, other }

class ParsedReceipt {
  const ParsedReceipt({
    required this.kind,
    required this.sourceApp,
    required this.rawText,
    required this.lines,
    this.nominal,
    this.tanggal,
    this.penerima,
    this.rekeningOrPhone,
    this.noMeterOrIdpel,
    this.token,
    this.appTotal,
  });

  final TxKind kind;
  final String sourceApp;
  final String rawText;

  /// Baris OCR setelah noise dan blocklist, untuk chip / debug.
  final List<String> lines;
  final String? nominal;
  final String? tanggal;
  final String? penerima;
  final String? rekeningOrPhone;
  final String? noMeterOrIdpel;
  final String? token;
  final String? appTotal;
}
