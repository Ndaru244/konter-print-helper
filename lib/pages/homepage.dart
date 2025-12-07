import 'dart:async';
import 'dart:io';
import 'package:cetak_struk/services/printer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'settingprinter.dart';
import 'cetakstruk.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel("app.share");
  bool fileReceived = false;
  String? filePath;

  @override
  void initState() {
    super.initState();

    final printerService = context.read<PrinterService>();
    printerService.init();

    _checkInitialShared();
    _listenOnShare();

    Timer.periodic(const Duration(seconds: 3), (_) {
      printerService.checkConnection();
    });
  }

  Future<void> _checkInitialShared() async {
    try {
      final path = await platform.invokeMethod<String>("getInitialShared");
      if (path != null) {
        setState(() {
          fileReceived = true;
          filePath = path;
        });
        debugPrint("Initial shared file: $path");
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get initial shared: ${e.message}");
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
          debugPrint("New shared file: $path");
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Cetak Struk",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fileReceived ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: fileReceived ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    fileReceived ? Icons.check_circle : Icons.info,
                    color: fileReceived ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileReceived
                          ? "File transaksi berhasil diterima."
                          : "Belum ada file transaksi yang diterima.",
                      style: TextStyle(
                        color: fileReceived ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (filePath != null) ...[
              const SizedBox(height: 20),
              _buildFilePreview(),
            ],
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Center(
                    child: Text(
                      "Panduan Pemakaian",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text("1. Buka riwayat transaksi dari Dompet Online."),
                  SizedBox(height: 6),
                  Text("2. Tekan tombol bagikan transaksi."),
                  SizedBox(height: 6),
                  Text("3. Pilih aplikasi Cetak Struk."),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final printerService = PrinterService();
          await printerService.checkConnection();

          if (!printerService.isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Printer belum tersambung. Silakan hubungkan terlebih dahulu.",
                ),
              ),
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
              const SnackBar(
                content: Text("Belum ada file transaksi yang diterima."),
              ),
            );
          }
        },
        label: const Text("Cetak", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.print, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildFilePreview() {
    if (filePath == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "File Diterima",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _removeFile,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 0.5,
              child: Image.file(File(filePath!), fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
