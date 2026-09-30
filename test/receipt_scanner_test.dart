import 'package:cetak_struk/models/parsed_receipt.dart';
import 'package:cetak_struk/services/money_format.dart';
import 'package:cetak_struk/services/pln_token_format.dart';
import 'package:cetak_struk/services/receipt_print.dart';
import 'package:cetak_struk/services/receipt_scanner.dart';
import 'package:cetak_struk/widgets/rupiah_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rupiah parser menerima Rp, spasi, dan titik ribuan', () {
    expect(MoneyFormat.parse('Rp1.000'), 1000);
    expect(MoneyFormat.parse('Rp 1.000'), 1000);
    expect(MoneyFormat.parse('101.900'), 101900);
    expect(MoneyFormat.parse('Rp500,00'), 50000);
    expect(MoneyFormat.parse('Rp500.00'), 50000);
    expect(MoneyFormat.parse('Rp500 00'), 50000);
    expect(MoneyFormat.firstAmount('Rp50.000'), 50000);
    expect(MoneyFormat.firstAmount('Rp50. 000'), 50000);
    expect(MoneyFormat.firstAmount('Rp50 .000'), 50000);
    expect(MoneyFormat.firstAmount('Rp50.000 28 Sep 2026'), 50000);
    expect(MoneyFormat.firstAmount('Jumlah Rp50.0O0'), 50000);
    expect(MoneyFormat.firstAmount('Total Rp50.0o0'), 50000);
    expect(MoneyFormat.format(101900), 'Rp 101.900');
    expect(MoneyFormat.inputText('Rp 100.000'), '100.000');
    expect(MoneyFormat.group(105000), '105.000');
  });

  test('ketikan nominal jadi titik ribuan', () {
    const formatter = RupiahInputFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '105000',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(result.text, '105.000');
    expect(result.text.contains('Rp'), isFalse);
  });

  test('GoPay PLN mengisi idpel, token, jumlah, dan total', () {
    const raw = '''
gopay
Rp101.900
PLN Token - 12345678901
PLN Token
1111-2222-3333-4444-5555
Klik untuk salin nomor
Waktu
12:15
Tanggal
30 Sep 2026
Nomor referensi
1111 2222 3333 4
Jumlah
Rp100.000
Biaya admin
Rp1.900
Total
Rp101.900
Dikirim dari app GoPay
Dapetin gratis transfer
''';

    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.plnToken);
    expect(parsed.sourceApp, 'GOPAY');
    expect(parsed.noMeterOrIdpel, '12345678901');
    expect(parsed.token, '1111-2222-3333-4444-5555');
    expect(parsed.nominal, 'Rp 100.000');
    expect(parsed.appTotal, 'Rp 101.900');
    expect(parsed.tanggal, '30 Sep 2026 12:15');
    expect(
      parsed.lines.any((l) => l.toLowerCase().contains('klik untuk salin')),
      isFalse,
    );
  });

  test('token terpecah baris tetap dirakit 20 digit', () {
    const raw = '''
PLN Token - 12345678901
1111 2222 3333
4444 5555
Jumlah
Rp50.000
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.plnToken);
    expect(parsed.token, '1111-2222-3333-4444-5555');
  });

  test('SeaBank transfer mengisi penerima dan nominal', () {
    const raw = '''
SeaBank
Bukti Transaksi
Jumlah Transfer
Rp46.000
Ke
Siti Aminah
OVO
Dari
Toko Contoh
29 Sep 2026 21:07
Butuh Bantuan?
Resi ini merupakan bukti
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.transfer);
    expect(parsed.sourceApp, 'SEABANK');
    expect(parsed.nominal, 'Rp 46.000');
    expect(parsed.penerima, 'Siti Aminah');
    expect(parsed.rekeningOrPhone, isNull);
    expect(parsed.tanggal, '29 Sep 2026 21:07');
  });

  test('DANA transfer mengambil nama setelah Kirim Uang', () {
    const raw = '''
DANA
Kirim Uang Rp32.000 ke Budi Santoso
Total Bayar
Rp32.000
30 Sep 2026 08:48
Diamankan oleh DANA PROTECTION
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.transfer);
    expect(parsed.sourceApp, 'DANA');
    expect(parsed.nominal, 'Rp 32.000');
    expect(parsed.penerima, 'Budi Santoso');
    expect(parsed.rekeningOrPhone, isNull);
  });

  test('DANA memakai akun penerima, bukan ID DANA pengirim', () {
    const raw = '''
ODANA
DANA DANA DANR
30 Sep 2026 • 16:53 ID DANA 0812•**7691
Transaksi berhasil!
Kirim Uang Rp500.000 ke Ernawati -
085892965320
Total Bayar Rp500.000
Metode Pembayaran Saldo DANA
(SmartPay)
DANe
DAN
Detail Penerima
Nama Ernawati
Akun DANA 085892965320
Detail Transaksi
ID Transaksi 2026093010121410010
100166257592792971
ID Order Merchant 2026093010121410010
100166257592792970
Diamankan oleh A DANA
PROTECTION
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.transfer);
    expect(parsed.sourceApp, 'DANA');
    expect(parsed.penerima, 'Ernawati');
    expect(parsed.rekeningOrPhone, '085892965320');
  });

  test('rekening terisi dari label, HP, dan angka di dekat penerima', () {
    final dana = ReceiptScanner.parseText('''
DANA
Kirim Uang Rp32.000 ke Siti Aminah
Nomor HP +62 812-3456-7890
Total Bayar
Rp32.000
''');
    expect(dana.rekeningOrPhone, '081234567890');
    expect(dana.penerima, 'Siti Aminah');

    final gopay = ReceiptScanner.parseText('''
gopay
Ditransfer ke Siti Aminah
0812xxxx7890
Jumlah Rp50.000
''');
    expect(gopay.rekeningOrPhone, '0812xxxx7890');

    final bank = ReceiptScanner.parseText('''
Bukti Transaksi
Jumlah Transfer
Rp200.000
Ke
Budi Santoso
BCA
No. Rek 8830123456
ID transaksi
0420260928132
''');
    expect(bank.penerima, 'Budi Santoso');
    expect(bank.rekeningOrPhone, '8830123456');

    final nearAccount = ReceiptScanner.parseText('''
Ditransfer ke Budi Santoso
BCA 5420112233
Rp50.000
''');
    expect(nearAccount.rekeningOrPhone, '5420112233');

    final bankOnly = ReceiptScanner.parseText('''
Ditransfer ke Siti Aminah
GoPay
Rp50.000
30 Sep 2026 08:48
''');
    expect(bankOnly.rekeningOrPhone, isNull);
  });

  test('SeaBank memakai rekening pihak Ke, bukan Dari', () {
    final ovo = ReceiptScanner.parseText('''
Dari Slamet Rahayu
SeaBank: ********7870
Ke ovo Somad
OVO: 0857*****403
''');
    expect(ovo.kind, TxKind.transfer);
    expect(ovo.penerima, 'Somad');
    expect(ovo.rekeningOrPhone, '0857*****403');

    final bca = ReceiptScanner.parseText('''
Dari Slamet Rahayu
SeaBank: ********7870
Ke Ahmad Farid Sopian
BANK BCA: ******1466
''');
    expect(bca.kind, TxKind.transfer);
    expect(bca.penerima, 'Ahmad Farid Sopian');
    expect(bca.rekeningOrPhone, '******1466');
  });

  test('rekening GoPay bertopeng, SeaBank, dan OVO', () {
    final gopay = ReceiptScanner.parseText('''
gopay
Ditransfer ke Siti Aminah
GoPay ****891
Jumlah Rp50.000
28 Sep 2026
''');
    expect(gopay.kind, TxKind.transfer);
    expect(gopay.penerima, 'Siti Aminah');
    expect(gopay.rekeningOrPhone, '****891');

    final gopayShort = ReceiptScanner.parseText('''
gopay
Ditransfer ke Budi Santoso
GoPay ***891
Rp10.000
''');
    expect(gopayShort.rekeningOrPhone, '***891');

    final seabank = ReceiptScanner.parseText('''
SeaBank
Bukti Transaksi
Jumlah Transfer
Rp200.000
Ke
Siti Aminah
BCA
****56789012
Dari
Toko Contoh
30 Sep 2026 16:18
ID transaksi
0420260928132
''');
    expect(seabank.sourceApp, 'SEABANK');
    expect(seabank.penerima, 'Siti Aminah');
    expect(seabank.rekeningOrPhone, '****56789012');

    final ovoPlain = ReceiptScanner.parseText('''
Bukti Transaksi
Jumlah Transfer
Rp46.000
Ke
Budi Santoso
OVO
081298765432
29 Sep 2026 21:07
''');
    expect(ovoPlain.rekeningOrPhone, '081298765432');

    final ovoMasked = ReceiptScanner.parseText('''
DANA
Kirim Uang Rp32.000 ke Siti Aminah
OVO
08***123
''');
    expect(ovoMasked.rekeningOrPhone, '08***123');
  });

  test('nominal GoPay Rp50.000 tidak terpotong meski titik terpisah spasi', () {
    const raw = '''
gopay
Rp50. 000
Ditransfer ke Siti Aminah
Jumlah
Rp50 .000
Total Rp50.000
28 Sep 2026 20:27
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.transfer);
    expect(parsed.nominal, 'Rp 50.000');
    expect(MoneyFormat.inputText(parsed.nominal), '50.000');
  });

  test('GoPay transfer Rp500,00 tetap 50000', () {
    const raw = '''
gopay
Rp500,00
Ditransfer ke Siti Aminah
GoPay ***8109
Rincian transaksi
Jumlah
Rp500,00
Total
Rp500,00
28 Sep 2026 20:27
Dikirim dari app GoPay
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.transfer);
    expect(parsed.sourceApp, 'GOPAY');
    expect(parsed.nominal, 'Rp 50.000');
    expect(parsed.penerima, 'Siti Aminah');
    expect(MoneyFormat.inputText(parsed.nominal), '50.000');
  });

  test('GoPay nominal tetap 50000 walau O di baris Jumlah dan Total', () {
    const raw = '''
gopay
Rp50.000
Ditransfer ke Siti Aminah
GoPay ****8109
Rincian transaksi
Status SelesaiO
Metode pembayaran GoPay Saldo O
Waktu 20:27
Tanggal 28 Sep 2026
ID transaksi 0420260928132..
Jumlah Rp50.0O0
Total Rp50.0o0
Dikirim dari app GoPay.
Dapetin gratis transfer 100x/
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.kind, TxKind.transfer);
    expect(parsed.sourceApp, 'GOPAY');
    expect(parsed.nominal, 'Rp 50.000');
    expect(parsed.appTotal, 'Rp 50.000');
    expect(MoneyFormat.inputText(parsed.nominal), '50.000');
  });

  test('nominal GoPay tetap benar bila titik ribuan utuh', () {
    const raw = '''
gopay
Rp50.000
Ditransfer ke Siti Aminah
Jumlah Rp50.000
Total Rp50.000
''';
    final parsed = ReceiptScanner.parseText(raw);
    expect(parsed.nominal, 'Rp 50.000');
  });

  test(
    'nominal GoPay tetap utuh saat pemisah OCR berupa spasi atau titik tengah',
    () {
      for (final amount in ['Rp500 00', 'Rp50·000', 'Rp500.00']) {
        final parsed = ReceiptScanner.parseText('''
gopay
Ditransfer ke Siti Aminah
Jumlah
$amount
''');
        expect(parsed.nominal, 'Rp 50.000', reason: amount);
      }
    },
  );

  test('blocklist membuang baris yang mengandung frasa', () {
    const raw = '''
Bukti Transaksi
Jumlah Transfer
Rp10.000
Ke
Budi Santoso
catatan internal rahasia
''';
    final parsed = ReceiptScanner.parseText(
      raw,
      blockedPhrases: {'catatan internal'},
    );
    expect(parsed.lines.any((l) => l.contains('rahasia')), isFalse);
    expect(parsed.penerima, 'Budi Santoso');
  });

  test('cetak PLN token satu baris tebal, tidak dipecah', () {
    final lines = buildReceiptLines(
      const ReceiptDraft(
        kind: TxKind.plnToken,
        namaToko: 'Daru Cell',
        sourceApp: 'GOPAY',
        nominal: 'Rp 100.000',
        noMeterOrIdpel: '12345678901',
        token: '1111 2222\n3333-4444 5555',
        tanggal: '30 Sep 2026',
        totalBayar: 'Rp 105.000',
      ),
    );

    final tokenIndex = lines.indexWhere((l) => l.size == plnTokenPrintSize);
    expect(tokenIndex, greaterThan(0));
    final tokenLine = lines[tokenIndex];
    expect(lines.where((l) => l.size == plnTokenPrintSize), hasLength(1));
    expect(tokenLine.text, '1111-2222-3333-4444-5555');
    expect(tokenLine.text.contains('\n'), isFalse);
    expect(tokenLine.text.length, lessThanOrEqualTo(receiptColumns));
    expect(tokenLine.align, 1);
    expect(lines[tokenIndex - 1].text, isEmpty);
    expect(lines[tokenIndex + 1].text, isEmpty);

    for (final label in ['IDPEL / Meter', 'Tanggal', 'Nominal']) {
      final row = lines.singleWhere((l) => l.text.startsWith(label));
      expect(row.size, 1, reason: label);
      expect(row.text.length, receiptColumns, reason: label);
    }
    expect(
      lines.any(
        (l) => l.text.contains('TOTAL BAYAR') && l.text.contains('105.000'),
      ),
      isTrue,
    );
    expect(lines.any((l) => l.text.startsWith('Dari')), isFalse);
  });

  test('baris transfer rata kiri kanan dengan ukuran TRANSFER', () {
    final lines = buildReceiptLines(
      const ReceiptDraft(
        kind: TxKind.transfer,
        namaToko: 'Daru Cell',
        sourceApp: 'DANA',
        nominal: '32000',
        penerima: 'Budi Santoso',
        rekeningOrPhone: '081234567890',
        tanggal: '30 Sep 2026',
        totalBayar: '35000',
      ),
    );

    for (final label in ['TRANSFER', 'Ke', 'Transfer ke', 'Tanggal', 'Dari']) {
      final row = lines.singleWhere((l) => l.text.startsWith(label));
      expect(row.size, 1, reason: label);
      expect(row.text.length, receiptColumns, reason: label);
      expect(
        row.text.trimRight().endsWith(
          row.text.trim().split(RegExp(r'\s+')).last,
        ),
        isTrue,
      );
    }
    expect(
      lines.singleWhere((l) => l.text.startsWith('Transfer ke')).text,
      contains('081234567890'),
    );
  });

  test('nomor bertopeng tercetak dengan label Transfer ke', () {
    final lines = buildReceiptLines(
      const ReceiptDraft(
        kind: TxKind.transfer,
        namaToko: 'Daru Cell',
        sourceApp: 'BCA',
        nominal: '32000',
        penerima: 'Ahmad',
        rekeningOrPhone: '******1466',
        totalBayar: '35000',
      ),
    );

    final row = lines.singleWhere((l) => l.text.startsWith('Transfer ke'));
    expect(row.text, contains('******1466'));
    expect(row.size, 1);
    expect(lines.any((l) => l.text.startsWith('No. HP')), isFalse);
    expect(lines.any((l) => l.text.startsWith('Rekening')), isFalse);
  });
}
