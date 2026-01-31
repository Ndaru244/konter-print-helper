import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cetak_struk/services/printer_service.dart';
import 'package:cetak_struk/services/receipt_scanner.dart';

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
    text: "Simpan struk ini sebagai bukti transaksi yang sah.",
  );
  final TextEditingController _scanDataController = TextEditingController();

  String _appSource = "UMUM";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterService>().init();
    });

    _loadNamaToko();
    _processImage();
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _catatanController.dispose();
    _scanDataController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _loadNamaToko() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaTokoController.text = prefs.getString("namaToko") ?? "NAMA TOKO ANDA";
    });
  }

  Future<void> _saveNamaToko() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("namaToko", _namaTokoController.text);
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(File(widget.imagePath));
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final result = ReceiptScanner.process(recognizedText);

      setState(() {
        _appSource = result.source;
        _scanDataController.text = result.processedText;
      });
    } catch (e) {
      debugPrint("Error OCR: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _printStruk() async {
    final printerService = Provider.of<PrinterService>(context, listen: false);
    await _saveNamaToko();

    if (_scanDataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data kosong, tidak ada yang dicetak.")),
      );
      return;
    }

    if (!printerService.isConnected && !printerService.isDummyMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Printer belum terhubung! Cek koneksi.")),
      );
      return;
    }

    if (printerService.isDummyMode) {
      debugPrint("\n\n");
      debugPrint("========================================");
      debugPrint("      SIMULASI CETAK STRUK (DUMMY)      ");
      debugPrint("========================================");

      debugPrint(_namaTokoController.text.toUpperCase());
      debugPrint("-" * 32);
      debugPrint("SUMBER: $_appSource");
      debugPrint("");

      final lines = _scanDataController.text.split('\n');
      for (var line in lines) {
        if (line.contains(":")) {
          final parts = line.split(":");
          if (parts.length >= 2) {
            String key = parts[0].trim();
            String val = parts.sublist(1).join(":").trim();

            int spaceCount = 32 - key.length - val.length;
            if (spaceCount < 1) spaceCount = 1;
            String spaces = " " * spaceCount;

            debugPrint("$key$spaces$val");
          } else {
            debugPrint(line);
          }
        } else {
          debugPrint(line);
        }
      }

      // Footer
      debugPrint("-" * 32);
      if (_catatanController.text.isNotEmpty) {
        debugPrint("Catatan:");
        debugPrint(_catatanController.text);
        debugPrint("-" * 32);
      }
      debugPrint("          TERIMA KASIH          ");
      debugPrint("========================================");
      debugPrint("\n\n");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("[DUMMY] Struk berhasil dicetak ke Console!")),
      );
      return;
    }

    final bt = printerService.bluetooth;

    try {
      bt.printNewLine();
      bt.printCustom(_namaTokoController.text.toUpperCase(), 2, 1);
      bt.printCustom("-" * 32, 1, 1);

      bt.printCustom("SUMBER: $_appSource", 1, 1);
      bt.printNewLine();

      final lines = _scanDataController.text.split('\n');
      for (var line in lines) {
        if (line.contains(":")) {
          final parts = line.split(":");
          if (parts.length >= 2) {
            String key = parts[0].trim();
            String val = parts.sublist(1).join(":").trim();
            bool isNominal = key.toLowerCase().contains("nominal");

            int dotsCount = 32 - key.length - val.length;
            if (dotsCount < 1) dotsCount = 1;
            String dots = " " * dotsCount;

            int size = isNominal ? 1 : 0;
            bt.printCustom("$key$dots$val", size, 0);

          } else {
            bt.printCustom(line, 1, 0);
          }
        } else {
          bt.printCustom(line, 1, 0);
        }
      }

      bt.printNewLine();
      bt.printCustom("-" * 32, 1, 1);

      if (_catatanController.text.isNotEmpty) {
        bt.printCustom(_catatanController.text, 1, 1);
        bt.printCustom("-" * 32, 1, 1);
      }

      bt.printCustom("TERIMA KASIH", 1, 1);
      bt.printNewLine();
      bt.printNewLine();

    } catch (e) {
      debugPrint("Error Print Native: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mencetak: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Struk"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            width: double.infinity,
            color: printerService.isConnected ? Colors.green : Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              printerService.isConnected ? "SIAP CETAK" : "PRINTER OFF",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
      body: _isProcessing
          ? const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Sedang membaca struk..."),
        ],
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInput("Nama Toko", _namaTokoController),
            const SizedBox(height: 12),
            _buildInput(
              "Data Transaksi (Bisa diedit manual)",
              _scanDataController,
              minLines: 5,
              maxLines: null,
            ),
            const SizedBox(height: 12),
            _buildInput("Catatan Kaki", _catatanController, maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _printStruk,
                icon: const Icon(Icons.print),
                label: const Text("CETAK SEKARANG"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      String label,
      TextEditingController controller,
      {
        int minLines = 1,
        int? maxLines = 1,
      }
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,

          keyboardType: (maxLines == null || maxLines > 1)
              ? TextInputType.multiline
              : TextInputType.text,

          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}