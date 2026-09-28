import "dart:async";
import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/pages/settingprinter.dart";
import "package:cetak_struk/pages/cetakstruk.dart";
import "package:cetak_struk/pages/tentangaplikasi.dart";
import "package:cetak_struk/widgets/app_bottom_bar.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_empty_state.dart";
import "package:cetak_struk/widgets/app_icon_tile.dart";
import "package:cetak_struk/widgets/app_section_label.dart";
import "package:cetak_struk/widgets/app_status_banner.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const platform = MethodChannel("app.share");

  bool fileReceived = false;
  String? filePath;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterService>().init();
      _checkInitialShared();
      _listenOnShare();
    });

    _connectionTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      context.read<PrinterService>().checkConnection();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrinterService>().checkConnection();
    }
  }

  Future<void> _checkInitialShared() async {
    try {
      final path = await platform.invokeMethod<String>("getInitialShared");
      if (!mounted) return;
      if (path != null && path.isNotEmpty) {
        setState(() {
          fileReceived = true;
          filePath = path;
        });
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
          setState(() {
            fileReceived = true;
            filePath = path;
          });
        }
      }
    });
  }

  void _removeFile() {
    setState(() {
      fileReceived = false;
      filePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    final connected = printerService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daru Cell"),
        actions: [
          IconButton(
            tooltip: "Tentang aplikasi",
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TentangAplikasiPage()),
            ),
          ),
          IconButton(
            tooltip: "Pengaturan printer",
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSettingPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AppStatusBanner(
            tone: connected ? AppStatusTone.success : AppStatusTone.danger,
            center: true,
            icon: connected ? Icons.check_circle : Icons.warning_amber_rounded,
            message: connected
                ? "Printer: ${printerService.selectedPrinter?.name}"
                : "Printer Tidak Terhubung",
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
          Icons.history,
          "Buka Riwayat Transaksi",
          "Cari transaksi yang ingin dicetak di DANA/GoPay.",
        ),
        _buildGuideItem(
          Icons.share_outlined,
          "Klik Bagikan",
          "Cari ikon share atau 'Bagikan ke Aplikasi Lain'.",
        ),
        _buildGuideItem(
          Icons.touch_app_outlined,
          "Pilih Daru Cell",
          "Otomatis struk akan muncul di halaman ini.",
        ),
      ],
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String desc) {
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
                Text(title, style: theme.textTheme.titleMedium),
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
            child: Image.file(
              File(filePath!),
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ],
    );
  }
}
