import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/sale.dart';
import '../../data/models/user.dart';
import 'esc_pos_builder.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._init();

  bool isEnabled = true;
  String type = 'mock'; // 'mock' or 'tcp'
  String host = '192.168.1.100';
  int port = 9100;
  int paperWidth = 80;
  bool autoCut = true;
  bool drawerEnabled = true;
  int drawerPin = 2;
  bool autoPrintOnCheckout = false;

  // In-memory buffer for mock printer simulation & inspections
  final List<Uint8List> mockPrintLogs = [];
  int mockDrawerKickCount = 0;

  PrinterService._init() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled = prefs.getBool('printer_enabled') ?? true;
    type = prefs.getString('printer_type') ?? 'mock';
    host = prefs.getString('printer_host') ?? '192.168.1.100';
    port = prefs.getInt('printer_port') ?? 9100;
    paperWidth = prefs.getInt('printer_paper_width') ?? 80;
    autoCut = prefs.getBool('printer_auto_cut') ?? true;
    drawerEnabled = prefs.getBool('printer_drawer_enabled') ?? true;
    drawerPin = prefs.getInt('printer_drawer_pin') ?? 2;
    autoPrintOnCheckout = prefs.getBool('printer_auto_print') ?? false;
  }

  Future<void> saveSettings({
    required bool isEnabled,
    required String type,
    required String host,
    required int port,
    required int paperWidth,
    required bool autoCut,
    required bool drawerEnabled,
    required int drawerPin,
    required bool autoPrintOnCheckout,
  }) async {
    this.isEnabled = isEnabled;
    this.type = type;
    this.host = host;
    this.port = port;
    this.paperWidth = paperWidth;
    this.autoCut = autoCut;
    this.drawerEnabled = drawerEnabled;
    this.drawerPin = drawerPin;
    this.autoPrintOnCheckout = autoPrintOnCheckout;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('printer_enabled', isEnabled);
    await prefs.setString('printer_type', type);
    await prefs.setString('printer_host', host);
    await prefs.setInt('printer_port', port);
    await prefs.setInt('printer_paper_width', paperWidth);
    await prefs.setBool('printer_auto_cut', autoCut);
    await prefs.setBool('printer_drawer_enabled', drawerEnabled);
    await prefs.setInt('printer_drawer_pin', drawerPin);
    await prefs.setBool('printer_auto_print', autoPrintOnCheckout);
  }

  EscPosBuilder _createBuilder() {
    return EscPosBuilder(
      paperWidth: paperWidth,
      autoCut: autoCut,
      drawerPin: drawerPin,
    );
  }

  Future<bool> printSaleReceipt(SaleModel sale, StoreModel? store) async {
    if (!isEnabled) return false;

    final builder = _createBuilder();
    final bytes = builder.buildReceipt(sale, store);

    return await _sendBytes(bytes);
  }

  Future<bool> kickCashDrawer() async {
    if (!isEnabled || !drawerEnabled) return false;

    final builder = _createBuilder();
    final bytes = Uint8List.fromList(builder.buildDrawerPulse());

    if (type == 'mock') {
      mockDrawerKickCount++;
      return true;
    }

    return await _sendBytes(bytes);
  }

  Future<bool> testPrint(StoreModel? store) async {
    final now = DateTime.now();
    final dummySale = SaleModel(
      transactionUuid: 'test-print-tx',
      invoiceNumber: 'TEST-INV-001',
      cashierUuid: 'cashier-test',
      cashierName: 'Test Cashier',
      storeUuid: store?.uuid ?? 'store-uuid',
      deviceUuid: 'device-uuid',
      subtotal: 1500.0,
      totalAmount: 1500.0,
      paidAmount: 2000.0,
      changeAmount: 500.0,
      soldAt: now,
      items: [],
      payments: [
        const PaymentModel(method: PaymentMethod.cash, amount: 2000.0),
      ],
    );

    return await printSaleReceipt(dummySale, store);
  }

  Future<bool> _sendBytes(Uint8List bytes) async {
    if (type == 'mock') {
      mockPrintLogs.add(bytes);
      debugPrint('[PrinterService] Mock print job logged (${bytes.length} bytes)');
      return true;
    }

    // Direct TCP raw socket to Network/WiFi Thermal Printer
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('[PrinterService] Network print failed: $e');
      socket?.destroy();
      return false;
    }
  }
}
