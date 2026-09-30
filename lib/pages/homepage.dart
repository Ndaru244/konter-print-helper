import "dart:async";
import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/brand.dart";
import "package:cetak_struk/pages/cetakstruk.dart";
import "package:cetak_struk/widgets/app_bottom_bar.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_empty_state.dart";
import "package:cetak_struk/widgets/app_icon_tile.dart";
import "package:cetak_struk/widgets/app_section_label.dart";
import "package:cetak_struk/widgets/app_status_banner.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onOpenPrinter, this.tabActive = true});

  /// Membuka tab Printer di shell. Dipakai banner saat printer putus.
  final VoidCallback? onOpenPrinter;

  /// False saat tab Beranda tertutup IndexedStack. Timer cek printer berhenti.
  final bool tabActive;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const platform = MethodChannel("app.share");

  bool fileReceived = false;
  String? filePath;
  Timer? _connectionTimer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  int? _previewCacheWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterService>().init();
      _checkInitialShared();
      _listenOnShare();
    });

    _syncConnectionTimer();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabActive == widget.tabActive) return;
    final showHome =
        widget.tabActive && _lifecycle == AppLifecycleState.resumed;
    _syncConnectionTimer();
    if (showHome && mounted) {
      context.read<PrinterService>().checkConnection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    final showHome = state == AppLifecycleState.resumed && widget.tabActive;
    _syncConnectionTimer();
    if (showHome && mounted) {
      context.read<PrinterService>().checkConnection();
    }
  }

  void _syncConnectionTimer() {
    final run = widget.tabActive && _lifecycle == AppLifecycleState.resumed;
    if (!run) {
      _connectionTimer?.cancel();
      _connectionTimer = null;
      return;
    }
    _connectionTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      context.read<PrinterService>().checkConnection();
    });
  }

  void _evictPreview(String? path) {
    if (path == null) return;
    final width = _previewCacheWidth;
    final ImageProvider provider = width == null
        ? FileImage(File(path))
        : ResizeImage(FileImage(File(path)), width: width);
    imageCache.evict(provider);
  }

  Future<void> _checkInitialShared() async {
    try {
      final path = await platform.invokeMethod<String>("getInitialShared");
      if (!mounted) return;
      if (path != null && path.isNotEmpty) {
        _showSharedFile(path);
      }
    } on PlatformException catch (e) {
      debugPrint("Error getInitialShared: ${e.message}");
    }
  }

  void _listenOnShare() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "onShare") {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty && mounted) {
          _showSharedFile(path);
        }
      }
    });
  }

  void _showSharedFile(String path) {
    if (filePath != null && filePath != path) _evictPreview(filePath);
    setState(() {
      fileReceived = true;
      filePath = path;
    });
  }

  void _removeFile() {
    final path = filePath;
    setState(() {
      fileReceived = false;
      filePath = null;
    });
    _evictPreview(path);
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    final connected = printerService.isConnected;
    final openPrinter = widget.onOpenPrinter;
    final printerName = printerService.selectedPrinter?.name?.trim();
    final shownName = (printerName == null || printerName.isEmpty)
        ? "Tidak diketahui"
        : printerName;

    return Scaffold(
      appBar: AppBar(title: Text(Brand.name)),
      body: Column(
        children: [
          _PrinterBanner(
            connected: connected,
            printerName: shownName,
            onOpenPrinter: openPrinter,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!fileReceived) ...[
                    _buildEmptyStateCard(),
                    const SizedBox(height: 24),
                    _buildGuideSection(),
                  ] else ...[
                    _buildFilePreviewCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: fileReceived && filePath != null
          ? AppBottomBar(
              child: AppButton.primary(
                icon: Icons.print,
                label: "LANJUT CETAK STRUK",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CetakStrukPage(imagePath: filePath!),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyStateCard() {
    return const AppCard(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: "Menunggu Struk...",
        description:
            "Buka e-wallet Anda (DANA, GoPay, Seabank, dll) lalu bagikan resi ke aplikasi ini.",
      ),
    );
  }

  Widget _buildGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: AppSectionLabel(label: "PANDUAN CEPAT"),
        ),
        _buildGuideItem(
          1,
          Icons.history,
          "Buka resi di e-wallet",
          "Di DANA, GoPay, Seabank, atau e-wallet lain, buka riwayat lalu pilih transaksi yang mau dicetak.",
        ),
        _buildGuideItem(
          2,
          Icons.share_outlined,
          "Bagikan gambar resi",
          "Ketuk Bagikan, lalu pilih ${Brand.name} di daftar aplikasi.",
        ),
        _buildGuideItem(
          3,
          Icons.touch_app_outlined,
          "Cetak dari halaman ini",
          "Gambar muncul di Beranda. Ketuk LANJUT CETAK STRUK di bawah.",
        ),
      ],
    );
  }

  Widget _buildGuideItem(int step, IconData icon, String title, String desc) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AppIconTile(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$step. $title", style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(desc, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: AppSectionLabel(label: "STRUK DITERIMA")),
            AppButton.destructive(
              icon: Icons.delete_outline,
              label: "Hapus",
              onPressed: _removeFile,
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final logical =
                    constraints.maxWidth.isFinite && constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final cacheWidth = (logical * dpr).round().clamp(1, 4096);
                _previewCacheWidth = cacheWidth;
                return Image.file(
                  File(filePath!),
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  cacheWidth: cacheWidth,
                  gaplessPlayback: true,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PrinterBanner extends StatelessWidget {
  const _PrinterBanner({
    required this.connected,
    required this.printerName,
    required this.onOpenPrinter,
  });

  final bool connected;
  final String printerName;
  final VoidCallback? onOpenPrinter;

  @override
  Widget build(BuildContext context) {
    final canOpen = !connected && onOpenPrinter != null;
    final banner = AppStatusBanner(
      tone: connected ? AppStatusTone.success : AppStatusTone.danger,
      center: !canOpen,
      icon: connected ? Icons.check_circle : Icons.warning_amber_rounded,
      message: connected ? "Printer: $printerName" : "Printer Tidak Terhubung",
      subtitle: canOpen ? "Ketuk untuk menyambungkan" : null,
      trailing: canOpen
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.error,
            )
          : null,
    );
    if (!canOpen) return banner;
    return Semantics(
      button: true,
      label: "Printer tidak terhubung. Ketuk untuk menyambungkan.",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenPrinter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: banner,
          ),
        ),
      ),
    );
  }
}
