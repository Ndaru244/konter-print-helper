import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService with ChangeNotifier {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  bool _isConnected = false;
  BluetoothDevice? _selectedPrinter;
  List<BluetoothDevice> _devices = [];

  bool get isConnected => _isConnected;
  BluetoothDevice? get selectedPrinter => _selectedPrinter;
  List<BluetoothDevice> get devices => _devices;

  bool isDummyMode = false; //Aktifkan untuk debug mode

  Future<void> init() async {
    if (isDummyMode) {
      _isConnected = true;
      _selectedPrinter = BluetoothDevice("Dummy Printer 80mm", "00:00:00:00:00:00");
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString("saved_printer");

    if (address != null) {
      final bondedDevices = await bluetooth.getBondedDevices();
      try {
        final device = bondedDevices.firstWhere((d) => d.address == address);
        await connect(device);
      } catch (_) {
        debugPrint("Printer saved not found");
      }
    }

    await getBondedDevices();
  }

  /// Daftar perangkat Dummy
  Future<void> getBondedDevices() async {
    if (isDummyMode) {
      _devices = [
        BluetoothDevice("Dummy Epson TM-T82", "00:11:22:33:44:55"),
        BluetoothDevice("Dummy Panda Printer", "AA:BB:CC:DD:EE:FF"),
        BluetoothDevice("Generic BlueTooth", "12:34:56:78:90:12"),
      ];
      notifyListeners();
      return;
    }

    try {
      _devices = await bluetooth.getBondedDevices();
      notifyListeners();
    } catch (e) {
      debugPrint("Error getBondedDevices: $e");
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (isDummyMode) {
      _selectedPrinter = device;
      _isConnected = true;
      notifyListeners();
      return;
    }

    try {
      if (_isConnected) {
        await bluetooth.disconnect();
      }

      await bluetooth.connect(device);
      _selectedPrinter = device;
      _isConnected = true;

      await savePrinter(device);
    } catch (e) {
      debugPrint("Gagal connect: $e");
      _isConnected = false;
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (isDummyMode) {
      _selectedPrinter = null;
      _isConnected = false;
      notifyListeners();
      return;
    }

    try {
      await bluetooth.disconnect();
    } catch (e) {
      debugPrint("Error disconnect: $e");
    }
    _selectedPrinter = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<void> savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_printer", device.address!);
  }

  Future<void> checkConnection() async {
    if (isDummyMode) {
      _isConnected = true;
      notifyListeners();
      return;
    }
    try {
      _isConnected = (await bluetooth.isConnected) ?? false;
    } catch (e) {
      _isConnected = false;
    }
    notifyListeners();
  }

  Future<void> testPrint() async {
    if (!_isConnected && !isDummyMode) {
      throw "Printer belum terhubung";
    }

    if (isDummyMode) {
      debugPrint(">>> DUMMY TEST PRINT BERHASIL <<<");
      return;
    }

    bluetooth.printNewLine();
    bluetooth.printCustom("TEST PRINT SUCCESS", 2, 1);
    bluetooth.printCustom("Printer siap digunakan", 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }
}