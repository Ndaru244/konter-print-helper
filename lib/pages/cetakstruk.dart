import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:cetak_struk/models/parsed_receipt.dart";
import "package:cetak_struk/services/money_format.dart";
import "package:cetak_struk/services/ocr_blocklist_store.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/services/receipt_print.dart";
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
  final OcrBlocklistStore _blocklistStore = OcrBlocklistStore();
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController(
    text: "Simpan struk ini sebagai bukti transaksi yang sah.",
  );
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _penerimaController = TextEditingController();
  final TextEditingController _rekeningController = TextEditingController();
  final TextEditingController _idpelController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();

  TxKind _kind = TxKind.other;
  String _appSource = "UMUM";
  String _rawText = "";
  List<String> _lines = const [];
  final Set<String> _blocked = {};
  bool _isProcessing = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterService>().init();
    });
    _boot();
  }

  Future<void> _boot() async {
    await _loadNamaToko();
    final blocked = await _blocklistStore.load();
    if (!mounted) return;
    setState(() => _blocked.addAll(blocked));
    await _processImage();
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _catatanController.dispose();
    _nominalController.dispose();
    _penerimaController.dispose();
    _rekeningController.dispose();
    _idpelController.dispose();
    _tokenController.dispose();
    _tanggalController.dispose();
    _totalController.dispose();
    _otherController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _loadNamaToko() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _namaTokoController.text = prefs.getString("namaToko") ?? "Daru Cell";
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
      final result = ReceiptScanner.process(
        recognizedText,
        blockedPhrases: _blocked,
      );
      if (!mounted) return;
      _applyReceipt(result);
    } catch (e) {
      debugPrint("Error OCR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal membaca struk. Coba foto yang lebih jelas."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _applyReceipt(ParsedReceipt result) {
    setState(() {
      _kind = result.kind;
      _appSource = result.sourceApp;
      _rawText = result.rawText;
      _lines = result.lines;
      _nominalController.text = MoneyFormat.inputText(result.nominal);
      _penerimaController.text = result.penerima ?? "";
      _rekeningController.text = result.rekeningOrPhone ?? "";
      _idpelController.text = result.noMeterOrIdpel ?? "";
      _tokenController.text = result.token ?? "";
      _tanggalController.text = result.tanggal ?? "";
      _totalController.text = MoneyFormat.inputText(
        result.nominal ?? result.appTotal,
      );
      _otherController.text = result.lines.join("\n");
    });
  }

  Future<void> _blockLine(String line) async {
    final phrase = OcrBlocklistStore.normalize(line);
    if (phrase.isEmpty) return;
    setState(() {
      _blocked.add(phrase);
      _lines = _lines
          .where((row) => !row.toLowerCase().contains(phrase))
          .toList();
      _otherController.text = _otherController.text
          .split("\n")
          .where((row) => !row.toLowerCase().contains(phrase))
          .join("\n");
    });
    await _blocklistStore.save(_blocked);
  }

  Future<void> _printStruk() async {
    if (_isPrinting) return;
    final printerService = context.read<PrinterService>();
    await _saveNamaToko();
    if (!mounted) return;

    if (MoneyFormat.parse(_totalController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi total bayar dengan angka.")),
      );
      return;
    }

    if (!printerService.isConnected && !printerService.isDummyMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Printer belum terhubung!")),
      );
      return;
    }

    final job = buildReceiptLines(
      ReceiptDraft(
        kind: _kind,
        namaToko: _namaTokoController.text.trim().isEmpty
            ? "Daru Cell"
            : _namaTokoController.text.trim(),
        sourceApp: _appSource,
        totalBayar: _totalController.text,
        nominal: _nominalController.text,
        penerima: _penerimaController.text,
        rekeningOrPhone: _rekeningController.text,
        noMeterOrIdpel: _idpelController.text,
        token: _tokenController.text,
        tanggal: _tanggalController.text,
        catatan: _catatanController.text,
        otherLines: _otherController.text.split("\n"),
      ),
    );

    setState(() => _isPrinting = true);
    try {
      if (printerService.isDummyMode) {
        debugPrint(">>> DUMMY STRUK <<<");
        for (final line in job) {
          debugPrint(line.text);
        }
      } else {
        final bt = printerService.bluetooth;
        bt.printNewLine();
        for (final line in job) {
          bt.printCustom(line.text, line.size, line.align);
        }
        bt.printNewLine();
        bt.printNewLine();
      }
    } catch (e) {
      debugPrint("Error Print: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mencetak: $e")),
        );
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputCard(
                    title: "Jenis Transaksi",
                    icon: Icons.category_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<TxKind>(
                          style: SegmentedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            textStyle: theme.textTheme.bodyLarge,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: TxKind.transfer,
                              label: Text("Transfer"),
                            ),
                            ButtonSegment(
                              value: TxKind.plnToken,
                              label: Text("PLN"),
                            ),
                            ButtonSegment(
                              value: TxKind.other,
                              label: Text("Lain"),
                            ),
                          ],
                          selected: {_kind},
                          onSelectionChanged: (value) {
                            setState(() => _kind = value.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Kalau tebakannya salah, pilih jenis di atas.",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Dari aplikasi: $_appSource",
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Yang dibayar pelanggan",
                    icon: Icons.payments_outlined,
                    child: AppTextField.rupiah(
                      label: "Total bayar",
                      controller: _totalController,
                      helperText:
                          "Ketik angka saja. Titik ribuan muncul sendiri. Contoh 105000 menjadi 105.000.",
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Isi struk",
                    icon: Icons.receipt_long_outlined,
                    child: Column(children: _fieldsForKind()),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Nama toko",
                    icon: Icons.store_outlined,
                    child: AppTextField(
                      label: "Nama toko di atas struk",
                      controller: _namaTokoController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Catatan",
                    icon: Icons.notes_outlined,
                    child: AppTextField(
                      label: "Tulisan di bawah struk",
                      controller: _catatanController,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: Text(
                      "Bersihkan tulisan scan",
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      "Buka hanya jika ada tulisan yang tidak perlu",
                      style: theme.textTheme.bodyMedium,
                    ),
                    children: [
                      _buildLineChips(theme),
                      const SizedBox(height: 8),
                    ],
                  ),
                  ExpansionTile(
                    title: Text(
                      "Teks OCR mentah",
                      style: theme.textTheme.titleMedium,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: "Salin",
                          onPressed: _rawText.isEmpty
                              ? null
                              : () {
                                  Clipboard.setData(
                                    ClipboardData(text: _rawText),
                                  );
                                },
                          icon: const Icon(Icons.copy),
                        ),
                      ),
                      SelectableText(
                        _rawText.isEmpty ? "Tidak ada teks." : _rawText,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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

  List<Widget> _fieldsForKind() {
    final fields = <Widget>[];
    void add(
      String label,
      TextEditingController controller, {
      int maxLines = 1,
      String? helperText,
      bool money = false,
    }) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: money
              ? AppTextField.rupiah(
                  label: label,
                  controller: controller,
                  helperText: helperText,
                )
              : AppTextField(
                  label: label,
                  controller: controller,
                  maxLines: maxLines,
                  helperText: helperText,
                ),
        ),
      );
    }

    switch (_kind) {
      case TxKind.transfer:
        add(
          "Nominal di struk",
          _nominalController,
          money: true,
          helperText: "Jumlah di aplikasi, sebelum admin konter.",
        );
        add("Nama penerima", _penerimaController);
        add("Rekening atau nomor HP", _rekeningController);
        add("Tanggal", _tanggalController);
      case TxKind.plnToken:
        add(
          "Nominal di struk",
          _nominalController,
          money: true,
          helperText: "Harga token di aplikasi, sebelum admin konter.",
        );
        add("Nomor meter / IDPEL", _idpelController);
        add(
          "Token PLN",
          _tokenController,
          helperText: "20 angka. Boleh pakai tanda minus.",
        );
        add("Tanggal", _tanggalController);
      case TxKind.other:
        add(
          "Nominal di struk",
          _nominalController,
          money: true,
          helperText: "Kosongkan jika tidak ada nominal.",
        );
        add("Catatan", _otherController, maxLines: 6);
        add("Tanggal", _tanggalController);
    }
    return fields;
  }

  Widget _buildLineChips(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tekan ikon blokir untuk menyembunyikan tulisan itu di scan berikutnya.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (_lines.isEmpty)
            Text("Tidak ada baris.", style: theme.textTheme.bodyMedium)
          else
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodyLarge),
                    ),
                    IconButton(
                      tooltip: "Blokir frasa",
                      onPressed: () => _blockLine(line),
                      icon: const Icon(Icons.block),
                    ),
                  ],
                ),
              ),
        ],
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
