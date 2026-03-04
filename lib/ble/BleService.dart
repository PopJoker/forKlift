// lib/ble/BleService.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BleService._();
  static final BleService instance = BleService._();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _writeChar;

  StreamSubscription? _notifySub;
  StreamSubscription? _scanSub;
  StreamSubscription? _deviceStateSub;
  Timer? _watchdog;

  /// 對外資料流（取代 GlobalVar）
  final StreamController<List<int>> _dataController =
      StreamController.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  /// 連線/斷線事件
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  // ================================
  // 🔍 Scan
  // ================================
  Future<void> startScan(Function(ScanResult) onResult) async {
    await _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.name.isNotEmpty) {
          onResult(r);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
  }

  // ================================
  // 🔗 Connect
  // ================================
  Future<void> connect(BluetoothDevice device) async {
    _device = device;

    await device.connect(autoConnect: false, license: License.free);
    await device.requestMtu(512);

    await _discover();
    await _enableNotify();

    // 發送已連線事件
    _connectionController.add(true);

    // 監控裝置斷線
    _deviceStateSub?.cancel();
    _deviceStateSub = device.state.listen((s) {
      if (s == BluetoothDeviceState.disconnected) {
        _connectionController.add(false);
        _device = null;
        _notifyChar = null;
        _writeChar = null;
        _notifySub?.cancel();
        _notifySub = null;
      }
    });
  }

  // ================================
  // 🔍 Discover
  // ================================
  Future<void> _discover() async {
    final services = await _device!.discoverServices();

    _notifyChar = null;
    _writeChar = null;

    for (var s in services) {
      for (var c in s.characteristics) {
        if (_notifyChar == null && c.properties.notify) {
          _notifyChar = c;
        }
        if (_writeChar == null &&
            (c.properties.write || c.properties.writeWithoutResponse)) {
          _writeChar = c;
        }
        if (_notifyChar != null && _writeChar != null) break;
      }
      if (_notifyChar != null && _writeChar != null) break;
    }

    if (_notifyChar == null || _writeChar == null) {
      throw Exception("找不到可用的 notify/write characteristic");
    }
  }

  // ================================
  // 📡 Notify
  // ================================
  Future<void> _enableNotify() async {
    if (_notifyChar == null) return;

    await _notifyChar!.setNotifyValue(true);

    _notifySub = _notifyChar!.value.listen((data) {
      _dataController.add(data);
      _resetWatchdog();
    });

    _resetWatchdog();
  }

  // ================================
  // ⏱️ Watchdog（安全延長 30 秒）
  // ================================
  void _resetWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 30), () {
      disconnect();
    });
  }

  // ================================
  // ❌ Disconnect
  // ================================
  Future<void> disconnect() async {
    _watchdog?.cancel();
    await _notifySub?.cancel();
    await _deviceStateSub?.cancel();
    await _device?.disconnect();

    _device = null;
    _notifyChar = null;
    _writeChar = null;
    _notifySub = null;
    _deviceStateSub = null;

    _connectionController.add(false);
  }

  // ================================
  // ✍️ 寫入資料
  // ================================
  Future<void> write(List<int> data) async {
    if (_writeChar == null) throw Exception("Write characteristic 未找到");
    await _writeChar!.write(data, withoutResponse: false);
  }
}