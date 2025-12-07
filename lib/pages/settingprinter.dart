import 'dart:async';

import 'package:cetak_struk/services/printer_service.dart';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';

class PrinterSettingPage extends StatefulWidget {
  const PrinterSettingPage({super.key});

  @override
  State<PrinterSettingPage> createState() => _PrinterSettingPageState();
}

class _PrinterSettingPageState extends State<PrinterSettingPage> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedPrinter;
  bool isBluetoothOn = false;

  @override
  void initState() {
    super.initState();

    final printerService = context.read<PrinterService>();
    printerService.init();

    _getDevices();

    Timer.periodic(const Duration(seconds: 3), (_) {
      printerService.checkConnection();
    });
  }

  Future<void> _getDevices() async {
    try {
      final bluetooth = BlueThermalPrinter.instance;
      final bool? state = await bluetooth.isOn;
      final List<BluetoothDevice> pairedDevices = await bluetooth
          .getBondedDevices();

      setState(() {
        isBluetoothOn = state ?? false;
        devices = pairedDevices;
      });
    } catch (e) {
      debugPrint("Error getDevices: $e");
    }
  }

  Future<void> _testPrint() async {
    try {
      final bluetooth = BlueThermalPrinter.instance;
      bool? connected = await bluetooth.isConnected;
      if (connected == true) {
        await bluetooth.printNewLine();
        await bluetooth.printCustom("TEST PRINT", 2, 1);
        await bluetooth.printCustom("Printer OK - 85mm", 1, 1);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil Test Print")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Printer belum tersambung")),
        );
      }
    } catch (e) {
      debugPrint("Error testPrint: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text("Setting Printer"),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status Bluetooth: ${isBluetoothOn ? "Aktif" : "Nonaktif"}",
                ),
                ElevatedButton.icon(
                  onPressed: _getDevices,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isSelected =
                      printerService.selectedPrinter?.address == device.address;
                  return ListTile(
                    title: Text(device.name ?? "Unknown"),
                    subtitle: Text(device.address ?? ""),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () async {
                      await printerService.connect(device);
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: _testPrint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        "Test Print",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (printerService.selectedPrinter != null) {
                          printerService.savePrinter(
                            printerService.selectedPrinter!,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        "Simpan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        printerService.disconnect();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        "Putuskan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
