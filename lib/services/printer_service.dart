// services/printer_service.dart
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService with ChangeNotifier {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  bool _isConnected = false;
  BluetoothDevice? _selectedPrinter;

  bool get isConnected => _isConnected;
  BluetoothDevice? get selectedPrinter => _selectedPrinter;

  /// Inisialisasi saat app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString("saved_printer");
    if (address != null) {
      final bondedDevices = await bluetooth.getBondedDevices();
      try {
        final device = bondedDevices.firstWhere((d) => d.address == address);
        await connect(device);
      } catch (_) {
        debugPrint("Printer yang tersimpan tidak ditemukan");
      }
    }
  }

  /// Connect ke printer
  Future<void> connect(BluetoothDevice device) async {
    try {
      await bluetooth.connect(device);
      _selectedPrinter = device;
      _isConnected = true;
    } catch (e) {
      debugPrint("Gagal connect: $e");
      _isConnected = false;
    }
    notifyListeners();
  }

  /// Disconnect manual
  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
    } catch (e) {
      debugPrint("Error disconnect: $e");
    }
    _selectedPrinter = null;
    _isConnected = false;
    notifyListeners();
  }

  /// Simpan printer yg dipilih user
  Future<void> savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_printer", device.address!);
    _selectedPrinter = device;
    notifyListeners();
  }

  /// Cek koneksi printer (anti ghost)
  Future<void> checkConnection() async {
    try {
      bool? connected = await bluetooth.isConnected;
      _isConnected = connected ?? false;
    } catch (e) {
      debugPrint("Error checkConnection: $e");
      _isConnected = false;
    }
    notifyListeners();
  }
}
