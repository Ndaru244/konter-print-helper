import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cetak_struk/services/receipt_print.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintJobException implements Exception {
  PrintJobException({
    required this.sentLines,
    required this.totalLines,
    required this.cause,
  });

  final int sentLines;
  final int totalLines;
  final Object cause;

  String get message {
    if (sentLines <= 0) return "Gagal mencetak: $cause";
    return "Gagal mencetak mulai baris ${sentLines + 1} dari $totalLines. "
        "Baris sebelumnya sudah terkirim. ($cause)";
  }

  @override
  String toString() => message;
}

class PrinterService with ChangeNotifier {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  bool _isConnected = false;
  BluetoothDevice? _selectedPrinter;
  List<BluetoothDevice> _devices = [];
  Future<void>? _initFuture;

  bool get isConnected => _isConnected;
  BluetoothDevice? get selectedPrinter => _selectedPrinter;
  List<BluetoothDevice> get devices => _devices;

  bool isDummyMode = false; //Aktifkan untuk debug mode

  /// Single-flight. Panggilan dari berapa layar pun berbagi satu scan bonded
  /// dan satu percobaan sambung ulang. Gagal → future direset agar bisa diulang.
  Future<void> init() {
    final existing = _initFuture;
    if (existing != null) return existing;
    final gate = Completer<void>();
    _initFuture = gate.future;
    unawaited(_finishInit(gate));
    return gate.future;
  }

  Future<void> _finishInit(Completer<void> gate) async {
    try {
      await _runInit();
      gate.complete();
    } catch (error, stack) {
      if (identical(_initFuture, gate.future)) _initFuture = null;
      gate.completeError(error, stack);
    }
  }

  Future<void> _runInit() async {
    if (isDummyMode) {
      _isConnected = true;
      _selectedPrinter = BluetoothDevice(
        "Dummy Printer 80mm",
        "00:00:00:00:00:00",
      );
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
    final previous = _isConnected;
    if (isDummyMode) {
      _isConnected = true;
    } else {
      try {
        _isConnected = (await bluetooth.isConnected) ?? false;
      } catch (e) {
        debugPrint("Error checkConnection: $e");
        _isConnected = false;
      }
    }
    if (_isConnected != previous) notifyListeners();
  }

  /// Cetak job struk. Baris berurutan dengan size/align sama digabung.
  /// Tiap panggilan plugin di-await. Gagal di tengah melempar [PrintJobException]
  /// dengan jumlah baris yang sudah terkirim (printer thermal tidak bisa rollback).
  Future<void> printLines(List<ReceiptPrintLine> lines) async {
    if (isDummyMode) {
      debugPrint(">>> DUMMY STRUK <<<");
      for (final line in lines) {
        debugPrint(line.text);
      }
      return;
    }

    if (!_isConnected) {
      throw PrintJobException(
        sentLines: 0,
        totalLines: lines.length,
        cause: "Printer belum terhubung",
      );
    }

    final batches = batchPrintLines(lines);
    var sent = 0;
    try {
      await bluetooth.printNewLine();
      for (final batch in batches) {
        await bluetooth.printCustom(batch.text, batch.size, batch.align);
        sent += batch.sourceLines;
      }
      await bluetooth.printNewLine();
      await bluetooth.printNewLine();
    } catch (e) {
      throw PrintJobException(
        sentLines: sent,
        totalLines: lines.length,
        cause: e,
      );
    }
  }

  Future<void> testPrint() async {
    if (!_isConnected && !isDummyMode) {
      throw "Printer belum terhubung";
    }

    if (isDummyMode) {
      debugPrint(">>> DUMMY TEST PRINT BERHASIL <<<");
      return;
    }

    await printLines(const [
      ReceiptPrintLine("Tes cetak berhasil", 2, 1),
      ReceiptPrintLine("Printer siap digunakan", 1, 1),
      ReceiptPrintLine("--------------------------------", 1, 1),
    ]);
  }
}
