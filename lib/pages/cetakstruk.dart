import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/pages/bantuan_page.dart";
import "package:cetak_struk/services/store_profile.dart";
import "package:cetak_struk/brand.dart";
import "package:cetak_struk/models/parsed_receipt.dart";
import "package:cetak_struk/services/money_format.dart";
import "package:cetak_struk/services/ocr_blocklist_store.dart";
import "package:cetak_struk/services/ocr_image_prep.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/services/receipt_print.dart";
import "package:cetak_struk/services/receipt_scanner.dart";
import "package:cetak_struk/widgets/app_bottom_bar.dart";
import "package:cetak_struk/widgets/app_snackbar.dart";
import "package:cetak_struk/widgets/receipt_preview.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_icon_tile.dart";
import "package:cetak_struk/widgets/app_list_tile.dart";
import "package:cetak_struk/widgets/app_status_banner.dart";
import "package:cetak_struk/widgets/app_text_field.dart";

/// Dialog jam. Skala teks di bawah 1 membuat tinggi mode ketik lebih pendek
/// dari batas Flutter (216), lalu ikon keyboard melempar error constraint.
Widget buildTimePicker(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(
      textScaler: media.textScaler.clamp(
        minScaleFactor: 1,
        maxScaleFactor: 1.1,
      ),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        timePickerTheme: const TimePickerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      child: child!,
    ),
  );
}

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
  final TextEditingController _catatanController = TextEditingController();
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
    await _loadProfile();
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

  Future<void> _loadProfile() async {
    final profile = await StoreProfile.load();
    if (!mounted) return;
    _namaTokoController.text = profile.namaToko;
    _catatanController.text = profile.catatan;
  }

  Future<void> _saveProfile() async {
    await StoreProfile.save(
      namaToko: _namaTokoController.text,
      catatan: _catatanController.text,
    );
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);
    OcrPreparedImage? prepared;
    try {
      prepared = await OcrImagePrep.prepare(widget.imagePath);
      final inputImage = InputImage.fromFile(File(prepared.path));
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
          appSnackBar(
            context,
            "Gagal membaca struk. Coba foto yang lebih jelas.",
          ),
        );
      }
    } finally {
      final copy = prepared;
      if (copy != null && copy.temporary) {
        try {
          await File(copy.path).delete();
        } catch (e) {
          debugPrint("Gagal hapus salinan OCR: $e");
        }
      }
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

  Future<void> _pickTanggal() async {
    final current = _parseTanggal(_tanggalController.text);
    final hadClock = RegExp(r"\d{1,2}:\d{2}").hasMatch(_tanggalController.text);
    final now = DateTime.now();
    final first = DateTime(now.year - 5);
    final last = DateTime(now.year + 1);
    var initial = current ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: "Tanggal transaksi",
      cancelText: "Batal",
      confirmText: "Lanjut",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: "Jam transaksi",
      cancelText: "Lewati jam",
      confirmText: "Pakai",
      builder: buildTimePicker,
    );
    if (!mounted) return;
    if (time == null) {
      _tanggalController.text = hadClock && current != null
          ? _formatTanggal(
              date,
              clock: TimeOfDay(hour: current.hour, minute: current.minute),
            )
          : _formatTanggal(date);
      return;
    }
    _tanggalController.text = _formatTanggal(date, clock: time);
  }

  ReceiptDraft _draft() {
    return ReceiptDraft(
      kind: _kind,
      namaToko: _namaTokoController.text.trim().isEmpty
          ? Brand.name
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
    );
  }

  void _previewStruk() {
    final lines = buildReceiptLines(_draft());
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  "Pratinjau struk",
                  style: theme.textTheme.titleLarge,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: ReceiptPreview(lines: lines),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton.secondary(
                  label: "Tutup",
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printStruk() async {
    if (_isPrinting) return;
    final printerService = context.read<PrinterService>();
    await _saveProfile();
    if (!mounted) return;

    if (MoneyFormat.parse(_totalController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appSnackBar(context, "Isi total bayar dengan angka."));
      return;
    }

    if (!printerService.isConnected && !printerService.isDummyMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appSnackBar(context, "Printer belum terhubung!"));
      return;
    }

    final job = buildReceiptLines(_draft());

    setState(() => _isPrinting = true);
    try {
      await printerService.printLines(job);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(
          context,
          printerService.isDummyMode
              ? "Struk contoh berhasil."
              : "Struk dikirim ke printer.",
        ),
      );
    } catch (e) {
      debugPrint("Error Print: $e");
      if (mounted) {
        final message = e is PrintJobException
            ? e.message
            : "Gagal mencetak: $e";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(appSnackBar(context, message));
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
                  const AppStatusBanner(
                    inset: true,
                    tone: AppStatusTone.info,
                    icon: Icons.info_outline,
                    message: "Hasil scan bisa saja salah.",
                    subtitle:
                        "Cek nominal, nama, rekening/HP, dan tanggal. Teks hasil scan serta foto ada di bagian paling bawah halaman (scroll ke bawah), lalu perbaiki isian sebelum cetak.",
                  ),
                  AppListTile(
                    leading: const AppIconTile(icon: Icons.help_outline),
                    title: "Bantuan",
                    subtitle: "Lapor bug atau e-wallet yang belum didukung",
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BantuanPage()),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    title: "Isi transaksi",
                    icon: Icons.receipt_long_outlined,
                    child: Column(children: _fieldsForKind()),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Toko dan catatan",
                    icon: Icons.store_outlined,
                    child: Column(
                      children: [
                        AppTextField(
                          label: "Nama toko di atas struk",
                          controller: _namaTokoController,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: "Tulisan di bawah struk",
                          controller: _catatanController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    title: "Teks hasil scan",
                    icon: Icons.article_outlined,
                    trailing: IconButton(
                      tooltip: "Salin",
                      onPressed: _rawText.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _rawText));
                            },
                      icon: const Icon(Icons.copy),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bandingkan dengan isian di atas.",
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(
                                _rawText.isEmpty
                                    ? "Tidak ada teks."
                                    : _rawText.replaceAll("\r\n", "\n"),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPhotoCard(theme),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomBar(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: AppButton.secondary(
                  icon: Icons.visibility_outlined,
                  label: "Pratinjau",
                  onPressed: busy ? null : _previewStruk,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                icon: Icons.print,
                label: "Cetak",
                loading: _isPrinting,
                onPressed: busy ? null : _printStruk,
              ),
            ),
          ],
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
      bool dateTime = false,
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
                  readOnly: dateTime,
                  onTap: dateTime ? _pickTanggal : null,
                  suffixIcon: dateTime
                      ? const Icon(Icons.calendar_month_outlined)
                      : null,
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
        add(
          "Tanggal / waktu",
          _tanggalController,
          dateTime: true,
          helperText: "Ketuk untuk memilih tanggal dan jam transaksi di struk.",
        );
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
        add(
          "Tanggal / waktu",
          _tanggalController,
          dateTime: true,
          helperText: "Ketuk untuk memilih tanggal dan jam transaksi di struk.",
        );
      case TxKind.other:
        add(
          "Nominal di struk",
          _nominalController,
          money: true,
          helperText: "Kosongkan jika tidak ada nominal.",
        );
        add("Catatan", _otherController, maxLines: 6);
        add(
          "Tanggal / waktu",
          _tanggalController,
          dateTime: true,
          helperText: "Ketuk untuk memilih tanggal dan jam transaksi di struk.",
        );
    }
    return fields;
  }

  // UI disembunyikan. Kode blokir frasa tetap dipakai lewat method ini.
  // ignore: unused_element
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

  Widget _buildPhotoCard(ThemeData theme) {
    final path = widget.imagePath;
    final file = File(path);
    final ready = path.isNotEmpty && file.existsSync();
    return _buildInputCard(
      title: "Foto struk",
      icon: Icons.photo_outlined,
      child: ready
          ? LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final logical =
                    constraints.maxWidth.isFinite && constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final cacheWidth = (logical * dpr).round().clamp(1, 4096);
                return InkWell(
                  onTap: () => _zoomPhoto(file, cacheWidth),
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      cacheWidth: cacheWidth,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Text(
                        "Foto tidak bisa ditampilkan.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                );
              },
            )
          : Text("Foto struk tidak ada.", style: theme.textTheme.bodyMedium),
    );
  }

  void _zoomPhoto(File file, int cacheWidth) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: "Tutup",
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    cacheWidth: (cacheWidth * 2).clamp(1, 4096),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
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
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

const _shortMonths = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "Mei",
  "Jun",
  "Jul",
  "Agu",
  "Sep",
  "Okt",
  "Nov",
  "Des",
];

DateTime? _parseTanggal(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final named = RegExp(
    r"(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})(?:\s+(\d{1,2}):(\d{2}))?",
  ).firstMatch(text);
  if (named != null) {
    final month = _monthIndex(named.group(2)!);
    final day = int.tryParse(named.group(1)!);
    final year = int.tryParse(named.group(3)!);
    if (month != null && day != null && year != null) {
      return DateTime(
        year,
        month,
        day,
        int.tryParse(named.group(4) ?? "") ?? 0,
        int.tryParse(named.group(5) ?? "") ?? 0,
      );
    }
  }
  final numeric = RegExp(
    r"(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:\s+(\d{1,2}):(\d{2}))?",
  ).firstMatch(text);
  if (numeric == null) return null;
  return DateTime(
    int.parse(numeric.group(3)!),
    int.parse(numeric.group(2)!),
    int.parse(numeric.group(1)!),
    int.tryParse(numeric.group(4) ?? "") ?? 0,
    int.tryParse(numeric.group(5) ?? "") ?? 0,
  );
}

int? _monthIndex(String name) {
  const months = {
    "jan": 1,
    "januari": 1,
    "feb": 2,
    "februari": 2,
    "mar": 3,
    "maret": 3,
    "apr": 4,
    "april": 4,
    "mei": 5,
    "may": 5,
    "jun": 6,
    "juni": 6,
    "jul": 7,
    "juli": 7,
    "agu": 8,
    "agt": 8,
    "agustus": 8,
    "aug": 8,
    "sep": 9,
    "september": 9,
    "okt": 10,
    "oktober": 10,
    "oct": 10,
    "nov": 11,
    "november": 11,
    "des": 12,
    "desember": 12,
    "dec": 12,
  };
  return months[name.toLowerCase()];
}

String _formatTanggal(DateTime date, {TimeOfDay? clock}) {
  final text = "${date.day} ${_shortMonths[date.month - 1]} ${date.year}";
  if (clock == null) return text;
  final hour = clock.hour.toString().padLeft(2, "0");
  final minute = clock.minute.toString().padLeft(2, "0");
  return "$text $hour:$minute";
}
