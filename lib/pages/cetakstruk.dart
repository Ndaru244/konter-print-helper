import 'dart:async';
import 'dart:io';
import 'package:cetak_struk/services/printer_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CetakStrukPage extends StatefulWidget {
  final String imagePath;
  const CetakStrukPage({super.key, required this.imagePath});

  @override
  State<CetakStrukPage> createState() => _CetakStrukPageState();
}

class _CetakStrukPageState extends State<CetakStrukPage> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController(
    text: "Struk Ini Merupakan Bukti Transaksi Yang Sah Harap Di Simpan!",
  );
  // Tambahkan TextEditingController baru untuk data hasil scan
  final TextEditingController _scanDataController = TextEditingController();
  String _appSource = "Tidak Dikenali";
  bool _isProcessing = false;
  bool _canPrint = false;

  @override
  void initState() {
    super.initState();

    final printerService = context.read<PrinterService>();
    printerService.init();

    _loadNamaToko();
    _processImage();

    Timer.periodic(const Duration(seconds: 3), (_) {
      printerService.checkConnection();
    });
  }

  Future<void> _loadNamaToko() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNama = prefs.getString("namaToko");
    if (savedNama != null && savedNama.isNotEmpty) {
      _namaTokoController.text = savedNama;
    } else {
      _namaTokoController.text = "Nama Toko";
    }
  }

  Future<void> _saveNamaToko() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("namaToko", _namaTokoController.text);
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _catatanController.dispose();
    _scanDataController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _canPrint = false;
      _appSource = "Tidak Dikenali";
    });

    final inputImage = InputImage.fromFile(File(widget.imagePath));
    final recognizedText = await _textRecognizer.processImage(inputImage);
    debugPrint("=== HASIL OCR MENTAH ===");
    debugPrint(recognizedText.text);

    final lowerText = recognizedText.text.toLowerCase();
    if (lowerText.contains("dana")) {
      _appSource = "Dari DANA";
    } else if (lowerText.contains("gopay")) {
      _appSource = "Dari GoPay";
    } else if (lowerText.contains("seabank")) {
      _appSource = "Dari SeaBank";
    }

    final lines = recognizedText.text.split('\n');
    final processedLines = <String>{};

    final regexNamaPenerimaDana = RegExp(r'ke\s(.+?)\s-');
    final matchNamaDana = regexNamaPenerimaDana.firstMatch(recognizedText.text);
    if (matchNamaDana != null && matchNamaDana.group(1) != null) {
      processedLines.add("Penerima: ${matchNamaDana.group(1)!.trim()}");
    }

    final regexNamaPenerimaGopay = RegExp(r'Ditransfer ke\s(.+)');
    final matchNamaGopay = regexNamaPenerimaGopay.firstMatch(
      recognizedText.text,
    );
    if (matchNamaGopay != null && matchNamaGopay.group(1) != null) {
      processedLines.add("Penerima: ${matchNamaGopay.group(1)!.trim()}");
    }

    final regexNominal = RegExp(r'Rp(\d{1,3}(?:\.\d{3})*)');
    final matchNominal = regexNominal.firstMatch(recognizedText.text);
    if (matchNominal != null && matchNominal.group(0) != null) {
      processedLines.add("Nominal: ${matchNominal.group(0)!.trim()}");
    }

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || _isNoise(trimmedLine)) {
        continue;
      }
      processedLines.add(trimmedLine);
    }

    // Gabungkan semua baris menjadi satu string dengan baris baru
    final combinedData = processedLines.join('\n');
    _scanDataController.text = combinedData;

    debugPrint("=== HASIL OCR YANG DIFILTER ===");
    debugPrint(_scanDataController.text);

    setState(() {
      _isProcessing = false;
      _canPrint = true;
    });
  }

  bool _isNoise(String text) {
    final t = text.toLowerCase();

    final blacklist = [
      "gratis",
      "transfer",
      "selesai",
      "rincian transaksi",
      "detail transaksi",
      "no. transaksi",
      "id transaksi",
      "metode pembayaran",
      "waktu",
      "tanggal",
      "total",
      "jumlah",
      "unduh",
      "unduh dan bagikan",
      "chat dengan cs",
      "download on the",
      "app store",
      "get it on",
      "google play",
      "aplikasi ringan",
      "diamankan oleh",
      "protection",
      "id dana",
      "id order merchant",
      "external serial number",
      "harga tercantum",
      "sudah termasuk",
      "dikirim dari",
      "dapetin",
      "saldo",
      "detail",
      "akun",
      "nama",
      "biaya",
      "admin",
      "pembayaran",
      "kirim",
      "uang",
      "dari",
      "ke",
      "jumlah transfer",
      "no. referensi",
      "bukti transaksi",
      "metode transaksi",
      "waktu transaksi",
      "butuh bantuan?",
      "resi ini merupakan bukti transaksi yang sah",
      "realtime online",
      "odana",
      "transaksi berhasil!",
      "metode pembayaran",
      "detail penerima",
      "nama",
      "akun dana",
      "detail transaksi",
      "diamankan oleh",
      "dp",
      "smartpay",
      "da",
      "id order merchar",
      "status",
      "rincian transaksi",
      "gopay saldo",
      "dikirim dari app gopay. dapetin",
      "gratis transfer 100x/bulan!",
      "aplikasi ringan buat kebutuhan",
      "finansialmu.",
    ];

    if (t.isEmpty || t.length <= 2) {
      return true;
    }
    if (t.contains("bank") && RegExp(r'\d').hasMatch(t)) {
      return false;
    }
    if (t.contains("rp") && t.length > 10) {
      return false;
    }
    for (var keyword in blacklist) {
      if (t.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _printStruk() async {
    final printerService = Provider.of<PrinterService>(context, listen: false);

    await _saveNamaToko();

    if (!_canPrint) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Struk belum siap untuk dicetak.")),
      );
      return;
    }

    if (!printerService.isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Printer belum terhubung.")));
      return;
    }

    String formatText(String text, {int width = 32}) {
      return text.length > width ? text.substring(0, width) : text;
    }

    final bluetooth = printerService.bluetooth;

    bluetooth.printNewLine();
    bluetooth.printCustom(_namaTokoController.text, 2, 1); // Nama toko
    bluetooth.printCustom('-' * 32, 1, 1); // Garis pembatas

    if (_appSource != "Tidak Dikenali") {
      bluetooth.printCustom("Bukti Transfer $_appSource", 1, 1);
      bluetooth.printCustom('-' * 32, 1, 1);
    }

    // Isi hasil OCR
    for (var line in _scanDataController.text.split('\n')) {
      bluetooth.printCustom(formatText(line), 1, 0);
    }

    bluetooth.printCustom('-' * 32, 1, 1); // Garis pembatas

    // Catatan
    if (_catatanController.text.trim().isNotEmpty) {
      bluetooth.printCustom("Catatan:", 1, 0);
      bluetooth.printCustom(_catatanController.text, 1, 0);
      bluetooth.printCustom('-' * 32, 1, 1);
    }

    // Footer
    bluetooth.printCustom("- Terima Kasih -", 1, 1);

    bluetooth.printNewLine();
    bluetooth.printNewLine();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Struk sedang dicetak...")));
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text("Cetak Struk"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            color: printerService.isConnected
                ? Colors.green.shade100
                : Colors.red.shade100,
            padding: const EdgeInsets.all(8),
            child: Text(
              printerService.isConnected
                  ? "Printer Terhubung"
                  : "Printer belum tersambung",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: printerService.isConnected ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormSection(
                    "Nama Toko",
                    _namaTokoController,
                    "Masukkan Nama Toko",
                  ),
                  _buildScanDataField(), // Menggunakan field baru di sini
                  _buildFormSection(
                    "Catatan / Deskripsi",
                    _catatanController,
                    "Masukkan Catatan / Deskripsi",
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _printStruk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text(
                      "Print",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormSection(
    String title,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Widget baru untuk menampilkan data hasil scan dalam satu field
  Widget _buildScanDataField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Data Hasil Scan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _scanDataController,
          maxLines: null, // Ini akan membuat field menjadi textarea
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: "Data hasil scan akan muncul di sini.",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
