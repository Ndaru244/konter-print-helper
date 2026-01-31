import 'package:cetak_struk/services/printer_service.dart';
import 'package:flutter/material.dart';
// Kita butuh import ini HANYA untuk tipe data BluetoothDevice
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';

class PrinterSettingPage extends StatefulWidget {
  const PrinterSettingPage({super.key});

  @override
  State<PrinterSettingPage> createState() => _PrinterSettingPageState();
}

class _PrinterSettingPageState extends State<PrinterSettingPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterService>().getBondedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    final devices = printerService.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan Printer"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            color: printerService.isConnected ? Colors.green.shade100 : Colors.red.shade100,
            padding: const EdgeInsets.all(8),
            child: Text(
              printerService.isConnected
                  ? "Terhubung ke: ${printerService.selectedPrinter?.name ?? 'Unknown'}"
                  : "Printer Belum Terhubung",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: printerService.isConnected ? Colors.green[800] : Colors.red[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  printerService.isDummyMode ? "Mode: DUMMY (Testing)" : "Mode: LIVE (Bluetooth)",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                TextButton.icon(
                  onPressed: () {
                    printerService.getBondedDevices();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh List"),
                ),
              ],
            ),
          ),

          // List Devices
          Expanded(
            child: devices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Tidak ada perangkat Bluetooth ditemukan."),
                  Text("Pastikan Bluetooth HP menyala & sudah pairing.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelected = printerService.selectedPrinter?.address == device.address;

                return ListTile(
                  leading: Icon(
                      Icons.print,
                      color: isSelected ? Colors.blue : Colors.grey
                  ),
                  title: Text(device.name ?? "Unknown Device", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(device.address ?? "-"),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                    onPressed: () {
                      printerService.connect(device);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text("Sambung"),
                  ),
                  onTap: () {
                    printerService.connect(device);
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await printerService.testPrint();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Test Print Terkirim!")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.receipt),
                    label: const Text("Test Print"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: printerService.isConnected
                        ? () => printerService.disconnect()
                        : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text("Putuskan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}