import "package:flutter/material.dart";
import "package:cetak_struk/models/parsed_receipt.dart";
import "package:cetak_struk/services/receipt_print.dart";
import "package:cetak_struk/services/store_profile.dart";
import "package:cetak_struk/theme/app_colors.dart";
import "package:cetak_struk/widgets/app_bottom_bar.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_snackbar.dart";
import "package:cetak_struk/widgets/app_text_field.dart";
import "package:cetak_struk/widgets/receipt_preview.dart";

class SettingsStrukPage extends StatefulWidget {
  const SettingsStrukPage({super.key});

  @override
  State<SettingsStrukPage> createState() => _SettingsStrukPageState();
}

class _SettingsStrukPageState extends State<SettingsStrukPage> {
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  TxKind _kind = TxKind.transfer;
  bool _loading = true;
  bool _saving = false;
  bool _allowPop = false;
  bool _notifiedDirty = false;
  String _savedNama = "";
  String _savedCatatan = "";
  late final Listenable _previewListenable = Listenable.merge([
    _namaTokoController,
    _catatanController,
  ]);

  bool get _dirty =>
      _namaTokoController.text != _savedNama ||
      _catatanController.text != _savedCatatan;

  @override
  void initState() {
    super.initState();
    _namaTokoController.addListener(_onDraftChanged);
    _catatanController.addListener(_onDraftChanged);
    _load();
  }

  void _onDraftChanged() {
    final dirty = _dirty;
    if (dirty == _notifiedDirty || !mounted) return;
    setState(() => _notifiedDirty = dirty);
  }

  Future<void> _load() async {
    final profile = await StoreProfile.load();
    if (!mounted) return;
    _savedNama = profile.namaToko;
    _savedCatatan = profile.catatan;
    _namaTokoController.text = profile.namaToko;
    _catatanController.text = profile.catatan;
    setState(() {
      _loading = false;
      _notifiedDirty = _dirty;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await StoreProfile.save(
      namaToko: _namaTokoController.text,
      catatan: _catatanController.text,
    );
    if (!mounted) return;
    final saved = await StoreProfile.load();
    _savedNama = saved.namaToko;
    _savedCatatan = saved.catatan;
    _namaTokoController.text = saved.namaToko;
    _catatanController.text = saved.catatan;
    setState(() {
      _saving = false;
      _notifiedDirty = _dirty;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(appSnackBar(context, "Nama toko dan catatan disimpan."));
  }

  @override
  void dispose() {
    _namaTokoController.removeListener(_onDraftChanged);
    _catatanController.removeListener(_onDraftChanged);
    _namaTokoController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty || _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _allowPop) return;
        final discard = await _confirmDiscard();
        if (discard != true || !mounted) return;
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Struk toko")),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<TxKind>(
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      textStyle: theme.textTheme.bodyLarge,
                    ),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TxKind.transfer,
                        label: Text("Transfer"),
                      ),
                      ButtonSegment(value: TxKind.plnToken, label: Text("PLN")),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (value) {
                      setState(() => _kind = value.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _previewListenable,
                    builder: (context, _) {
                      final lines = buildReceiptLines(
                        previewReceiptDraft(
                          kind: _kind,
                          namaToko: _namaTokoController.text,
                          catatan: _catatanController.text,
                        ),
                      );
                      return ReceiptPreview(lines: lines);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppCard(
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
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: AppBottomBar(
          child: AppButton.primary(
            icon: Icons.save_outlined,
            label: "SIMPAN",
            loading: _saving,
            onPressed: _loading ? null : _save,
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDiscard() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Perubahan belum disimpan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Nama toko atau catatan belum disimpan. Buang perubahan ini?",
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Tetap di sini"),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dangerFill,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Buang perubahan"),
              ),
            ],
          ),
        );
      },
    );
  }
}
