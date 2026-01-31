import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cetak_struk/services/printer_service.dart';
import 'package:cetak_struk/pages/settingprinter.dart';
import 'package:cetak_struk/pages/cetakstruk.dart';

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

    final printerService = context.read<PrinterService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterService>().init();
    });

    _checkInitialShared();
    _listenOnShare();

    _connectionTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      printerService.checkConnection();
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
      if (path != null) {
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
        if (path != null) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cetak Struk", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey[800]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterSettingPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: printerService.isConnected ? Colors.green.shade50 : Colors.red.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    printerService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    size: 18,
                    color: printerService.isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    printerService.isConnected
                        ? "Printer: ${printerService.selectedPrinter?.name ?? 'Terhubung'}"
                        : "Printer Tidak Terhubung",
                    style: TextStyle(
                      color: printerService.isConnected ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: fileReceived && filePath != null
                  ? _buildFilePreviewCard()
                  : _buildEmptyStateCard(),
            ),

            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("Panduan Cepat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 12),
                  _buildGuideItem("1", "Buka Aplikasi E-Wallet (DANA/GoPay/dll)"),
                  _buildGuideItem("2", "Buka Riwayat & Klik Bagikan Resi"),
                  _buildGuideItem("3", "Pilih Aplikasi 'Cetak Struk' ini"),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.print, color: Colors.white),
        label: const Text("Lanjut Cetak", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final service = Provider.of<PrinterService>(context, listen: false);

          await service.checkConnection();

          if (!service.isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sambungkan printer di menu pengaturan dulu!")),
            );
            return;
          }

          if (fileReceived && filePath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CetakStrukPage(imagePath: filePath!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Belum ada file gambar struk yang diterima.")),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: const [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "Belum Ada Transaksi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "Bagikan gambar struk dari aplikasi lain ke sini.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Struk Diterima!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _removeFile,
                tooltip: "Hapus File",
              )
            ],
          ),
          const Divider(),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Image.file(File(filePath!), fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.blue.shade100,
            child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}