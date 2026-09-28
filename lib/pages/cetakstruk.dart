import "dart:io";
import "package:flutter/material.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/services/receipt_scanner.dart";
import "package:cetak_struk/widgets/app_bottom_bar.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_text_field.dart";

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
  bool _isPrinting = false;

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
    if (!mounted) return;
    setState(() {
      _namaTokoController.text =
          prefs.getString("namaToko") ?? "Daru Cell";
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
      if (!mounted) return;
      setState(() {
        _appSource = result.source;
        _scanDataController.text = result.processedText;
      });
    } catch (e) {
      debugPrint("Error OCR: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _printStruk() async {
    if (_isPrinting) return;
    final printerService = context.read<PrinterService>();
    await _saveNamaToko();
    if (!mounted) return;

    if (_scanDataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data kosong, tidak ada yang dicetak.")),
      );
      return;
    }

    if (!printerService.isConnected && !printerService.isDummyMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Printer belum terhubung!")));
      return;
    }

    setState(() => _isPrinting = true);
    final bt = printerService.bluetooth;
    try {
      bt.printNewLine();
      bt.printCustom(_namaTokoController.text.toUpperCase(), 2, 1);
      bt.printCustom("-" * 32, 1, 1);
      bt.printCustom("SUMBER: $_appSource", 1, 1);
      bt.printNewLine();

      final lines = _scanDataController.text.split("\n");
      for (var line in lines) {
        if (line.contains(":")) {
          final parts = line.split(":");
          if (parts.length >= 2) {
            String key = parts[0].trim();
            String val = parts.sublist(1).join(":").trim();
            bool isBig =
                key.toLowerCase().contains("nominal") ||
                key.toLowerCase().contains("total");

            int dotsCount = 32 - key.length - val.length;
            if (dotsCount < 1) dotsCount = 1;
            String dots = " " * dotsCount;
            bt.printCustom("$key$dots$val", isBig ? 1 : 0, 0);
          } else {
            bt.printCustom(line, 0, 0);
          }
        } else {
          bt.printCustom(line, 0, 0);
        }
      }

      bt.printNewLine();
      bt.printCustom("-" * 32, 1, 1);
      if (_catatanController.text.isNotEmpty) {
        bt.printCustom(_catatanController.text, 0, 1);
        bt.printCustom("-" * 32, 1, 1);
      }
      bt.printCustom("TERIMA KASIH", 1, 1);
      bt.printNewLine();
      bt.printNewLine();
    } catch (e) {
      debugPrint("Error Print: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mencetak: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _isProcessing || _isPrinting;
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Struk")),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Sedang membaca data struk...",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInputCard(
                    title: "Informasi Toko",
                    icon: Icons.store_outlined,
                    child: AppTextField(
                      label: "Nama Toko (Header)",
                      controller: _namaTokoController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Detail Transaksi",
                    icon: Icons.receipt_long_outlined,
                    child: AppTextField(
                      label: "Isi Struk (Bisa diedit)",
                      controller: _scanDataController,
                      minLines: 8,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Pesan Kaki",
                    icon: Icons.notes_outlined,
                    child: AppTextField(
                      label: "Catatan Bawah",
                      controller: _catatanController,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomBar(
        child: AppButton.primary(
          icon: Icons.print,
          label: "CETAK STRUK SEKARANG",
          loading: _isPrinting,
          onPressed: busy ? null : _printStruk,
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
