import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/widgets/app_bottom_bar.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_empty_state.dart";
import "package:cetak_struk/widgets/app_icon_tile.dart";
import "package:cetak_struk/widgets/app_list_tile.dart";
import "package:cetak_struk/widgets/app_section_label.dart";
import "package:cetak_struk/widgets/app_status_banner.dart";

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
      context.read<PrinterService>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerService = context.watch<PrinterService>();
    final devices = printerService.devices;
    final connected = printerService.isConnected;

    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan Printer")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppStatusBanner(
              inset: true,
              tone: connected ? AppStatusTone.success : AppStatusTone.danger,
              icon: connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              message: connected ? "Printer Terhubung" : "Printer Terputus",
              subtitle: connected
                  ? (printerService.selectedPrinter?.name ?? "Unknown")
                  : null,
              trailing: connected
                  ? IconButton(
                      onPressed: () => printerService.disconnect(),
                      tooltip: "Putuskan",
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
            child: Row(
              children: [
                const Expanded(
                  child: AppSectionLabel(label: "DAFTAR PERANGKAT"),
                ),
                IconButton(
                  onPressed: () => printerService.getBondedDevices(),
                  icon: const Icon(Icons.refresh, size: 24),
                  tooltip: "Cari Ulang",
                ),
              ],
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppEmptyState(
                        icon: Icons.bluetooth_searching,
                        title: "Tidak Ada Perangkat",
                        description:
                            "Pastikan Bluetooth menyala dan\nprinter sudah ter-pairing di HP.",
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final isSelected =
                          printerService.selectedPrinter?.address ==
                          device.address;

                      return AppListTile(
                        selected: isSelected,
                        leading: const AppIconTile(icon: Icons.print_outlined),
                        title: device.name ?? "Unknown Device",
                        subtitle: device.address ?? "-",
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : AppButton.text(
                                label: "SAMBUNG",
                                onPressed: () => printerService.connect(device),
                              ),
                        onTap: isSelected
                            ? null
                            : () => printerService.connect(device),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        child: AppButton.secondary(
          icon: Icons.receipt_outlined,
          label: "TEST PRINT",
          onPressed: connected
              ? () async {
                  await printerService.testPrint();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Test print terkirim ke printer!"),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }
}
